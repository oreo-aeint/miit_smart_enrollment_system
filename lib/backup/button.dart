import 'package:flutter/material.dart';

/// Standard action button like "Enroll"
class ActionButton extends StatelessWidget {
  final String text;
  final IconData? icon; // ✅ optional icon
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlue[100],
        foregroundColor: Colors.indigo,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ✅ Let button shrink to content width
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded box button for Old/New student choices
/// Rounded box button for Old/New student choices
class RoundedBoxButton extends StatelessWidget {
  final String text;
  final IconData? icon;       // optional icon
  final VoidCallback onPressed;
  final double? iconSize;     // ✅ new

  const RoundedBoxButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.iconSize,            // accept custom size
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black54, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize ?? 50, // ✅ use passed size, default 50
                  color: Colors.indigo,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
