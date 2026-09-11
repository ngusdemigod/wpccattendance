import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/animated_search_filter.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/section_empty_state.dart';
import 'department_repository.dart';

class DepartmentDetailPage extends StatefulWidget {
  const DepartmentDetailPage({super.key, required this.departmentId, this.seed});
  final String departmentId;
  final Map<String, dynamic>? seed;
  @override State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> with SingleTickerProviderStateMixin {
  final repo = DepartmentRepository();
  int tab = 0;
  int direction = 1;
  String memberSearch = '';
  String memberFilter = 'All members';
  String attendanceSearch = '';
  String attendanceFilter = 'All events';
  String fileSearch = '';
  String fileFilter = 'All files';
  late Future<List<Map<String, dynamic>>> leaders;
  late Future<List<Map<String, dynamic>>> members;
  late Future<List<Map<String, dynamic>>> attendance;
  late Future<List<Map<String, dynamic>>> files;
  late Future<Map<String, dynamic>?> deptContext;
  late Future<List<Map<String, dynamic>>> wallets;
  Map<String,dynamic>? currentDepartment;
  final ScrollController scrollController = ScrollController();
  bool headerFrosted = false;

  @override
  void initState() {
    super.initState();
    currentDepartment = widget.seed;
    leaders = repo.leadership(widget.departmentId);
    members = repo.members(widget.departmentId);
    attendance = repo.attendanceEvents(widget.departmentId);
    files = repo.files(widget.departmentId);
    deptContext = repo.context(widget.departmentId);
    wallets = repo.wallets(widget.departmentId);
    deptContext.then((value){if(mounted&&value!=null)setState(()=>currentDepartment=value);});
    scrollController.addListener(() {
      final next = scrollController.offset > 195;
      if (next != headerFrosted && mounted) setState(() => headerFrosted = next);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void selectTab(int next) {
    if (next == tab) return;
    setState(() { direction = next > tab ? 1 : -1; tab = next; });
  }

  @override
  Widget build(BuildContext context) {
    final name = currentDepartment?['name']?.toString() ?? 'Department';
    return Scaffold(
      body: CustomScrollView(controller: scrollController, slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 290,
          elevation: 0,
          backgroundColor: headerFrosted ? Colors.white.withValues(alpha: .88) : Colors.transparent,
          foregroundColor: headerFrosted ? WpccColors.ink : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text('Department', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: headerFrosted ? WpccColors.ink : Colors.white)),
          actions: [FutureBuilder<Map<String,dynamic>?>(future:deptContext,builder:(context,s){
            final canManage=s.data?['can_manage']==true;
            if(!canManage)return const SizedBox.shrink();
            return PopupMenuButton<String>(icon:Icon(PhosphorIcons.dotsThree(),size:21),onSelected:_departmentAction,itemBuilder:(context)=>[
              const PopupMenuItem(value:'announcement',child:Text('Post announcement',style:TextStyle(fontSize:12))),
              const PopupMenuItem(value:'event',child:Text('Create event',style:TextStyle(fontSize:12))),
              const PopupMenuItem(value:'files',child:Text('Manage files',style:TextStyle(fontSize:12))),
              const PopupMenuItem(value:'profile',child:Text('Change profile',style:TextStyle(fontSize:12))),
              const PopupMenuItem(value:'wallet',child:Text('New wallet',style:TextStyle(fontSize:12))),
            ]);
          })],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              if((currentDepartment?['cover_url']?.toString()??'').isNotEmpty) Image.network(currentDepartment!['cover_url'].toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF3D3E4C),Color(0xFF777A8B)])))) else const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3D3E4C), Color(0xFF777A8B)]))),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xB3000000)]))),
              Positioned(left: 18, right: 18, bottom: 28, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: -.7)),
                const SizedBox(height: 7),
                if(currentDepartment?['member_count']!=null)...[Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(99)),child:Text('${currentDepartment!['member_count']} members',style:const TextStyle(fontSize:10,color:Colors.white)))],
                Text(currentDepartment?['description']?.toString() ?? 'Department community and resources.', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ])),
            ]),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsDelegate(
            child: Container(
              color: WpccColors.background,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Row(children: List.generate(4, (i) {
                const names = ['Overview', 'Members', 'Attendance', 'Files'];
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    selected: tab == i,
                    showCheckmark: false,
                    label: Text(names[i]),
                    onSelected: (_) => selectTab(i),
                    selectedColor: WpccColors.ink,
                    backgroundColor: Colors.white,
                    labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: tab == i ? Colors.white : WpccColors.inkSoft),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                );
              })),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 210),
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(begin: Offset(.045 * direction, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(opacity: animation, child: SlideTransition(position: offset, child: child));
            },
            child: Padding(
              key: ValueKey(tab),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
              child: switch (tab) {
                0 => _overview(),
                1 => _members(),
                2 => _attendance(),
                _ => _files(),
              },
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _departmentAction(String action) async {
    final route=switch(action){
      'announcement'=>'/departments/${widget.departmentId}/announcement',
      'event'=>'/departments/${widget.departmentId}/event/new',
      'files'=>'/departments/${widget.departmentId}/files/manage',
      'profile'=>'/departments/${widget.departmentId}/profile/edit',
      'wallet'=>'/departments/${widget.departmentId}/wallet/new',
      _=>null,
    };
    if(route==null)return;
    final changed=await context.push<bool>(route);
    if(changed==true&&mounted){final fresh=await repo.context(widget.departmentId);if(!mounted)return;setState((){currentDepartment=fresh??currentDepartment;deptContext=Future.value(fresh);wallets=repo.wallets(widget.departmentId);files=repo.files(widget.departmentId);attendance=repo.attendanceEvents(widget.departmentId);});}
  }

  Widget _overview() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    FutureBuilder<List<Map<String, dynamic>>>(
      future: leaders,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done) return const SizedBox(height: 110);
        return SizedBox(
          height: 112,
          child: rows.isEmpty ? SectionEmptyState(icon: PhosphorIcons.userCircle(), message: 'No leadership profiles', height: 110) : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final row = rows[i];
              return SizedBox(width: 84, child: Column(children: [
                InitialsAvatar(initials: row['initials']?.toString() ?? '--', imageUrl: row['avatar']?.toString(), size: 62),
                const SizedBox(height: 6),
                Text(row['full_name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
                Text(row['title_name']?.toString() ?? 'Leader', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: WpccColors.muted)),
              ]));
            },
          ),
        );
      },
    ),
    const SizedBox(height: 20),
    Text('Departmental wallet', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    FutureBuilder<List<Map<String,dynamic>>>(future:wallets,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const SizedBox(height:120,child:Center(child:CircularProgressIndicator()));
      final rows=s.data??const[];
      if(rows.isEmpty)return SectionEmptyState(icon: PhosphorIcons.wallet(), message: 'No departmental wallet yet', height: 140);
      return SizedBox(height:140,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(context,i){final w=rows[i];return Container(width:270,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:WpccColors.ink,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(w['wallet_name']?.toString()??'Department wallet',style:const TextStyle(fontSize:11,color:Colors.white70)),const Spacer(),Text(w['account_number']?.toString()??'',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w600,color:Colors.white)),const SizedBox(height:4),Text(w['account_name']?.toString()??'',style:const TextStyle(fontSize:11,color:Colors.white)),Text(w['bank_name']?.toString()??'',style:const TextStyle(fontSize:10,color:Colors.white70))]));}));
    }),
  ]);

  Widget _members() => FutureBuilder<List<Map<String, dynamic>>>(
    future: members,
    builder: (context, snapshot) {
      final all = snapshot.data ?? const [];
      final query = memberSearch.trim().toLowerCase();
      final rows = all.where((m) {
        final text = '${m['full_name']} ${m['role_name']}'.toLowerCase();
        final filterOk = memberFilter == 'All members' || m['role_name']?.toString().toLowerCase() == memberFilter.toLowerCase();
        return (query.isEmpty || text.contains(query)) && filterOk;
      }).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Members', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500))),
          AnimatedSearchFilter(hint: 'Search members', onSearch: (v) => setState(() => memberSearch = v), filterOptions: const ['All members', 'worker', 'member', 'dept_leader'], selectedFilter: memberFilter, onFilter: (v) => setState(() => memberFilter = v)),
        ]),
        const SizedBox(height: 10),
        if (snapshot.connectionState != ConnectionState.done)
          const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
        else
          _FilterAnimated(
            stateKey: 'members:$memberSearch:$memberFilter:${rows.map((e) => e['user_id']).join(',')}',
            child: rows.isEmpty
                ? SectionEmptyState(icon: PhosphorIcons.userList(), message: 'No members found', height: 170)
                : Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      child: Column(children: rows.map((m) => _AnimatedFilteredRow(
                        key: ValueKey(m['user_id']),
                        child: InkWell(
                          onTap: () => _showMember(m['user_id'].toString()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                            child: Row(children: [
                              InitialsAvatar(initials: m['initials']?.toString() ?? '--', imageUrl: m['avatar']?.toString(), size: 38),
                              const SizedBox(width: 11),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['full_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(m['role_name']?.toString() ?? 'Member', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: WpccColors.muted)),
                              ])),
                            ]),
                          ),
                        ),
                      )).toList()),
                    ),
                  ),
          ),
      ]);
    },
  );

  Future<void> _showMember(String id) async {
    final data = await repo.publicMember(id);
    if (!mounted || data == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(vsync: this, duration: const Duration(milliseconds: 220)),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .62,
        minChildSize: .42,
        maxChildSize: .84,
        builder: (context, scroll) => Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: ListView(controller: scroll, children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD9DBE1), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Center(child: GestureDetector(
              onTap: () => _expandAvatar(data),
              child: InitialsAvatar(initials: data['initials']?.toString() ?? '--', imageUrl: data['avatar']?.toString(), size: 96),
            )),
            const SizedBox(height: 12),
            Text(data['full_name']?.toString() ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _DetailCard(icon: PhosphorIcons.phone(), label: 'Phone number', value: data['phone']?.toString() ?? 'Not available'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: WpccColors.line), borderRadius: BorderRadius.circular(22)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(PhosphorIcons.usersThree(), size: 19), const SizedBox(width: 10), Text('Departments', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted))]),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: ((data['departments'] as List?) ?? const []).map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(border: Border.all(color: WpccColors.line), borderRadius: BorderRadius.circular(99)),
                  child: Text((d as Map)['name']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                )).toList()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _expandAvatar(Map<String, dynamic> data) => showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0xD411131B),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      InitialsAvatar(initials: data['initials']?.toString() ?? '--', imageUrl: data['avatar']?.toString(), size: math.min(MediaQuery.sizeOf(context).width * .72, 290)),
      const SizedBox(height: 20),
      Text(data['full_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
    ])),
  );

  Widget _attendance() => FutureBuilder<List<Map<String, dynamic>>>(
    future: attendance,
    builder: (context, snapshot) {
      final query = attendanceSearch.toLowerCase();
      final rows = (snapshot.data ?? const []).where((e) { final category=(e['event_type']?.toString()??'').toLowerCase(); final filterOk=attendanceFilter=='All events'||category==attendanceFilter.toLowerCase(); return (query.isEmpty || e['title'].toString().toLowerCase().contains(query))&&filterOk; }).toList();
      return Column(children: [
        Row(children: [
          Expanded(child: Text('Attendance', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500))),
          AnimatedSearchFilter(hint: 'Search events', onSearch: (v) => setState(() => attendanceSearch = v), filterOptions: const ['All events','service','meeting','rehearsal','training','special'], selectedFilter: attendanceFilter, onFilter: (v) => setState(() => attendanceFilter = v)),
        ]),
        const SizedBox(height: 10),
        if (snapshot.connectionState != ConnectionState.done)
          const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())
        else
          _FilterAnimated(
            stateKey: 'attendance:$attendanceSearch:$attendanceFilter:${rows.map((e) => e['event_id']).join(',')}',
            child: rows.isEmpty
                ? SectionEmptyState(icon: PhosphorIcons.calendarX(), message: 'No attendance events found', height: 170)
                : Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: WpccColors.line), borderRadius: BorderRadius.circular(24)),
                    child: Column(children: rows.map((e) {
                      final start = DateTime.tryParse(e['event_start_at']?.toString() ?? '');
                      return _AnimatedFilteredRow(
                        key: ValueKey(e['event_id']),
                        child: InkWell(
                          onTap: () => _showAttendanceEvent(e),
                          child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [
                            Container(width: 42, height: 42, decoration: BoxDecoration(color: WpccColors.subtle, borderRadius: BorderRadius.circular(14)), child: Icon(PhosphorIcons.church(), size: 19)),
                            const SizedBox(width: 11),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e['title']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(start == null ? '' : WpccTime.compact(start.toIso8601String()), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: WpccColors.muted)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${e['present_count'] ?? 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), Text('Present', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: WpccColors.muted))]),
                            const SizedBox(width: 7),
                            Icon(PhosphorIcons.caretRight(), size: 15, color: WpccColors.muted),
                          ])),
                        ),
                      );
                    }).toList()),
                  ),
          ),
      ]);
    },
  );

  Future<void> _showAttendanceEvent(Map<String, dynamic> event) async {
    final rows = await repo.attendanceForEvent(widget.departmentId, event['event_id'].toString());
    if (!mounted) return;
    final start = DateTime.tryParse(event['event_start_at']?.toString() ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD9DBE1), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Text(event['title']?.toString() ?? 'Attendance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            if (start != null) Text(WpccTime.compact(start.toIso8601String()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Present members', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)), Text('Ranked by check-in time', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted))]),
            const SizedBox(height: 8),
            Expanded(child: rows.isEmpty ? SectionEmptyState(icon: PhosphorIcons.userList(), message: 'No present members') : ListView.builder(itemCount: rows.length, itemBuilder: (context, i) {
              final row = rows[i];
              final check = DateTime.tryParse(row['checked_in_at']?.toString() ?? '');
              final delta = row['minutes_from_start'] as int? ?? 0;
              final relative = delta == 0 ? 'On time' : delta < 0 ? '${delta.abs()} min early' : '$delta min late';
              return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
                InitialsAvatar(initials: row['initials']?.toString() ?? '--', imageUrl: row['avatar']?.toString(), size: 40),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(row['full_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)), Text(relative, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted))])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(check == null ? '' : WpccTime.eventTime(check.toIso8601String(), null), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('Check-in', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted))]),
              ]));
            })),
          ]),
        ),
      ),
    );
  }

  Widget _files() => FutureBuilder<List<Map<String, dynamic>>>(
    future: files,
    builder: (context, snapshot) {
      final query = fileSearch.toLowerCase();
      final rows = (snapshot.data ?? const []).where((f) {
        final mime = f['mime_type']?.toString() ?? '';
        final category = mime.startsWith('image/') ? 'Images' : mime.contains('spreadsheet') || mime == 'text/csv' ? 'Sheets' : 'Documents';
        return (query.isEmpty || f['file_name'].toString().toLowerCase().contains(query)) && (fileFilter == 'All files' || fileFilter == category);
      }).toList();
      return Column(children: [
        Row(children: [
          Expanded(child: Text('Files', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500))),
          AnimatedSearchFilter(hint: 'Search files', onSearch: (v) => setState(() => fileSearch = v), filterOptions: const ['All files', 'Documents', 'Sheets', 'Images'], selectedFilter: fileFilter, onFilter: (v) => setState(() => fileFilter = v)),
        ]),
        const SizedBox(height: 10),
        if (snapshot.connectionState != ConnectionState.done)
          const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())
        else
          _FilterAnimated(
            stateKey: 'files:$fileSearch:$fileFilter:${rows.map((e) => e['id']).join(',')}',
            child: rows.isEmpty
                ? SectionEmptyState(icon: PhosphorIcons.fileDashed(), message: 'No files found', height: 170)
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .9),
                    itemBuilder: (context, i) {
                      final f = rows[i];
                      final mime = f['mime_type']?.toString() ?? '';
                      final icon = mime.startsWith('image/') ? PhosphorIcons.image() : mime.contains('spreadsheet') || mime == 'text/csv' ? PhosphorIcons.table() : PhosphorIcons.fileText();
                      return _AnimatedFilteredRow(
                        key: ValueKey(f['id']),
                        child: InkWell(
                          borderRadius:BorderRadius.circular(22),
                          onTap:()async{try{await repo.openFile(f['id'].toString());}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to open file')));}},
                          child:Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: WpccColors.line)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: WpccColors.subtle, borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 30, color: WpccColors.inkSoft))),
                              const SizedBox(height: 8),
                              Text(f['file_name']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ]);
    },
  );
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.child}); final Widget child;
  @override double get minExtent => 58;
  @override double get maxExtent => 58;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(covariant _TabsDelegate oldDelegate) => true;
}

class _FilterAnimated extends StatelessWidget {
  const _FilterAnimated({required this.stateKey, required this.child});
  final String stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 190),
        reverseDuration: const Duration(milliseconds: 135),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, .018), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(stateKey), child: child),
      );
}

class _AnimatedFilteredRow extends StatelessWidget {
  const _AnimatedFilteredRow({super.key, required this.child}); final Widget child;
  @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(duration: const Duration(milliseconds: 190), tween: Tween(begin: 0, end: 1), curve: Curves.easeOutCubic, builder: (context, value, _) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 6 * (1-value)), child: child)));
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: WpccColors.line), borderRadius: BorderRadius.circular(22)), child: Row(children: [Icon(icon, size: 19), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted)), const SizedBox(height: 3), Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500))]))]));
}
