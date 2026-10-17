import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entry.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/panel.dart';

/// Add a new entry, or edit [entry] when it is not null.
class LogScreen extends StatefulWidget {
  const LogScreen({super.key, this.entry});

  final Entry? entry;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _steps = TextEditingController();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  final _note = TextEditingController();

  DateTime _date = today();
  String _exercise = '';
  String? _error;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;

    final e = widget.entry;
    if (e != null) {
      _date = parseIso(e.date);
      _exercise = e.exercise;
      _steps.text = e.steps > 0 ? '${e.steps}' : '';
      _minutes.text = e.minutes > 0 ? '${e.minutes}' : '';
      _calories.text = (!e.estimated && e.calories > 0) ? '${e.calories}' : '';
      _note.text = e.note;
    } else {
      final sel = AppScope.of(context).selected;
      _date = sel.isAfter(today()) ? today() : sel;
    }
  }

  @override
  void dispose() {
    _steps.dispose();
    _minutes.dispose();
    _calories.dispose();
    _note.dispose();
    super.dispose();
  }

  int _num(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: today(),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _save() async {
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final steps = _num(_steps);
    final minutes = _num(_minutes);
    var calories = _num(_calories);

    String? err;
    if (_date.isAfter(today())) {
      err = 'You can only log activity up to today.';
    } else if (steps > 100000) {
      err = 'Steps look too high. Enter 100,000 or fewer.';
    } else if (minutes > 1440) {
      err = 'A day only has 1,440 minutes.';
    } else if (calories > 20000) {
      err = 'Calories look too high. Enter 20,000 or fewer.';
    } else if (_exercise.isNotEmpty && minutes == 0) {
      err = 'Add how long the workout lasted.';
    } else if (minutes > 0 && _exercise.isEmpty) {
      err = 'Choose the exercise type for those minutes.';
    } else if (steps == 0 && minutes == 0 && calories == 0) {
      err = 'Add steps, a workout, or calories before saving.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    var estimated = false;
    if (calories == 0) {
      calories = app.estimateCalories(_exercise, minutes, steps);
      estimated = calories > 0;
    }

    final wasEditing = widget.entry != null;
    final entry = Entry(
      id: widget.entry?.id ?? app.newId(),
      date: isoDate(_date),
      exercise: _exercise,
      minutes: minutes,
      steps: steps,
      calories: calories,
      estimated: estimated,
      note: _note.text.trim(),
    );

    final message = wasEditing
        ? 'Changes saved'
        : 'Saved: ${entry.title}${minutes > 0 ? ', $minutes min' : ''}';

    FocusScope.of(context).unfocus();
    await app.saveEntry(entry);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final editing = widget.entry != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        ScreenHeader(
          title: editing ? 'Edit entry' : 'Log activity',
          subtitle: editing
              ? 'Change the details and save.'
              : 'Add steps, a workout, or both for a day.',
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: fieldDecoration('Date'),
                  child: Row(
                    children: [
                      Expanded(child: Text(longDate(_date))),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _steps,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: fieldDecoration('Steps', hint: 'e.g. 8200'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Workout (optional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: fieldDecoration('Exercise type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _exercise,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('No workout'),
                      ),
                      for (final name in kExercises.keys)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (v) => setState(() => _exercise = v ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    fieldDecoration('Duration (minutes)', hint: 'e.g. 35'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _calories,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: fieldDecoration(
                  'Calories burned',
                  hint: 'Leave blank to estimate',
                  helper:
                      'Estimated from the exercise, duration and your weight (${app.weightKg.toStringAsFixed(app.weightKg % 1 == 0 ? 0 : 1)} kg), or from steps.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                maxLength: 120,
                decoration: fieldDecoration('Note (optional)',
                    hint: 'Morning run by the lake'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
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
                onPressed: _save,
                child: Text(editing ? 'Save changes' : 'Save entry'),
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: app.cancelEdit,
                  child: const Text('Cancel edit'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
