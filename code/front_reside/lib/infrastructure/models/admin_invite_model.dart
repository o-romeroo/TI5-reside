class AdminInviteModel {
  final int condominiumId;
  final List<InviteGroup> invites;

  AdminInviteModel({
    required this.condominiumId,
    required this.invites,
  });

  Map<String, dynamic> toJson() => {
        'condominium_id': condominiumId,
        'invites': invites.map((invite) => invite.toJson()).toList(),
      };
}

class InviteGroup {
  final List<String> emails;
  final List<String> apartments;

  InviteGroup({
    required this.emails,
    required this.apartments,
  });

  Map<String, dynamic> toJson() => {
        'emails': emails,
        'apartments': apartments,
      };
}