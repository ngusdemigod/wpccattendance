import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';
import 'souls_repository.dart';

class SoulsPage extends StatefulWidget {
  const SoulsPage({super.key, this.loadSouls});
  final Future<List<Map<String, dynamic>>> Function()? loadSouls;

  @override
  State<SoulsPage> createState() => _SoulsPageState();
}

class _SoulsPageState extends State<SoulsPage> {
  late final repository = SoulsRepository();
  late Future<List<Map<String, dynamic>>> souls;

  @override
  void initState() {
    super.initState();
    souls = (widget.loadSouls ?? repository.mine)();
  }

  Future<void> refresh() async {
    setState(() {
      souls = (widget.loadSouls ?? repository.mine)();
    });
    try {
      await souls;
    } catch (_) {}
  }

  Future<void> addSoul() async {
    final created = await showModalBottomSheet<bool>(
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _AddSoulSheet(repository: repository),
    );
    if (created == true) await refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.sizeOf(context).width >= 900 ? 820 : 1180),
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: memberPagePadding(context),
                  children: [
                    MemberPageHeader(
                      title: 'Souls',
                      onBack: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                      actions: [
                        MemberIconButton(
                          icon: PhosphorIconsRegular.plus,
                          label: 'Add a guest',
                          onPressed: addSoul,
                        )
                      ],
                    ),
                    Text('Keep in touch.',
                        style: MemberVisuals.display(context)),
                    const SizedBox(height: 17),
                    Text('People you are welcoming and following up.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 28),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: souls,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const MemberSkeleton();
                        }
                        if (snapshot.hasError) {
                          return MemberStatus(
                              icon: PhosphorIconsRegular.warningCircle,
                              message: 'Unable to load your souls',
                              onRetry: refresh);
                        }
                        final rows = snapshot.data ?? const [];
                        return Column(children: [
                          if (rows.isEmpty)
                            const MemberStatus(
                              icon: PhosphorIconsRegular.userPlus,
                              message: 'No souls added yet',
                            ),
                          for (var index = 0; index < rows.length; index++) ...[
                            if (index > 0) const SizedBox(height: 7),
                            MemberListRow(
                              leading: Container(
                                width: 64,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(PhosphorIconsRegular.user,
                                    size: 24),
                              ),
                              title: rows[index]['full_name']?.toString() ??
                                  'Soul',
                              subtitle: _statusLabel(
                                  rows[index]['status']?.toString()),
                              onTap: () => context.push(
                                  '/souls/${rows[index]['id']}',
                                  extra: rows[index]),
                            ),
                          ],
                        ]);
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: addSoul,
                          icon: const Icon(PhosphorIconsRegular.plus, size: 20),
                          label: const Text('Add a guest'),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class SoulDetailPage extends StatelessWidget {
  const SoulDetailPage({super.key, required this.soulId, this.seed});
  final String soulId;
  final Map<String, dynamic>? seed;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to my souls',
            onPressed: () => context.pop(),
            icon: Icon(PhosphorIcons.caretLeft()),
          ),
          title: const Text('Soul details'),
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: seed == null
              ? SoulsRepository().byId(soulId)
              : Future.value(seed),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final soul = snapshot.data;
            if (soul == null) {
              return const Center(child: Text('Soul not found'));
            }
            final wonAt = DateTime.tryParse(soul['won_at']?.toString() ?? '');
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: WpccColors.primarySoft,
                  child: Text(_initials(soul['full_name']?.toString() ?? ''),
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 16),
                Text(soul['full_name']?.toString() ?? 'Soul',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Center(
                    child: Chip(
                        label: Text(_statusLabel(soul['status']?.toString())))),
                const SizedBox(height: 24),
                _DetailCard(rows: [
                  ('Phone', soul['phone']),
                  ('Email', soul['email']),
                  ('Location', soul['location']),
                  ('Evangelist', soul['evangelist_name']),
                  (
                    'Won on',
                    wonAt == null
                        ? null
                        : DateFormat('d MMM yyyy, h:mm a')
                            .format(wonAt.toLocal())
                  ),
                ]),
              ],
            );
          },
        ),
      );
}

class _AddSoulSheet extends StatefulWidget {
  const _AddSoulSheet({required this.repository});
  final SoulsRepository repository;

  @override
  State<_AddSoulSheet> createState() => _AddSoulSheetState();
}

class _AddSoulSheetState extends State<_AddSoulSheet> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  late final Future<List<Map<String, dynamic>>> events;
  String? eventId;
  String? error;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    events = widget.repository.evangelismEvents();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!key.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.add(
          eventId: eventId!,
          fullName: name.text,
          email: email.text,
          phone: phone.text,
          location: location.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(
          child: Form(
            key: key,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Add a soul',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.x())),
              ]),
              const SizedBox(height: 14),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: events,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const [];
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: eventId,
                    decoration:
                        const InputDecoration(labelText: 'Evangelism event'),
                    items: rows
                        .map((row) => DropdownMenuItem(
                            value: row['id'].toString(),
                            child: Text(
                                row['title']?.toString() ?? 'Evangelism event',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: rows.isEmpty
                        ? null
                        : (value) => setState(() => eventId = value),
                    validator: (value) =>
                        value == null ? 'Choose an evangelism event' : null,
                    hint: Text(rows.isEmpty
                        ? 'No evangelism event is available'
                        : 'Select an event'),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter the full name'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: location,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Location')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                      onPressed: saving ? null : submit,
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add soul'))),
            ]),
          ),
        ),
      );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});
  final List<(String, Object?)> rows;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
              children: rows
                  .where((row) => row.$2?.toString().trim().isNotEmpty == true)
                  .map((row) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 92,
                                  child: Text(row.$1,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant))),
                              Expanded(child: Text(row.$2.toString())),
                            ]),
                      ))
                  .toList()),
        ),
      );
}

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

String _statusLabel(String? status) => (status ?? 'awaiting_contact')
    .split('_')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
