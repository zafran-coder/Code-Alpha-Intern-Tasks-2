import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/storage.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StrideApp());
}

class StrideApp extends StatefulWidget {
  const StrideApp({super.key});

  @override
  State<StrideApp> createState() => _StrideAppState();
}

class _StrideAppState extends State<StrideApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(Storage())..load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Stride',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
