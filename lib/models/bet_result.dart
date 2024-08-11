class BetResultModel {
  final String betId;
  final List<String> winners;
  final double totalAmountWon;
  final DateTime dateSent;

  BetResultModel({
    required this.betId,
    required this.winners,
    required this.totalAmountWon,
    required this.dateSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'betId': betId,
      'winners': winners,
      'totalAmountWon': totalAmountWon,
      'dateSent': dateSent.millisecondsSinceEpoch,
    };
  }

  factory BetResultModel.fromMap(Map<String, dynamic> map) {
    return BetResultModel(
      betId: map['betId'] ?? '',
      winners: List<String>.from(map['winners'] ?? []),
      totalAmountWon: map['totalAmountWon'] ?? 0.0,
      dateSent: DateTime.fromMillisecondsSinceEpoch(map["dateSent"]),
    );
  }
}
