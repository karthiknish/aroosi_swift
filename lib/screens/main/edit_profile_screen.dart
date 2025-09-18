import 'package:flutter/material.dart';

import 'package:aroosi_flutter/core/toast_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = 'Aroosi Member';
  String _bio = 'Tell the community a little about yourself';

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (!mounted) return;
      ToastService.instance.success('Profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Display name'),
                onSaved: (value) => _name = value ?? _name,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _bio,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 4,
                onSaved: (value) => _bio = value ?? _bio,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
