import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;

  const InputField({super.key, required this.controller, required this.label, this.obscure = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    if (isCupertinoPlatform(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          CupertinoTextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
          ),
        ],
      );
    }
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}
