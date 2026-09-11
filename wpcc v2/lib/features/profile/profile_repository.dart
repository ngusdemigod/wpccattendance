import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<Map<String,dynamic>?> profile() async {
    final data=await client.rpc('current_my_profile');
    if(data is List&&data.isNotEmpty)return Map<String,dynamic>.from(data.first as Map);
    if(data is Map)return Map<String,dynamic>.from(data);
    return null;
  }

  Future<List<Map<String,dynamic>>> classes() async {
    final data=await client.rpc('current_my_classes');
    return (data as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String,dynamic>>> queries() async {
    final data=await client.rpc('current_my_queries');
    return (data as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<Map<String,dynamic>> submitQuery({required String title,required String details}) async {
    final data=await client.rpc('submit_my_query',params:{'p_title':title,'p_details':details});
    return Map<String,dynamic>.from(data as Map);
  }

  Future<void> updateAllowedDetails({String? bio,String? occupation,String? address}) async {
    final uid=client.auth.currentUser?.id;
    if(uid==null)throw StateError('Authentication required');
    if(bio!=null)await client.from('profiles').update({'bio':bio}).eq('id',uid);
    final values=<String,dynamic>{};
    if(occupation!=null)values['occupation']=occupation;
    if(address!=null)values['residential_address']=address;
    if(values.isNotEmpty)await client.from('profiles_priv_info').update(values).eq('id',uid);
  }
}
