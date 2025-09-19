import 'package:flutter/material.dart';

class ExpiryWarning extends StatelessWidget {
  const ExpiryWarning({
    super.key,
    required this.daysUntilExpiry,
    required this.onRenew,
  });
  final int daysUntilExpiry;
  final VoidCallback onRenew;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your subscription expires in $daysUntilExpiry day${daysUntilExpiry != 1 ? 's' : ''}',
            ),
          ),
          TextButton(onPressed: onRenew, child: const Text('Renew')),
        ],
      ),
    );
  }
}
