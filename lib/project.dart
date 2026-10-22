import 'domain.dart';

class ProjectSource {
  final String url, title, imageUrl;
  ProjectSource({required this.url, required this.title, this.imageUrl = ''});
  factory ProjectSource.fromJson(dynamic value) {
    final j = jsonObject(value);
    return ProjectSource(url: safeProjectUrl(jsonString(j['url'])), title: jsonString(j['title']), imageUrl: safeProjectUrl(jsonString(j['imageUrl'])));
  }
  Map<String, dynamic> toJson() => {'url': url, 'title': title, 'imageUrl': imageUrl};
}
String safeProjectUrl(String value) {
  final u = Uri.tryParse(value);
  if (u == null || u.scheme != 'https' || u.userInfo.isNotEmpty || !u.host.contains('.') ||
      u.host == 'localhost' || u.host.endsWith('.local') || u.host.contains(':') ||
      (u.hasPort && u.port != 443) || RegExp(r'^(127|10|0|169\.254|192\.168|172\.(1[6-9]|2\d|3[01]))\.').hasMatch(u.host)) return '';
  return u.toString();
}
class ProjectStage {
  final String id;
  String title, detail;
  bool done;
  ProjectStage({String? id, required this.title, this.detail = '', this.done = false}) : id = id == null || id.isEmpty ? newId('stage') : id;
  factory ProjectStage.fromJson(dynamic v) { final j=jsonObject(v); return ProjectStage(id:jsonString(j['id']),title:jsonString(j['title']),detail:jsonString(j['detail']),done:j['done']==true); }
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'detail':detail,'done':done};
}
class ProjectItem {
  final String id, kind;
  String title, text;
  final ProjectSource? source;
  final bool userAuthored;
  ProjectItem({String? id, required this.title, this.text='', this.kind='note', this.source, this.userAuthored=true}) : id=id ?? newId('item');
  factory ProjectItem.fromJson(dynamic v) { final j=jsonObject(v); return ProjectItem(id:jsonString(j['id']),title:jsonString(j['title']),text:jsonString(j['text']),kind:jsonString(j['kind'],'note'),source:j['source']==null?null:ProjectSource.fromJson(j['source']),userAuthored:j['userAuthored']==true); }
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'text':text,'kind':kind,'source':source?.toJson(),'userAuthored':userAuthored};
}
class ProjectWorkspace {
  final String goalId;
  String summary;
  final List<ProjectStage> roadmap, proposedRoadmap;
  final List<ProjectItem> items;
  ProjectWorkspace({required this.goalId,this.summary='',List<ProjectStage>? roadmap,List<ProjectStage>? proposedRoadmap,List<ProjectItem>? items}):roadmap=roadmap??[],proposedRoadmap=proposedRoadmap??[],items=items??[];
  factory ProjectWorkspace.fromJson(dynamic v) { final j=jsonObject(v); return ProjectWorkspace(goalId:jsonString(j['goalId']),summary:jsonString(j['summary']),roadmap:jsonList(j['roadmap']).map(ProjectStage.fromJson).toList(),proposedRoadmap:jsonList(j['proposedRoadmap']).map(ProjectStage.fromJson).toList(),items:jsonList(j['items']).map(ProjectItem.fromJson).toList()); }
  Map<String,dynamic> toJson()=>{'goalId':goalId,'summary':summary,'roadmap':roadmap.map((x)=>x.toJson()).toList(),'proposedRoadmap':proposedRoadmap.map((x)=>x.toJson()).toList(),'items':items.map((x)=>x.toJson()).toList()};
}
