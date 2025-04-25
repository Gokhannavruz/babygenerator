import 'package:flutter/material.dart';

class AgePickerWidget extends StatelessWidget {
  final int currentAge;
  final Function(int) onChanged;

  const AgePickerWidget({
    required this.currentAge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Target Age: $currentAge years',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: currentAge.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: '$currentAge years',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}
