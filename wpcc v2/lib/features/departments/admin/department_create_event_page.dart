import 'package:file_picker/file_picker.dart';
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
  State<DepartmentCreateEventPage> createState() => _DepartmentCreateEventPageState();
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
  PlatformFile? image;
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
    if (title.text.trim().length < 3 || startLocal == null || endLocal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add title, date, start time and end time.')));
      return;
    }
    setState(() => busy = true);
    try {
      String? imageUrl;
      if (image != null) {
        final branch = department?['branch_id']?.toString();
        if (branch == null) throw StateError('Department branch unavailable');
        imageUrl = await repo.uploadPublicAsset(branchId: branch, departmentId: widget.departmentId, file: image!, folder: 'departments');
      }
      await repo.createEvent(
        departmentId: widget.departmentId,
        eventType: type,
        title: title.text.trim(),
        description: description.text.trim(),
        startLocal: startLocal,
        endLocal: endLocal,
        featuredUrl: imageUrl,
        location: location.text.trim(),
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to create the event. Check your connection and try again.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
        title: const Text('Create event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          children: [
            InkWell(
              onTap: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                  if (!mounted) return;
                  if (result != null) setState(() => image = result.files.single);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to select that image. Please try again.')));
                }
              },
              child: Container(
                height: 170,
                decoration: BoxDecoration(color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.image(), size: 26),
                    const SizedBox(height: 8),
                    Text(image?.name ?? 'Add event image', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: ['service', 'meeting', 'rehearsal', 'training']
                  .map(
                    (value) => ChoiceChip(
                      label: Text('${value[0].toUpperCase()}${value.substring(1)}'),
                      selected: type == value,
                      onSelected: (_) => setState(() => type = value),
                      showCheckmark: false,
                      selectedColor: WpccColors.ink,
                      labelStyle: TextStyle(fontSize: 11, color: type == value ? Colors.white : WpccColors.inkSoft),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Event title')),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final selected = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (!mounted) return;
                if (selected != null) setState(() => date = selected);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(date == null ? 'Choose date' : DateFormat('EEE, d MMM yyyy').format(date!)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: 'Start time',
                    value: start,
                    onTap: () async {
                      final selected = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                      if (!mounted) return;
                      if (selected != null) setState(() => start = selected);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeBox(
                    label: 'End time',
                    value: end,
                    onTap: () async {
                      final selected = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 11, minute: 0));
                      if (!mounted) return;
                      if (selected != null) setState(() => end = selected);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10),
            TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: WpccColors.ink,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: busy ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Create event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.onTap});
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(value?.format(context) ?? 'Choose time'),
        ),
      );
}
