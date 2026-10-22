import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'project.dart';
import 'store.dart';
import 'widgets.dart';

Future<void> openProjectUrl(BuildContext context,String value) async {
  final url=safeProjectUrl(value); if(url.isEmpty)return;
  try { await const MethodChannel('realhero/actions').invokeMethod('openUrl',{'url':url}); }
  catch (_) { if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Не удалось открыть ссылку. Её можно скопировать.'))); }
}
class ProjectSourceCard extends StatelessWidget {
  final ProjectSource source;
  final bool saved;
  final VoidCallback onSave;
  const ProjectSourceCard({super.key,required this.source,required this.saved,required this.onSave});
  @override Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:ink.withValues(alpha:.6),borderRadius:BorderRadius.circular(14),border:Border.all(color:teal.withValues(alpha:.2))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(source.imageUrl.isNotEmpty) ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(source.imageUrl,height:170,width:double.infinity,fit:BoxFit.cover,
        errorBuilder:(_,e,stack)=>const SizedBox(height:60,child:Center(child:Text('Изображение доступно на странице источника',style:TextStyle(color:muted,fontSize:12))))),),
      const SizedBox(height:8),Text(source.title,style:const TextStyle(fontWeight:FontWeight.w600)),
      Text(Uri.tryParse(source.url)?.host??source.url,style:const TextStyle(color:muted,fontSize:12)),
      Wrap(spacing:8,children:[TextButton(onPressed:()=>openProjectUrl(context,source.url),child:const Text('Открыть источник')),
        TextButton.icon(onPressed:saved?null:onSave,icon:Icon(saved?Icons.bookmark:Icons.bookmark_add_outlined,size:16),label:Text(saved?'Сохранено':'В проект')),
        IconButton(tooltip:'Скопировать ссылку',onPressed:()=>Clipboard.setData(ClipboardData(text:source.url)),icon:const Icon(Icons.copy,size:16))]),
    ]));
}

