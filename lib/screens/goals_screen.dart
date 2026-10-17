import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entry.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/panel.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _steps = TextEditingController();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  final _weight = TextEditingController();
  String? _error;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _steps.text = '${app.goals.steps}';
    _minutes.text = '${app.goals.minutes}';
    _calories.text = '${app.goals.calories}';
    _weight.text = app.weightKg % 1 == 0
        ? app.weightKg.toStringAsFixed(0)
        : app.weightKg.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _steps.dispose();
    _minutes.dispose();
    _calories.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveGoals() async {
    final app = AppScope.of(context);
    final s = int.tryParse(_steps.text.trim()) ?? 0;
    final m = int.tryParse(_minutes.text.trim()) ?? 0;
    final c = int.tryParse(_calories.text.trim()) ?? 0;
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.')) ?? 0;

    String? err;
    if (s < 500 || s > 100000) {
      err = 'Steps goal must be between 500 and 100,000.';
    } else if (m < 5 || m > 600) {
      err = 'Workout goal must be between 5 and 600 minutes.';
    } else if (c < 50 || c > 10000) {
      err = 'Calorie goal must be between 50 and 10,000.';
    } else if (w < 20 || w > 300) {
      err = 'Weight must be between 20 and 300 kg.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    await app.saveGoals(Goals(steps: s, minutes: m, calories: c), w);
    _snack('Goals saved');
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _copyCsv(AppState app) async {
    if (app.entries.isEmpty) {
      _snack('Nothing to export yet');
      return;
    }
    await Clipboard.setData(ClipboardData(text: app.toCsv()));
    _snack('CSV copied to clipboard');
  }

  Future<void> _addSample(AppState app) async {
    if (app.entries.isNotEmpty &&
        !await _confirm('Add sample data?',
            'This adds 3 weeks of demo entries to your existing data.', 'Add')) {
      return;
    }
    await app.addSampleData();
  }

  Future<void> _clear(AppState app) async {
    if (app.entries.isEmpty) {
      _snack('There is nothing to delete');
      return;
    }
    final ok = await _confirm(
      'Delete all entries?',
      'All ${app.entries.length} entries will be removed. Your goals are kept. This cannot be undone.',
      'Delete all',
    );
    if (!ok) return;
    await app.clearEntries();
    _snack('All entries deleted');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const ScreenHeader(
          title: 'Goals & data',
          subtitle: 'Set your daily targets and manage what is saved on this device.',
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Daily goals',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _numberField(_steps, 'Steps per day'),
              const SizedBox(height: 14),
              _numberField(_minutes, 'Workout minutes per day'),
              const SizedBox(height: 14),
              _numberField(_calories, 'Calories burned per day'),
              const SizedBox(height: 14),
              TextField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: fieldDecoration(
                  'Your weight (kg)',
                  helper: 'Used only to estimate calories.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: kDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveGoals,
                child: const Text('Save goals'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your data',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Everything is stored on this device. Nothing is uploaded.',
                style: TextStyle(color: kMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _copyCsv(app),
                child: const Text('Copy data as CSV'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _addSample(app),
                child: const Text('Add 3 weeks of sample data'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: kDanger),
                onPressed: () => _clear(app),
                child: const Text('Delete all entries'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: fieldDecoration(label),
    );
  }
}
