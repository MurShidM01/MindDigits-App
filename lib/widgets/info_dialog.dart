import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Text('About Game'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              'Game Instructions',
              [
                '1. Choose a difficulty level',
                '2. The game will generate a random number',
                '3. Enter your guess in the input field',
                '4. The game will tell you if your guess is too high or too low',
                '5. Try to guess the number in as few attempts as possible',
                '6. Your score is based on the number of attempts and time taken',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Game Features',
              [
                '• Multiple difficulty levels',
                '• Score tracking',
                '• Game history',
                '• Customizable settings',
                '• Dark/Light theme support',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Game Information',
              [
                'Version: 1.0.0',
                'Developer: MurShidM01',
                'Created with Flutter',
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item),
        )),
      ],
    );
  }
} 