class ProjectView extends StatelessWidget {
  final RealHeroStore store;
  final VoidCallback onChat,onRoadmap,onNewProject;
  final VoidCallback? onAction,onMission;
  const ProjectView({super.key,required this.store,required this.onChat,required this.onRoadmap,required this.onNewProject,this.onAction,this.onMission});
  Future<void> edit(BuildContext context,{ProjectItem? item,ProjectStage? stage,String kind='note'}) async {
    var title=item?.title??stage?.title??'';
    var text=item?.text??stage?.detail??'';
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(sheet)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(sheet).bottom+24),
      child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(stage!=null?'Изменить этап':kind=='decision'?'Решение проекта':'Материал проекта',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),TextFormField(initialValue:title,decoration:const InputDecoration(labelText:'Название'),onChanged:(v)=>title=v),
        const SizedBox(height:12),TextFormField(initialValue:text,minLines:3,maxLines:8,decoration:const InputDecoration(labelText:'Текст'),onChanged:(v)=>text=v),
        const SizedBox(height:16),ActionButton('Сохранить',onPressed:(){
          if(title.trim().isEmpty)return;
          if(stage!=null) {store.editStage(stage,title.trim(),text.trim());}
          else if(item!=null) {store.editProjectItem(item,title.trim(),text.trim());}
          else {store.addProjectItem(title.trim(),text.trim(),kind:kind);}
          Navigator.pop(sheet);
        }),
      ]))));
  }
  @override Widget build(BuildContext context) {
    final p=store.project;
    final count=p.roadmap.where((x)=>x.done).length;
    return ListView(padding:const EdgeInsets.fromLTRB(20,24,20,30),children:[
      Row(children:[const Expanded(child:Text('Твой проект',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold))),
        PopupMenuButton<String>(tooltip:'Проекты',onSelected:(id){if(id=='new'){onNewProject();}else{store.switchProject(store.state.goals.firstWhere((g)=>g.id==id));}},itemBuilder:(_)=>[
          for(final goal in store.state.goals.where((g)=>!g.id.startsWith('demo'))) PopupMenuItem(value:goal.id,child:Text(goal.title,maxLines:2,overflow:TextOverflow.ellipsis)),
          const PopupMenuItem(value:'new',child:Text('Новый проект')),
        ],icon:const Icon(Icons.folder_copy_outlined,color:teal))]),
      const SizedBox(height:18),Text(store.goal?.title??'',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w700)),
      const SizedBox(height:14),ActionButton('Обсудить с Леей',onPressed:onChat,icon:Icons.chat_bubble_outline),
      if(onAction!=null) TextButton(onPressed:onAction,child:const Text('Подготовить реальное действие')),
      if(store.currentMission!=null && !store.currentMission!.isClosed && onMission!=null)
        ExpansionTile(title:const Text('Ранее подготовленная миссия',style:TextStyle(color:muted,fontSize:13)),children:[
          ListTile(title:Text(store.currentMission!.title),trailing:const Icon(Icons.chevron_right),onTap:onMission)]),
      if(p.summary.isNotEmpty)...[const SizedBox(height:16),GlassPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Замысел · черновик Леи',style:TextStyle(color:muted,fontSize:12)),const SizedBox(height:6),SelectableText(p.summary)]))],
      const SizedBox(height:24),Row(children:[const Expanded(child:Text('Дорожная карта',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),
        IconButton(tooltip:'Добавить этап',onPressed:()async{
          var title=''; await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(sheet)=>Padding(padding:EdgeInsets.fromLTRB(20,24,20,MediaQuery.viewInsetsOf(sheet).bottom+24),child:Column(mainAxisSize:MainAxisSize.min,children:[
            TextField(decoration:const InputDecoration(labelText:'Новый этап'),onChanged:(v)=>title=v),const SizedBox(height:16),ActionButton('Добавить',onPressed:(){if(title.trim().isEmpty)return;store.addStage(title.trim(),'');Navigator.pop(sheet);})])));
        },icon:const Icon(Icons.add,color:teal))]),
      if(p.roadmap.isEmpty) ...[const Text('Собери этапы с Леей или добавь свой. Отмечай изменения по мере работы.',style:TextStyle(color:muted)),
        TextButton(onPressed:onRoadmap,child:const Text('Подготовить карту с Леей'))]
      else ...[Text('$count из ${p.roadmap.length} этапов отмечено тобой',style:const TextStyle(color:muted,fontSize:12)),
        for(final stage in p.roadmap) Card(color:panel,child:ListTile(
          leading:Checkbox(value:stage.done,onChanged:(_)=>store.toggleStage(stage)),
          title:Text(stage.title,style:TextStyle(decoration:stage.done?TextDecoration.lineThrough:null)),
          subtitle:stage.detail.isEmpty?null:Text(stage.detail),
          trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit'){edit(context,stage:stage);}else{store.removeStage(stage);}},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Изменить')),PopupMenuItem(value:'delete',child:Text('Убрать этап'))]),
        )),TextButton(onPressed:onRoadmap,child:const Text('Обсудить изменения карты'))],
      if(p.proposedRoadmap.isNotEmpty)...[const SizedBox(height:14),GlassPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Предложение Леи',style:TextStyle(color:teal,fontWeight:FontWeight.bold)),
        for(final stage in p.proposedRoadmap) Padding(padding:const EdgeInsets.only(top:10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(stage.title,style:const TextStyle(fontWeight:FontWeight.w600)),if(stage.detail.isNotEmpty)Text(stage.detail,style:const TextStyle(color:muted,fontSize:13))])),
        const SizedBox(height:12),ActionButton(p.roadmap.isEmpty?'Принять карту':'Заменить карту этим вариантом',onPressed:store.acceptRoadmap),
        TextButton(onPressed:store.dismissRoadmap,child:const Text('Оставить текущую карту')),
      ]))],
      const SizedBox(height:24),const Text('Материалы и решения',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      Wrap(spacing:8,children:[TextButton.icon(onPressed:()=>edit(context),icon:const Icon(Icons.add,size:18),label:const Text('Заметка')),
        TextButton.icon(onPressed:()=>edit(context,kind:'decision'),icon:const Icon(Icons.check_circle_outline,size:18),label:const Text('Решение'))]),
      if(p.items.isEmpty) const Text('Сохраняй сюда примеры из чата, черновики и свои решения.',style:TextStyle(color:muted)),
      for(final item in p.items.reversed) Padding(padding:const EdgeInsets.only(top:10),child:GlassPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text(item.kind=='decision'?'Принятое решение':item.kind=='draft'?'Черновик':item.kind=='reference'?'Сохранённый пример':'Заметка',style:const TextStyle(color:teal,fontSize:12))),
          PopupMenuButton<String>(onSelected:(v){if(v=='edit'){edit(context,item:item);}else{store.removeProjectItem(item);}},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Изменить')),PopupMenuItem(value:'delete',child:Text('Удалить материал'))])]),
        if(item.source!=null) ProjectSourceCard(source:item.source!,saved:true,onSave:(){})
        else ...[Text(item.title,style:const TextStyle(fontWeight:FontWeight.w700)),if(item.text.isNotEmpty)...[const SizedBox(height:8),SelectableText(item.text)]],
      ]))),
    ]);
  }
}
