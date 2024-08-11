// ignore_for_file: constant_identifier_names

enum MessageType {
  InvalidPinLength,
  InsufficientBalance,
  IncorrectPin,
  SuccessfulTransaction,
  CancelledTransaction,
  UnableToGetTransactionStatus,
  Other,
}

MessageType identifyMessageType(String message) {
  if (message.contains('invalid PIN length')) {
    return MessageType.InvalidPinLength;
  } else if (message.contains('Solde insuffisant')) {
    return MessageType.InsufficientBalance;
  } else if (message.contains('incorrect four digit PIN')) {
    return MessageType.IncorrectPin;
  } else if (message.contains('Transaction a ete effectue avec succes') ||
      message.contains('Your transaction has been successfully processed')) {
    return MessageType.SuccessfulTransaction;
  } else if (message.contains('transaction a ete annulee avec succes')) {
    return MessageType.CancelledTransaction;
  } else if (message.contains(
      'Impossible d\'obtenir le statut de la transaction après plusieurs tentatives')) {
    return MessageType.UnableToGetTransactionStatus;
  } else {
    return MessageType.Other;
  }
}
