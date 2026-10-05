import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DepartmentToolDefinition {
  const DepartmentToolDefinition(
      this.name, this.title, this.description, this.icon);
  final String name;
  final String title;
  final String description;
  final IconData icon;
  static DepartmentToolDefinition? forName(String name) {
    final normalized = name.trim().toLowerCase().replaceAll('\u2019', "'");
    for (final entry in all) {
      if (entry.name.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  static const all = [
    DepartmentToolDefinition(
        'Ushering & Protocol',
        'Attendance counter slip',
        'Count attendance by section and prepare service totals.',
        PhosphorIconsRegular.users),
    DepartmentToolDefinition(
        'ICARE',
        'First-timer intake',
        'Welcome first-timers and coordinate follow-up.',
        PhosphorIconsRegular.userPlus),
    DepartmentToolDefinition(
        'Evangelism & Outreach',
        'Outreach intake',
        'Record outreach contacts and organize follow-up.',
        PhosphorIconsRegular.megaphone),
    DepartmentToolDefinition(
        'Accounts',
        'Reconciliation checklist',
        'Check reconciliations and track discrepancies.',
        PhosphorIconsRegular.calculator),
    DepartmentToolDefinition(
        "Children's Department",
        'Lesson plan',
        'Prepare lessons and coordinate adult volunteers.',
        PhosphorIconsRegular.bookOpen),
    DepartmentToolDefinition(
        'Creativity',
        'Creative brief',
        'Plan creative work and review deliverables.',
        PhosphorIconsRegular.pencilRuler),
    DepartmentToolDefinition(
        'Decoration',
        'Setup plan',
        'Organize setup, materials and completion checks.',
        PhosphorIconsRegular.paintBrush),
    DepartmentToolDefinition(
        'Directorate of Works',
        'Maintenance request',
        'Track maintenance needs and repair progress.',
        PhosphorIconsRegular.wrench),
    DepartmentToolDefinition(
        'Life Plus Church',
        'Teen-service programme',
        'Plan teen services, teaching and volunteer cover.',
        PhosphorIconsRegular.student),
    DepartmentToolDefinition(
        'Media & Technical',
        'Production checklist',
        'Prepare production checks and flag equipment faults.',
        PhosphorIconsRegular.videoCamera),
    DepartmentToolDefinition(
        'Pastorate',
        'Ministry summary',
        'Review ministry activity and operational needs.',
        PhosphorIconsRegular.clipboardText),
    DepartmentToolDefinition(
        'Power House',
        'Prayer-session plan',
        'Prepare prayer sessions, guides and facilitators.',
        PhosphorIconsRegular.handsPraying),
    DepartmentToolDefinition(
        'Prayer & Intercession',
        'Prayer-duty schedule',
        'Coordinate prayer duties and approved themes.',
        PhosphorIconsRegular.calendar),
    DepartmentToolDefinition('Sanctuary', 'Service readiness',
        'Check each service area is ready.', PhosphorIconsRegular.checkSquare),
    DepartmentToolDefinition(
        'Security',
        'Duty acknowledgement',
        'Confirm duty posts, shifts and handovers.',
        PhosphorIconsRegular.shieldCheck),
    DepartmentToolDefinition(
        'Transport',
        'Trip request',
        'Plan routes, capacity and driver requirements.',
        PhosphorIconsRegular.bus),
    DepartmentToolDefinition(
        'Welfare',
        'Service-support request',
        'Coordinate practical support and service supplies.',
        PhosphorIconsRegular.handHeart),
    DepartmentToolDefinition(
        'Wisdom Streams',
        'Setlist & rehearsal',
        'Prepare setlists, arrangements and rehearsals.',
        PhosphorIconsRegular.musicNotes),
    DepartmentToolDefinition(
        'Worship & Music',
        'Worship-service order',
        'Plan worship order, songs and rehearsal resources.',
        PhosphorIconsRegular.microphone),
    DepartmentToolDefinition(
        'Youth & Teen Ministry',
        'Programme plan',
        'Organize programmes and adult volunteer cover.',
        PhosphorIconsRegular.student),
  ];
}
