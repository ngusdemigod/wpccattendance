import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../department_repository.dart';

class DepartmentCreateEventPage extends StatefulWidget {
  const DepartmentCreateEventPage({super.key, required this.departmentId});
  final String departmentId;

  @override
  State<DepartmentCreateEventPage> createState() =>
      _DepartmentCreateEventPageState();
}

class _DepartmentCreateEventPageState extends State<DepartmentCreateEventPage> {
  final repo = DepartmentRepository();
  final title = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  String type = 'service';
  DateTime? date;
  TimeOfDay? start;
  TimeOfDay? end;
  Map<String, dynamic>? department;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    repo.context(widget.departmentId).then((value) {
      if (mounted) setState(() => department = value);
    });
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }

  String? _localTimestamp(TimeOfDay? value) {
    if (date == null || value == null) return null;
    final day = DateFormat('yyyy-MM-dd').format(date!);
    return '${day}T${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _save() async {
    final startLocal = _localTimestamp(start);
    final endLocal = _localTimestamp(end);
    if (title.text.trim().length < 3 ||
        startLocal == null ||
        endLocal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add title, date, start time and end time.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await repo.createEvent(
        departmentId: widget.departmentId,
        eventType: type,
        title: title.text.trim(),
        description: description.text.trim(),
        startLocal: startLocal,
        endLocal: endLocal,
        featuredUrl: null,
        location: location.text.trim(),
      );
      if (mounted) {
        context.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to create the event. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(PhosphorIcons.caretLeft(), size: 20),
        ),
        title: const Text(
          'Create event',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: busy ? null : _save,
            child: const Text(
              'Publish',
              style: TextStyle(fontSize: 12, color: Color(0xFF7D46B4)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: ['service', 'meeting', 'rehearsal', 'training']
                  .map(
                    (value) => ChoiceChip(
                      label: Text(
                        '${value[0].toUpperCase()}${value.substring(1)}',
                      ),
                      selected: type == value,
                      onSelected: (_) => setState(() => type = value),
                      showCheckmark: false,
                      selectedColor: WpccColors.ink,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color:
                            type == value ? Colors.white : WpccColors.inkSoft,
                      ),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: WpccColors.line),
              ),
              child: Column(
                children: [
                  _EventField(controller: title, label: 'Event title'),
                  _EventPicker(
                    label: 'Date',
                    value: date == null
                        ? 'Choose date'
                        : DateFormat('EEE, d MMM yyyy').format(date!),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime(2100),
                      );
                      if (mounted && selected != null) {
                        setState(() => date = selected);
                      }
                    },
                  ),
                  _EventPicker(
                    label: 'Time',
                    value: start == null || end == null
                        ? 'Choose start and end time'
                        : '${start!.format(context)} – ${end!.format(context)}',
                    onTap: () async {
                      final s = await showTimePicker(
                        context: context,
                        initialTime:
                            start ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (!context.mounted || s == null) return;
                      final e = await showTimePicker(
                        context: context,
                        initialTime:
                            end ?? const TimeOfDay(hour: 11, minute: 0),
                      );
                      if (mounted && e != null) {
                        setState(() {
                          start = s;
                          end = e;
                        });
                      }
                    },
                  ),
                  _EventField(controller: location, label: 'Location'),
                  _EventField(
                    controller: description,
                    label: 'Description',
                    maxLines: 4,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: WpccColors.ink,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: busy
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                  : const Text('Create event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPicker extends StatelessWidget {
  const _EventPicker({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: WpccColors.line)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: WpccColors.muted,
                      ),
                ),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}

class _EventField extends StatelessWidget {
  const _EventField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.isLast = false,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: WpccColors.line)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      );
}
