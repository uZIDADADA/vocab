import 'package:flutter/material.dart';

import 'data/local/app_database.dart';
import 'data/repositories/learning_repository.dart';
import 'features/home/home_screen.dart';
import 'theme/vocab_theme.dart';

class VocabApp extends StatefulWidget {
  const VocabApp({this.database, super.key});

  final AppDatabase? database;

  @override
  State<VocabApp> createState() => _VocabAppState();
}

class _VocabAppState extends State<VocabApp> {
  late final bool _ownsDatabase = widget.database == null;
  late final AppDatabase _database = widget.database ?? AppDatabase();
  late final LearningRepository _repository = LearningRepository(_database);

  @override
  void dispose() {
    if (_ownsDatabase) {
      _database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab',
      debugShowCheckedModeBanner: false,
      theme: VocabTheme.light,
      home: HomeScreen(repository: _repository),
    );
  }
}
