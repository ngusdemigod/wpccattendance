import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_repository.dart';

final supabaseRepositoryProvider = Provider((ref) => SupabaseRepository());
final currentProfileProvider = FutureProvider((ref) => ref.watch(supabaseRepositoryProvider).currentProfile());
final myDepartmentsProvider = FutureProvider((ref) => ref.watch(supabaseRepositoryProvider).myDepartments());
final upcomingEventsProvider = FutureProvider((ref) => ref.watch(supabaseRepositoryProvider).upcomingEvents());
final announcementsProvider = FutureProvider((ref) => ref.watch(supabaseRepositoryProvider).announcements());
