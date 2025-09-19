import 'package:flutter/material.dart';

class UsagePeriodInfo extends StatelessWidget {
  const UsagePeriodInfo({
    super.key,
    required this.periodStart,
    required this.periodEnd,
  });
  final DateTime periodStart;
  final DateTime periodEnd;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Period',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${_formatDate(periodStart)} - ${_formatDate(periodEnd)}'),
          Text(
            'Resets on ${_formatDate(periodEnd)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
