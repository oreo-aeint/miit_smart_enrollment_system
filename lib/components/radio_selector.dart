import 'package:flutter/material.dart';

class RadioSelector extends StatelessWidget {
  final String groupValue;
  final Function(String?) onChanged;
  final TextStyle? labelStyle;

  const RadioSelector({
    super.key,
    required this.groupValue,
    required this.onChanged,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Radio<String>(
              value: 'CSE',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            Text('CSE', style: labelStyle),
          ],
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            Radio<String>(
              value: 'ECE',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            Text('ECE', style: labelStyle),
          ],
        ),
      ],
    );
  }
}
