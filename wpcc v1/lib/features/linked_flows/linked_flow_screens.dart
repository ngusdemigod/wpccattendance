import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../flutter_flow/custom_icons.dart';

/// Live-data entry screens for flows not represented by a legacy Flutter page.
/// They deliberately query the existing backend and never supply sample records.
class SoulsScreen extends StatelessWidget {
  const SoulsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LiveCollectionScreen(
        title: 'Souls',
        subtitle: 'Your soul-winning journey',
        table: 'souls',
        icon: FFIcons.kuserPlus,
      );
}

class CounsellingScreen extends StatelessWidget {
  const CounsellingScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LiveCollectionScreen(
        title: 'Counselling',
        subtitle: 'Private care and appointments',
        table: 'counselling_bookings',
        icon: FFIcons.kchatsCircle,
      );
}

class GivingScreen extends StatelessWidget {
  const GivingScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LiveCollectionScreen(
        title: 'Give',
        subtitle: 'Your giving history',
        table: 'giving_transactions',
        icon: FFIcons.khandHeart,
      );
}

class _LiveCollectionScreen extends StatelessWidget {
  const _LiveCollectionScreen({required this.title, required this.subtitle, required this.table, required this.icon});
  final String title, subtitle, table;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6F7FA),
        appBar: AppBar(backgroundColor: const Color(0xFFF6F7FA), elevation: 0, leading: IconButton(icon: const Icon(FFIcons.karrowLeft), onPressed: () => Navigator.of(context).pop()), title: Text(title, style: GoogleFonts.urbanist(color: const Color(0xFF303239), fontWeight: FontWeight.w600))),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: Supabase.instance.client.from(table).select().limit(30),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('This service is not available for your account.', textAlign: TextAlign.center, style: GoogleFonts.urbanist(color: const Color(0xFF7E828A)))));
            final records = snapshot.data ?? const [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF303239), borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(icon, color: Colors.white, size: 30), const SizedBox(width: 14), Expanded(child: Text(subtitle, style: GoogleFonts.urbanist(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)))])),
              const SizedBox(height: 16),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Center(child: Text('No records yet', style: GoogleFonts.urbanist(color: const Color(0xFF7E828A)))),
                ),
              ...records.map(
                (record) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Text((record['title'] ?? record['full_name'] ?? record['purpose'] ?? 'Record').toString(), style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                ),
              ),
            ]);
          },
        ),
      );
}
