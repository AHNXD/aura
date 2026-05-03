import 'package:flutter/material.dart';

void main() {
  runApp(const Aura());
}

class Aura extends StatelessWidget {
  const Aura({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(),
    );
  }
}
