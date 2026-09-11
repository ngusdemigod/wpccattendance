import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';

class DepartmentRepository {
  DepartmentRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<Map<String, dynamic>?> context(String departmentId) async {
    final rows = await client.rpc('community_department_context', params: {'p_department_id': departmentId});
    if (rows is List && rows.isNotEmpty) return Map<String,dynamic>.from(rows.first as Map);
    return null;
  }

  Future<List<Map<String, dynamic>>> members(String departmentId, {String search = ''}) async {
    final rows = await client.rpc('community_department_members', params: {'p_department_id': departmentId, 'p_search': search, 'p_limit': 100, 'p_offset': 0});
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> publicMember(String profileId) async {
    final rows = await client.rpc('community_public_member_profile', params: {'p_profile_id': profileId});
    if (rows is List && rows.isNotEmpty) return Map<String, dynamic>.from(rows.first as Map);
    return null;
  }

  Future<List<Map<String, dynamic>>> leadership(String departmentId) async {
    final rows = await client.rpc('community_department_leadership', params: {'p_department_id': departmentId});
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> attendanceEvents(String departmentId) async {
    final rows = await client.rpc('community_department_attendance_events', params: {'p_department_id': departmentId, 'p_limit': 100, 'p_offset': 0});
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> attendanceForEvent(String departmentId, String eventId) async {
    final rows = await client.rpc('community_department_event_attendance', params: {'p_department_id': departmentId, 'p_event_id': eventId});
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> files(String departmentId) async {
    final rows = await client.from('department_attachments').select('id,file_name,mime_type,size_bytes,created_at,visibility').eq('department_id', departmentId).order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String,dynamic>>> wallets(String departmentId) async {
    final rows = await client.from('church_bank_accounts').select('id,wallet_name,bank_name,account_name,account_number,purpose,style_variant').eq('department_id',departmentId).eq('is_active',true).order('display_order');
    return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<Map<String,dynamic>> createWallet({required String departmentId,required String walletName,required String bankName,required String accountNumber,required String accountName,String? purpose}) async {
    final result=await client.rpc('community_create_department_wallet',params:{'p_department_id':departmentId,'p_wallet_name':walletName,'p_bank_name':bankName,'p_account_number':accountNumber,'p_account_name':accountName,'p_purpose':purpose});
    return Map<String,dynamic>.from(result as Map);
  }

  Future<Map<String,dynamic>> createEvent({required String departmentId,required String eventType,required String title,String? description,required String startLocal,required String endLocal,String timezone='Africa/Lagos',String? featuredUrl,String? location}) async {
    final result=await client.rpc('community_create_department_event_local',params:{'p_department_id':departmentId,'p_event_type':eventType,'p_title':title,'p_description':description,'p_start_local':startLocal,'p_end_local':endLocal,'p_timezone':timezone,'p_featured_url':featuredUrl,'p_location':location,'p_latitude':null,'p_longitude':null});
    return Map<String,dynamic>.from(result as Map);
  }

  Future<Map<String,dynamic>> postAnnouncement({required String departmentId,required String title,required String content,String? mediaUrl}) async {
    final result=await client.rpc('community_post_department_announcement',params:{'p_department_id':departmentId,'p_title':title,'p_content':content,'p_media_url':mediaUrl});
    return Map<String,dynamic>.from(result as Map);
  }

  Future<Map<String,dynamic>> updateProfile({required String departmentId,required String name,String? description,String? coverUrl,String? avatarUrl}) async {
    final result=await client.rpc('community_update_department_profile',params:{'p_department_id':departmentId,'p_name':name,'p_description':description,'p_cover_url':coverUrl,'p_avatar_url':avatarUrl});
    return Map<String,dynamic>.from(result as Map);
  }

  Future<String> uploadPublicAsset({required String branchId,required String departmentId,required PlatformFile file,required String folder}) async {
    final bytes=file.bytes;if(bytes==null)throw StateError('Selected file could not be read');
    final safe=(file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'-'));
    final nonce=List.generate(12,(_)=>Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();
    final path='$folder/$branchId/$departmentId/$nonce-$safe';
    await client.storage.from('wpcc').uploadBinary(path,Uint8List.fromList(bytes),fileOptions:FileOptions(contentType:_contentType(file.extension),upsert:false));
    return client.storage.from('wpcc').getPublicUrl(path);
  }

  Future<Map<String,dynamic>> uploadPrivateFile({required String departmentId,required String branchId,required PlatformFile file,String visibility='members'}) async {
    final bytes=file.bytes;if(bytes==null)throw StateError('Selected file could not be read');
    final token=client.auth.currentSession?.accessToken;if(token==null)throw StateError('Authentication required');
    final uri=Uri.parse('${AppConfig.supabaseUrl}/functions/v1/churchmetric-private-files?action=upload');
    final request=http.MultipartRequest('POST',uri)
      ..headers['Authorization']='Bearer $token'
      ..headers['apikey']=AppConfig.supabasePublishableKey
      ..fields['department_id']=departmentId
      ..fields['branch_id']=branchId
      ..fields['visibility']=visibility
      ..files.add(http.MultipartFile.fromBytes('file',bytes,filename:file.name));
    final response=await request.send();final body=await response.stream.bytesToString();
    if(response.statusCode>=400)throw StateError('File upload failed');
    final data=body.isEmpty?<String,dynamic>{}:Map<String,dynamic>.from(jsonDecode(body) as Map);
    return Map<String,dynamic>.from((data['attachment'] as Map?)??data);
  }

  Future<void> toggleVisibility(String attachmentId,String visibility)=>client.rpc('community_update_attachment_visibility',params:{'p_attachment_id':attachmentId,'p_visibility':visibility});

  Future<void> deleteFile(String attachmentId) async {
    final token=client.auth.currentSession?.accessToken;if(token==null)throw StateError('Authentication required');
    final response=await http.post(Uri.parse('${AppConfig.supabaseUrl}/functions/v1/churchmetric-private-files?action=delete'),headers:{'Authorization':'Bearer $token','apikey':AppConfig.supabasePublishableKey,'Content-Type':'application/json'},body:'{"attachment_id":"$attachmentId"}');
    if(response.statusCode>=400)throw StateError('Unable to remove file');
  }

  Future<void> openFile(String attachmentId) async {
    final token=client.auth.currentSession?.accessToken;if(token==null)throw StateError('Authentication required');
    final response=await http.post(Uri.parse('${AppConfig.supabaseUrl}/functions/v1/churchmetric-private-files?action=download'),headers:{'Authorization':'Bearer $token','apikey':AppConfig.supabasePublishableKey,'Content-Type':'application/json'},body:'{"attachment_id":"$attachmentId"}');
    if(response.statusCode>=400)throw StateError('Unable to open file');
    final data=Map<String,dynamic>.from(jsonDecode(response.body) as Map);final uri=Uri.tryParse(data['url']?.toString()??'');if(uri==null)throw StateError('Download link unavailable');
    if(!await launchUrl(uri,webOnlyWindowName:'_blank'))throw StateError('Unable to open file');
  }

  String _contentType(String? ext)=>switch((ext??'').toLowerCase()){'jpg'||'jpeg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp',_=>'application/octet-stream'};
}
