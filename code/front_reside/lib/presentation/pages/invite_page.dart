import 'package:flutter/material.dart';
import 'package:front_reside/domain/services/invite_service.dart';
import 'package:front_reside/domain/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../controllers/user_profile_controller.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({Key? key}) : super(key: key);

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final _formKey = GlobalKey<FormState>();
  String inviteCode = '';
  String firstName = '';
  String lastName = '';
  String document = '';
  String contactPhone = '';

  late final String googleId;
  late final String idToken;

  bool _loading = false;
  String? _error;
  bool _didInit = false;

  // Máscaras de entrada
  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInit) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      print('❌ InvitePage: argumentos não encontrados');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return;
    }

    googleId = args['googleId'] as String;
    idToken = args['idToken'] as String;

    print('✅ InvitePage: carregado com googleId=$googleId');

    _didInit = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Tenta obter FCM token de forma opcional
      String? fcmToken;
      try {
        fcmToken = await NotificationService.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          print('📱 FCM Token obtido para cadastro');
        } else {
          print('📱 Cadastro sem FCM Token - notificações desabilitadas');
        }
      } catch (e) {
        print('⚠️ Erro ao obter FCM token (continuando sem notificações): $e');
        fcmToken = null;
      }

      await InviteService().bindResident(
        inviteCode: inviteCode,
        firstName: firstName,
        lastName: lastName,
        document: document,
        contactPhone: contactPhone,
        fcmToken: fcmToken, // Agora é opcional
        googleId: googleId,
        idToken: idToken,
      );

      await Provider.of<UserProfileController>(
        context,
        listen: false,
      ).loadUserProfile();

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vincular Convite')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Código de convite',
                      ),
                      onSaved: (v) => inviteCode = v!.trim(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Código obrigatório'
                                  : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nome'),
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      onSaved: (v) => firstName = v!.trim(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nome obrigatório';
                        if (v.length > 20) return 'Máx. 20 caracteres';
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Sobrenome'),
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      onSaved: (v) => lastName = v!.trim(),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Sobrenome obrigatório';
                        if (v.length > 20) return 'Máx. 20 caracteres';
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'CPF'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [cpfMaskFormatter],
                      onSaved: (v) => document = v!.trim(),
                      validator: (v) {
                        final raw = cpfMaskFormatter.getUnmaskedText();
                        if (raw.isEmpty) return 'CPF obrigatório';
                        if (raw.length != 11) return 'CPF inválido';
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [phoneMaskFormatter],
                      onSaved: (v) => contactPhone = v!.trim(),
                      validator: (v) {
                        final raw = phoneMaskFormatter.getUnmaskedText();
                        if (raw.isEmpty) return 'Telefone obrigatório';
                        if (raw.length < 10) return 'Telefone inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _loading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Vincular'),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
