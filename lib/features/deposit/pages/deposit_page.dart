import 'package:flutter/material.dart';

class DepositPageStatus extends StatelessWidget {
  final String code;

  const DepositPageStatus({Key? key, required this.code}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statut de dépôt'),
      ),
      body: Center(
        child: Text('La transaction a été effectuée avec succès! Code : $code'),
      ),
    );
  }
}
