import 'dart:js_interop';

import 'package:supabase_flutter/supabase_flutter.dart';

@JS('wpccPush.supported')
external JSPromise<JSBoolean> _pushSupported();

@JS('wpccPush.subscribe')
external JSPromise<JSAny?> _pushSubscribe(JSString vapidPublicKey);

class PushSubscriptionService {
  PushSubscriptionService([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<bool> isSupported() async {
    try {
      return (await _pushSupported().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  Future<void> enable({required String vapidPublicKey}) async {
    if (vapidPublicKey.trim().isEmpty) {
      throw StateError('Web Push is not configured for this deployment.');
    }

    final raw = await _pushSubscribe(vapidPublicKey.trim().toJS).toDart;
    final dartValue = raw?.dartify();
    if (dartValue is! Map) {
      throw StateError('The browser returned an invalid push subscription.');
    }

    final json = Map<String, dynamic>.from(dartValue);
    final keys = json['keys'];
    if (keys is! Map) {
      throw StateError('The browser push subscription has no encryption keys.');
    }

    final endpoint = json['endpoint']?.toString() ?? '';
    final p256dh = keys['p256dh']?.toString() ?? '';
    final auth = keys['auth']?.toString() ?? '';
    if (endpoint.isEmpty || p256dh.isEmpty || auth.isEmpty) {
      throw StateError('The browser push subscription is incomplete.');
    }

    await client.rpc('upsert_push_subscription', params: {
      'p_endpoint': endpoint,
      'p_p256dh_key': p256dh,
      'p_auth_key': auth,
      'p_device_name': null,
      'p_platform': 'web',
      'p_user_agent': null,
    });
  }
}
