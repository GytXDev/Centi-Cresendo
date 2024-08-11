import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String userId;
  final DateTime requestDate;
  final String phoneNumber;
  final double amount;
  final String reference;
  WithdrawalStatus status;
  bool isConfirmed;
  final String currency;
  DateTime? statusUpdateDate;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.requestDate,
    required this.phoneNumber,
    required this.amount,
    required this.reference,
    this.status = WithdrawalStatus.pending,
    this.isConfirmed = false,
    required this.currency,
    this.statusUpdateDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'requestDate': Timestamp.fromDate(requestDate),
      'phoneNumber': phoneNumber,
      'amount': amount,
      'reference': reference,
      'status': status.toString().split('.').last,
      'isConfirmed': isConfirmed,
      'currency': currency,
      'statusUpdateDate': statusUpdateDate != null
          ? Timestamp.fromDate(statusUpdateDate!)
          : null,
    };
  }

  static WithdrawalRequest fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalRequest(
      id: doc.id,
      userId: data['userId'],
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      phoneNumber: data['phoneNumber'],
      amount: data['amount'],
      reference: data['reference'],
      status: WithdrawalStatus.values.firstWhere(
          (e) => e.toString() == 'WithdrawalStatus.${data['status']}'),
      isConfirmed: data['isConfirmed'],
      currency: data['currency'],
      statusUpdateDate: data['statusUpdateDate'] != null
          ? (data['statusUpdateDate'] as Timestamp).toDate()
          : null,
    );
  }
}

enum WithdrawalStatus { pending, processed, refused }
