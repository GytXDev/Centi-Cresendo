//lib\models\bet_model.dart
class BetModel {
  final String id;
  final String userId;
  final String description;
  final double potentialGain;
  final double participationSum;
  final List<String> participants;
  final List<String> winners;
  final DateTime creationDate;
  final Duration duration;
  bool isGainSending;

  BetModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.potentialGain,
    required this.participationSum,
    required this.participants,
    required this.winners,
    required this.creationDate,
    required this.duration,
    this.isGainSending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'potentialGain': potentialGain,
      'participationSum': participationSum,
      'participants': participants,
      'winners': winners,
      'creationDate': creationDate.toIso8601String(),
      'duration': duration.inMilliseconds,
      'isGainSending': isGainSending,
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> map) {
    return BetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      potentialGain: map['potentialGain'] ?? 0.0,
      participationSum: map['participationSum'] ?? 0.0,
      participants: List<String>.from(map['participants'] ?? []),
      winners: List<String>.from(map["winners"] ?? []),
      creationDate: DateTime.parse(map['creationDate'] ?? ''),
      duration: Duration(
        milliseconds: map['duration'] ?? 0,
      ),
      isGainSending: map['isGainSending'] ?? false,
    );
  }
}
