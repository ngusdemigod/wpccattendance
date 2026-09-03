import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/database/database.dart';

class ResolvedProfileIdentity {
  const ResolvedProfileIdentity({
    required this.authUserId,
    required this.profileUserId,
    required this.membershipCode,
    required this.email,
    required this.isDirectAuthMatch,
  });

  final String authUserId;
  final String profileUserId;
  final String membershipCode;
  final String email;
  final bool isDirectAuthMatch;
}

class ProfileIdentityResolver {
  static ResolvedProfileIdentity? _cachedIdentity;
  static String? _cachedForAuthUid;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  static void clearCache() {
    _cachedIdentity = null;
    _cachedForAuthUid = null;
    _cachedAt = null;
  }

  Future<ResolvedProfileIdentity> resolveCurrentUser() async {
    if (currentUserUid.isEmpty) {
      throw StateError('No authenticated user.');
    }

    final cached = _cachedIdentity;
    final cachedAt = _cachedAt;
    if (cached != null &&
        _cachedForAuthUid == currentUserUid &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final resolved = await _resolveCurrentProfileIdentity();
    if (resolved == null) {
      final fallback = ResolvedProfileIdentity(
        authUserId: currentUserUid,
        profileUserId: currentUserUid,
        membershipCode: _currentMembershipCode(),
        email: currentUserEmail.trim(),
        isDirectAuthMatch: true,
      );
      _cacheIdentity(fallback);
      return fallback;
    }

    if (!resolved.isDirectAuthMatch &&
        resolved.profileUserId.isNotEmpty &&
        resolved.profileUserId != currentUserUid) {
      await relinkCurrentAuthProfile();
      final relinked = await _resolveCurrentProfileIdentity();
      if (relinked != null) {
        _cacheIdentity(relinked);
        return relinked;
      }
    }

    _cacheIdentity(resolved);
    return resolved;
  }

  void _cacheIdentity(ResolvedProfileIdentity identity) {
    _cachedIdentity = identity;
    _cachedForAuthUid = currentUserUid;
    _cachedAt = DateTime.now();
  }

  Future<void> relinkCurrentAuthProfile() async {
    if (currentUserUid.isEmpty) {
      throw StateError('No authenticated user.');
    }

    clearCache();
    await SupaFlow.client.rpc('relink_current_auth_profile');
  }

  Future<ResolvedProfileIdentity?> _resolveCurrentProfileIdentity() async {
    final dynamic response =
        await SupaFlow.client.rpc('resolve_current_profile_identity');

    final row = _coerceRow(response);
    if (row == null) {
      return null;
    }

    final profileUserId = row['profile_user_id']?.toString().trim() ?? '';
    if (profileUserId.isEmpty) {
      return null;
    }

    return ResolvedProfileIdentity(
      authUserId: currentUserUid,
      profileUserId: profileUserId,
      membershipCode:
          row['membership_code']?.toString().trim() ?? _currentMembershipCode(),
      email: row['email']?.toString().trim() ?? currentUserEmail.trim(),
      isDirectAuthMatch: (row['is_direct_auth_match'] == true) ||
          profileUserId == currentUserUid,
    );
  }

  Map<String, dynamic>? _coerceRow(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return first.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (response is Map) {
      return response.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
  }

  String _currentMembershipCode() {
    final user = SupaFlow.client.auth.currentUser;
    final rawUserMetadata = user?.userMetadata;
    final rawAppMetadata = user?.appMetadata;

    final userMembership = rawUserMetadata?['membership_code']?.toString();
    final appMembership = rawAppMetadata?['membership_code']?.toString();

    return (userMembership?.trim().isNotEmpty ?? false)
        ? userMembership!.trim()
        : (appMembership?.trim() ?? '');
  }
}
