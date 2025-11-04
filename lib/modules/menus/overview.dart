import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Overview'),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
      body: Center(
        child: Text(
          'Hello world',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C4DFF),
              ),
        ),
      ),
    );
  }
}
