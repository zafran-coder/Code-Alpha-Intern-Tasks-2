import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/panel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = '';

  Future<void> _confirmDelete(AppState app, Entry e) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('${e.title} on ${longDate(parseIso(e.date))} will be removed. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteEntry(e.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.entries;
    final list = all.where((e) => _filter.isEmpty || e.exercise == _filter).toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });

    // group by date (list is already sorted newest first)
    final dates = <String>[];
    final groups = <String, List<Entry>>{};
    for (final e in list) {
      if (!groups.containsKey(e.date)) {
        dates.add(e.date);
        groups[e.date] = [];
      }
      groups[e.date]!.add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        ScreenHeader(
          title: 'History',
          subtitle: all.isEmpty
              ? 'Your logged activity will show up here.'
              : '${all.length} ${all.length == 1 ? 'entry' : 'entries'} saved on this device.',
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: fieldDecoration('Show'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filter,
              isExpanded: true,
              isDense: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('All activity')),
                for (final name in kExercises.keys)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (v) => setState(() => _filter = v ?? ''),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Panel(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  all.isEmpty
                      ? 'No activity logged yet'
                      : 'No entries for that exercise',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  all.isEmpty
                      ? 'Add your first workout or step count to start tracking.'
                      : 'Try another filter.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
                if (all.isEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => app.goTo(1),
                    child: const Text('Log activity'),
                  ),
                ],
              ],
            ),
          )
        else
          for (final date in dates) ...[
            _DayGroup(date: date, entries: groups[date]!, onDelete: (e) => _confirmDelete(app, e)),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.entries,
    required this.onDelete,
  });

  final String date;
  final List<Entry> entries;
  final void Function(Entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final day = parseIso(date);
    var steps = 0, minutes = 0, calories = 0;
    for (final e in entries) {
      steps += e.steps;
      minutes += e.minutes;
      calories += e.calories;
    }

    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF6F8FB),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sameDay(day, today()) ? 'Today' : longDate(day),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmtInt(steps)} steps · $minutes min · ${fmtInt(calories)} kcal',
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: kLine),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          entries[i].meta,
                          style: const TextStyle(color: kMuted, fontSize: 14),
                        ),
                        if (entries[i].note.isNotEmpty)
                          Text(
                            entries[i].note,
                            style: const TextStyle(
                              color: kMuted,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => app.startEdit(entries[i]),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => onDelete(entries[i]),
                    icon: const Icon(Icons.delete_outline, color: kDanger),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
