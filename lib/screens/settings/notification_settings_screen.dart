import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool smsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push notifications'),
            value: pushEnabled,
            onChanged: (value) => setState(() => pushEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Email notifications'),
            value: emailEnabled,
            onChanged: (value) => setState(() => emailEnabled = value),
          ),
          SwitchListTile(
            title: const Text('SMS notifications'),
            value: smsEnabled,
            onChanged: (value) => setState(() => smsEnabled = value),
          ),
        ],
      ),
    );
  }
}
