import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRepository {
  SearchRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<List<Map<String,dynamic>>> search(String query) async {
    final q=query.trim();if(q.isEmpty)return [];
    final aggregate=await client.rpc('global_search',params:{'search_query':q,'search_filter':'all','limit_per_section':8});
    final rows=(aggregate as List).map((e)=>Map<String,dynamic>.from(e as Map)).where((e)=>e['section']!='people').toList();
    final myTeams=await client.rpc('community_departments',params:{'p_filter':'mine'});
    final ids=(myTeams as List).map((e)=>(e as Map)['department_id']?.toString()).whereType<String>().toSet();
    for(final id in ids){
      final people=await client.rpc('community_department_members',params:{'p_department_id':id,'p_search':q,'p_limit':8,'p_offset':0});
      for(final p in (people as List)){
        final m=Map<String,dynamic>.from(p as Map);
        if(rows.any((r)=>r['id']?.toString()==m['user_id']?.toString()))continue;
        rows.add({'section':'people','id':m['user_id'],'title':m['full_name'],'subtitle':m['department_name'],'body':m['role_name'],'image_url':m['avatar'],'result_type':'member','route':'','metadata':m});
      }
    }
    return rows;
  }
}
