import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'theme/vocab_theme.dart';

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab',
      debugShowCheckedModeBanner: false,
      theme: VocabTheme.light,
      home: const HomeScreen(),
    );
  }
}
