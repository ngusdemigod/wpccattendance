import '../../../backend/supabase/supabase.dart';
import '../models/global_search_models.dart';

class GlobalSearchRepository {
  Future<List<GlobalSearchResult>> search({
    required String query,
    SearchFilter filter = SearchFilter.all,
    int limitPerSection = 5,
  }) async {
    final rows = await SupaFlow.client.rpc('global_search', params: {
      'search_query': query,
      'search_filter': filter.rpcValue,
      'limit_per_section': limitPerSection,
    });
    return (rows as List)
        .whereType<Map>()
        .map((row) =>
            GlobalSearchResult.fromJson(Map<String, dynamic>.from(row)))
        .whereType<GlobalSearchResult>()
        .toList(growable: false);
  }
}
