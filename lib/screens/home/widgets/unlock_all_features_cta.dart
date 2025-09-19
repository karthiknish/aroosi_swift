import 'package:flutter/material.dart';

class UnlockAllFeaturesCTA extends StatelessWidget {
  const UnlockAllFeaturesCTA({super.key, required this.onUpgrade});
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Unlock All Features',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to Premium or Premium Plus for unlimited access',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onUpgrade, child: const Text('View Plans')),
        ],
      ),
    );
  }
}
