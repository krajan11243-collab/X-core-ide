import 'dart:convert';

enum AiBridgePermission {
  readFiles, writeFiles, createFiles, deleteFiles, projectManagement,
  dependencies, terminal, build, git,
}

extension AiBridgePermissionLabel on AiBridgePermission {
  String get label => switch (this) {
    AiBridgePermission.readFiles => 'Read files',
    AiBridgePermission.writeFiles => 'Write files',
    AiBridgePermission.createFiles => 'Create files',
    AiBridgePermission.deleteFiles => 'Delete files',
    AiBridgePermission.projectManagement => 'Project management',
    AiBridgePermission.dependencies => 'Dependencies',
    AiBridgePermission.terminal => 'Terminal',
    AiBridgePermission.build => 'Build',
    AiBridgePermission.git => 'Git',
  };
}

class AiBridgeSettings {
  final bool enabled;
  final bool lanMode;
  final String apiKey;
  final int port;
  final Set<AiBridgePermission> permissions;
  const AiBridgeSettings({
    this.enabled=false, this.lanMode=false, this.apiKey='', this.port=8765,
    this.permissions=const {
      AiBridgePermission.readFiles, AiBridgePermission.writeFiles,
      AiBridgePermission.createFiles, AiBridgePermission.projectManagement,
      AiBridgePermission.build,
    },
  });
  AiBridgeSettings copyWith({bool? enabled,bool? lanMode,String? apiKey,int? port,Set<AiBridgePermission>? permissions}) =>
    AiBridgeSettings(enabled:enabled??this.enabled,lanMode:lanMode??this.lanMode,apiKey:apiKey??this.apiKey,port:port??this.port,permissions:permissions??this.permissions);
  Map<String,dynamic> toJson()=>{'enabled':enabled,'lanMode':lanMode,'apiKey':apiKey,'port':port,'permissions':permissions.map((e)=>e.name).toList()};
  factory AiBridgeSettings.fromJson(Map<String,dynamic> j){
    final raw=(j['permissions'] as List?)?.cast<String>()??[];
    final set=raw.map((x){for(final p in AiBridgePermission.values){if(p.name==x)return p;}return null;}).whereType<AiBridgePermission>().toSet();
    return AiBridgeSettings(enabled:j['enabled']==true,lanMode:j['lanMode']==true,apiKey:j['apiKey'] as String???'',port:(j['port'] as num?)?.toInt()??8765,permissions:set.isEmpty?const {AiBridgePermission.readFiles,AiBridgePermission.writeFiles,AiBridgePermission.createFiles,AiBridgePermission.projectManagement,AiBridgePermission.build}:set);
  }
  String encode()=>jsonEncode(toJson());
}