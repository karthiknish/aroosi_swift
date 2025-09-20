import 'package:flutter/material.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                CircleAvatar(radius: 32, child: Text('AM')),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aroosi Member',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Lahore, Pakistan'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('About'),
            const SizedBox(height: 8),
            const Text(
              'I love discovering new cultures and cuisines. Looking for genuine connections and meaningful conversations.',
            ),
            const SizedBox(height: 24),
            const Text('Interests'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: const [
                Chip(label: Text('Travel')),
                Chip(label: Text('Cooking')),
                Chip(label: Text('Photography')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
