import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'give_repository.dart';

class GiveHomePage extends StatefulWidget {
  const GiveHomePage({super.key});
  @override State<GiveHomePage> createState() => _GiveHomePageState();
}

class _GiveHomePageState extends State<GiveHomePage> {
  final repo = GiveRepository();
  late Future<List<Map<String,dynamic>>> accounts;
  late Future<List<Map<String,dynamic>>> projects;
  @override void initState(){super.initState();_load();}
  void _load(){accounts=repo.accounts();projects=repo.projects();}

  @override Widget build(BuildContext context)=>SafeArea(bottom:false,child:RefreshIndicator(
    onRefresh:()async{setState(_load);await Future.wait([accounts,projects]);},
    child:ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
      Row(children:[Expanded(child:Text('Give',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w600,letterSpacing:-.7))),TextButton(onPressed:()=>context.push('/give/history'),child:const Text('History'))]),
      const SizedBox(height:18),
      FutureBuilder<List<Map<String,dynamic>>>(future:accounts,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const SizedBox(height:170,child:Center(child:CircularProgressIndicator()));
        if(s.hasError)return SectionEmptyState(icon:PhosphorIcons.warningCircle(),message:'Unable to load church accounts',height:170);
        final rows=s.data??const[]; if(rows.isEmpty)return SectionEmptyState(icon:PhosphorIcons.bank(),message:'No giving accounts configured',height:160);
        return SizedBox(height:170,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(context,i)=>_AccountCard(row:rows[i])));
      }),
      const SizedBox(height:24),
      Text('Quick Actions',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontSize:14,fontWeight:FontWeight.w500)),const SizedBox(height:10),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,mainAxisSpacing:8,crossAxisSpacing:8,childAspectRatio:.92,children:[
        _Action(label:'Offering',icon:PhosphorIcons.handCoins(),onTap:()=>_pay('offering','Offering')),
        _Action(label:'Tithe',icon:PhosphorIcons.wallet(),onTap:()=>_pay('tithe','Tithe')),
        _Action(label:'Prophet offering',icon:PhosphorIcons.heartStraight(),onTap:()=>_pay('prophet_offering','Prophet offering')),
        _Action(label:'Auto give',icon:PhosphorIcons.arrowsClockwise(),onTap:()=>context.push('/give/auto')),
      ]),
      const SizedBox(height:26),
      Text('Projects',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontSize:14,fontWeight:FontWeight.w500)),const SizedBox(height:10),
      FutureBuilder<List<Map<String,dynamic>>>(future:projects,builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const SizedBox(height:180,child:Center(child:CircularProgressIndicator()));
        if(s.hasError)return SectionEmptyState(icon:PhosphorIcons.warningCircle(),message:'Unable to load projects');
        final rows=s.data??const[]; if(rows.isEmpty)return SectionEmptyState(icon:PhosphorIcons.target(),message:'No active giving projects');
        return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:rows.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:.9),itemBuilder:(context,i)=>_ProjectCard(row:rows[i],onTap:()=>context.push('/give/payment',extra:{'giving_type':'project','title':rows[i]['title'],'project_id':rows[i]['id']})));
      }),
    ]),
  ));
  void _pay(String type,String title)=>context.push('/give/payment',extra:{'giving_type':type,'title':title});
}

class _AccountCard extends StatelessWidget{
  const _AccountCard({required this.row});final Map<String,dynamic> row;
  @override Widget build(BuildContext context){
    final variant=row['style_variant']?.toString()??'dark'; final dark=variant=='dark';
    final bg=variant=='warm'?const Color(0xFFF2E8DF):variant=='light'?Colors.white:WpccColors.ink;
    final fg=dark?Colors.white:WpccColors.ink; final muted=dark?Colors.white70:WpccColors.muted;
    return Container(width:300,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(27),border:dark?null:Border.all(color:WpccColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:dark?Colors.white12:const Color(0xFFF3F4F7),borderRadius:BorderRadius.circular(12)),child:Icon(PhosphorIcons.bank(),size:19,color:fg)),const Spacer(),if((row['wallet_name']?.toString()??'').isNotEmpty)Text(row['wallet_name'].toString(),style:TextStyle(fontSize:10,color:muted))]),
      const Spacer(),Row(children:[Expanded(child:Text(row['account_number']?.toString()??'',style:TextStyle(fontSize:22,fontWeight:FontWeight.w600,color:fg,letterSpacing:.6))),IconButton(tooltip:'Copy account number',onPressed:()async{await Clipboard.setData(ClipboardData(text:row['account_number']?.toString()??''));if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Account number copied')));},icon:Icon(PhosphorIcons.copy(),size:17,color:fg))]),
      Text(row['account_name']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:fg)),const SizedBox(height:3),Text(row['bank_name']?.toString()??'',style:TextStyle(fontSize:11,color:muted)),
    ]));
  }
}
class _Action extends StatelessWidget{const _Action({required this.label,required this.icon,required this.onTap});final String label;final IconData icon;final VoidCallback onTap;@override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(20),onTap:onTap,child:Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:WpccColors.line)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:20),const SizedBox(height:8),Text(label,textAlign:TextAlign.center,maxLines:2,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w500))])));}
class _ProjectCard extends StatelessWidget{const _ProjectCard({required this.row,required this.onTap});final Map<String,dynamic> row;final VoidCallback onTap;@override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(22),onTap:onTap,child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:WpccColors.line)),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:(row['image_url']?.toString()??'').isNotEmpty?Image.network(row['image_url'].toString(),width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_placeholder()):_placeholder()),Padding(padding:const EdgeInsets.all(11),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(row['title']?.toString()??'Project',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w500)),if(row['target_amount_kobo']!=null)...[const SizedBox(height:4),Text(NumberFormat.compactCurrency(locale:'en_NG',symbol:'₦').format((int.tryParse(row['target_amount_kobo'].toString())??0)/100),style:Theme.of(context).textTheme.labelSmall?.copyWith(color:WpccColors.muted))]]))])));Widget _placeholder()=>Container(color:const Color(0xFFF1F2F6),child:Center(child:Icon(PhosphorIcons.target(),size:28,color:WpccColors.muted)));}
