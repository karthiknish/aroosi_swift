import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool showOnlineStatus = true;
  bool shareProfileWithMatches = true;
  bool visibleInSearch = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Show online status'),
            value: showOnlineStatus,
            onChanged: (value) => setState(() => showOnlineStatus = value),
          ),
          SwitchListTile(
            title: const Text('Share profile with matches'),
            value: shareProfileWithMatches,
            onChanged: (value) => setState(() => shareProfileWithMatches = value),
          ),
          SwitchListTile(
            title: const Text('Appear in search results'),
            value: visibleInSearch,
            onChanged: (value) => setState(() => visibleInSearch = value),
          ),
        ],
      ),
    );
  }
}
