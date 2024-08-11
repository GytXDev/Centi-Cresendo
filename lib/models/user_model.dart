//lib\models\user_model.dart
class UserModel {
  final String username;
  final String uid;
  final String email;
  final String userType;
  final double latitude;
  final double longitude;
  final double balance;
  final String accountNumber;
  List<String>? transactionNumbers;
  List<String>? ticketIds;

  UserModel({
    required this.username,
    required this.uid,
    required this.email,
    required this.userType,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.balance = 0,
    required this.accountNumber,
    this.transactionNumbers,
    this.ticketIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'uid': uid,
      'email': email,
      'userType': userType,
      'latitude': latitude,
      'longitude': longitude,
      'balance': balance,
      'accountNumber': accountNumber,
      'transactionNumbers': transactionNumbers ?? [],
      'ticketIds': ticketIds ?? [],
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? '',
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? 'user',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      balance: (map['balance'] ?? 0).toDouble(),
      accountNumber: map['accountNumber'] ?? '',
      transactionNumbers: map['transactionNumbers'] != null
          ? List<String>.from(map['transactionNumbers'])
          : null,
      ticketIds:
          map['ticketIds'] != null ? List<String>.from(map['ticketIds']) : null,
    );
  }

  void removeTransactionNumber(String number) {
    transactionNumbers?.remove(number);
  }

  void addTicketId(String ticketId) {
    ticketIds ??= [];
    ticketIds!.add(ticketId);
  }

  String? getLastTicketId() {
    return ticketIds?.isNotEmpty == true ? ticketIds!.last : null;
  }
}
