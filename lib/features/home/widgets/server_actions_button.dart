import 'package:flutter/material.dart';

class ServerActionButton extends StatelessWidget {
  final bool isRunning;
  final bool isLoading;
  final VoidCallback onPressed;

  const ServerActionButton({
    super.key,
    required this.isRunning,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isRunning ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? const SizedBox(
        height: 20, width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isRunning ? Icons.stop : Icons.play_arrow),
          const SizedBox(width: 8),
          Text(isRunning ? 'Stop Server' : 'Start Server',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}