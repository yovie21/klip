import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../features/projects/data/project_repository.dart';
import '../features/projects/presentation/home_screen.dart';

class KlipApp extends StatelessWidget {
  const KlipApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ProjectRepository(),
        child: MaterialApp(
          title: 'Klip',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const HomeScreen(),
        ),
      );
}
