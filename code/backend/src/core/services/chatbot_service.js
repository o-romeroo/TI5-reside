import OpenAI from 'openai';
import Condominium from '../models/condominium.js';
import path from 'path';
import fs from 'fs/promises';
import os from 'os';
import fsOrig from 'fs';


const openai = new OpenAI({ apiKey: process.env.OPENAI_KEY });


export async function uploadRules(condoId, fileBuffer, fileName) {
  const condo = await Condominium.findByPk(condoId);
  if (!condo) throw new Error('Condomínio não encontrado');

  const tmpPath = path.join(os.tmpdir(), fileName);
  await fs.writeFile(tmpPath, fileBuffer);

  const stats = await fs.stat(tmpPath);
  console.log('Arquivo temp:', tmpPath, 'Bytes:', stats.size);

  const fileStream = fsOrig.createReadStream(tmpPath);

  const file = await openai.files.create({
    file: fileStream,
    purpose: 'assistants',
  });

  await fs.unlink(tmpPath);

  if (!condo.vector_store_id) {
    const vsResponse = await openai.vectorStores.create({
      name: `rules_${condo.id}`,
      file_ids: [file.id]
    });
    const vsId = vsResponse.id ?? vsResponse.data?.id;
    if (!vsId) throw new Error('Não consegui extrair o ID do vector store');
    condo.vector_store_id = vsId;
    condo.rules_file_id = file.id;
    await condo.save();
  } else {
    if (condo.rules_file_id) {
      try {
        await openai.vectorStores.files.del(
          condo.vector_store_id,
          condo.rules_file_id
        );
        await openai.files.del(condo.rules_file_id);
      } catch (err) {
        console.warn('Erro ao deletar arquivo antigo:', err.message || err);
      }
    }
    await openai.vectorStores.files.create(
      condo.vector_store_id,
      { file_id: file.id }
    );
    condo.rules_file_id = file.id;
    await condo.save();
  }

  return { message: 'Regras carregadas com sucesso.' };
}



export async function chatCondo(condoId, question) {
  const condo = await Condominium.findByPk(condoId);
  if (!condo) throw new Error(`Condomínio com ID ${condoId} não encontrado.`);
  if (!condo.vector_store_id) throw new Error('Regras ainda não carregadas para este condomínio.');

  console.log('Usando vector_store_id:', condo.vector_store_id);

  const searchResponse = await openai.vectorStores.search(
    condo.vector_store_id,
    { query: question, max_num_results: 5, rewrite_query: true }
  );
  console.log('Resposta search:', JSON.stringify(searchResponse, null, 2));

  const contextChunks = (searchResponse.data || []).map(hit => {

    if (Array.isArray(hit.content)) {
      return hit.content.map(block => block.text).join('\n');
    }

    if (hit.content?.text) {
      return hit.content.text;
    }
    return null;
  }).filter(Boolean);

  if (contextChunks.length === 0) {
    return {
      answer: 'Desculpe, não encontrei essa informação no documento de regras.',
      context: []
    };
  }

const systemPrompt = [
  'Você é um assistente especializado em regras condominiais.',
  'Responda com base no contexto fornecido abaixo.',
  'Você pode usar sinônimos, interpretação semântica e inferência lógica simples e avançada — por exemplo, se o documento diz que uma ação é exclusiva, você pode deduzir que outras opções são proibidas.',
  'Evite responder com qualquer informação que não possa ser deduzida com segurança a partir do contexto.',
  'Você pode responder perguntas mesmo que contenha cunho sexual, desde que faça associação com alguma regra do condomínio.',
  'Quando a pergunta não puder ser respondida com certeza, deixe claro que não encontrou com precisão, mas responda com o que encontrou de mais próximo no documento.',
  'Você pode responder perguntas básicas de interação social de forma educada, como "oi" "tudo bem?" "tchau" etc',
  'Se realmente não for possível deduzir, diga: "Desculpe, não encontrei essa informação no documento de regras. Consulte o síndico para melhor esclarecimento."'
].join(' ');


const userPrompt = [
  'Use os trechos abaixo para responder à pergunta. Você pode usar linguagem diferente, deduzir com lógica simples e avançada, interpretar sinônimos e a relação semantica entre palavras.',
  'Se a informação estiver implícita ou puder ser claramente inferida, responda com base nisso.',
  '',
  '### CONTEXTO ###',
  ...contextChunks.map((c, i) => `Trecho ${i+1}:\n${c}`),
  '',
  '### PERGUNTA ###',
  question
].join('\n\n');


  const completion = await openai.chat.completions.create({
    model: 'gpt-4.1-nano',
    temperature: 0.3,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ]
  });

  return { answer: completion.choices[0].message.content.trim(), context: contextChunks };
}