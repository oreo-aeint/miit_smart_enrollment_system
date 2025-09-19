import 'package:flutter/material.dart';

class InputTextBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String? hintText;
  final bool readOnly;
  final IconData? icon;
  final int maxLines;

  const InputTextBox({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.hintText,
    this.readOnly = false,
    this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        readOnly: readOnly, // ✅ now works
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          hintText: hintText, // ✅ now works
          labelStyle: const TextStyle(color: Colors.indigo),
          prefixIcon: icon != null ? Icon(icon, color: Colors.indigo) : null,
        ),
      ),
    );
  }
}
