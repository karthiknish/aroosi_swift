import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class OnboardingChecklistScreen extends StatefulWidget {
  const OnboardingChecklistScreen({super.key});

  @override
  State<OnboardingChecklistScreen> createState() =>
      _OnboardingChecklistScreenState();
}

class _OnboardingChecklistScreenState extends State<OnboardingChecklistScreen> {
  final _items = <_ChecklistItem>[
    _ChecklistItem('Upload a profile photo'),
    _ChecklistItem('Share a short bio'),
    _ChecklistItem('Select your interests'),
  ];

  @override
  Widget build(BuildContext context) {
    final isComplete = _items.every((item) => item.completed);

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeThrough(
          delay: AppMotionDurations.fast,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 80 * index),
                      beginOffset: const Offset(0, 0.05),
                      child: CheckboxListTile(
                        title: Text(item.title),
                        value: item.completed,
                        onChanged: (value) =>
                            setState(() => item.completed = value ?? false),
                      ),
                    );
                  },
                ),
              ),
              FadeScaleIn(
                delay: AppMotionDurations.fast,
                child: FilledButton(
                  onPressed: isComplete
                      ? () => context.push('/onboarding/complete')
                      : null,
                  child: const Text('Finish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem {
  _ChecklistItem(this.title);

  final String title;
  bool completed = false;
}
