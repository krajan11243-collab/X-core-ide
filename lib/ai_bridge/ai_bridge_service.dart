import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:quantum_ide/ai_bridge/models/ai_bridge_models.dart';
import 'package:quantum_ide/core/services/project_service.dart';
import 'package:quantum_ide/core/services/workspace_service.dart';

class AiBridgeService extends StateNotifier<AiBridgeSettings> {
  AiBridgeService(this._ref) : super(const AiBridgeSettings()) { _load(); }
  final Ref _ref;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  HttpServer? _server;

  Future<void> _load() async {
    try {
      final enabled = await _secure.read(key:'xcore_ai_bridge_enabled') == 'true';
      final lan = await _secure.read(key:'xcore_ai_bridge_lan') == 'true';
      final key = await _secure.read(key:'xcore_ai_bridge_key') ?? '';
      final port = int.tryParse(await _secure.read(key:'xcore_ai_bridge_port') ?? '') ?? 8765;
      var permissions = const <AiBridgePermission>{
        AiBridgePermission.readFiles, AiBridgePermission.writeFiles,
        AiBridgePermission.createFiles, AiBridgePermission.projectManagement,
        AiBridgePermission.build,
      };
      final raw = await _secure.read(key:'xcore_ai_bridge_permissions');
      if (raw != null) {
        try {
          permissions = (jsonDecode(raw) as List).map((v) {
            for (final p in AiBridgePermission.values) { if (p.name == v) return p; }
            return null;
          }).whereType<AiBridgePermission>().toSet();
        } catch (_) {}
      }
      state = state.copyWith(enabled:enabled,lanMode:lan,apiKey:key,port:port,permissions:permissions);
      if (enabled) await start();
    } catch (e) { debugPrint('[AI Bridge] load: $e'); }
  }

  String _newKey() {
    final r = Random.secure();
    return 'xcore_' + List.generate(40, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  Future<void> _ensureKey() async {
    if (state.apiKey.isNotEmpty) return;
    final key = _newKey();
    await _secure.write(key:'xcore_ai_bridge_key',value:key);
    state = state.copyWith(apiKey:key);
  }

  Future<void> regenerateKey() async {
    final key = _newKey();
    await _secure.write(key:'xcore_ai_bridge_key',value:key);
    state = state.copyWith(apiKey:key);
  }

  Future<void> setEnabled(bool value) async {
    if (value) await _ensureKey();
    state = state.copyWith(enabled:value);
    await _secure.write(key:'xcore_ai_bridge_enabled',value:value.toString());
    if (value) { await start(); } else { await stop(); }
  }

  Future<void> setLanMode(bool value) async {
    state = state.copyWith(lanMode:value);
    await _secure.write(key:'xcore_ai_bridge_lan',value:value.toString());
    if (state.enabled) { await stop(); await start(); }
  }

  Future<void> setPort(int value) async {
    final port=value.clamp(1024,65535);
    state=state.copyWith(port:port);
    await _secure.write(key:'xcore_ai_bridge_port',value:port.toString());
    if (state.enabled) { await stop(); await start(); }
  }

  Future<void> setPermission(AiBridgePermission permission,bool allowed) async {
    final next={...state.permissions};
    if(allowed){next.add(permission);}else{next.remove(permission);}
    state=state.copyWith(permissions:next);
    await _secure.write(key:'xcore_ai_bridge_permissions',value:jsonEncode(next.map((e)=>e.name).toList()));
  }

  String get localEndpoint => 'http://127.0.0.1:' + state.port.toString() + '/v1';
  String get lanEndpoint => 'http://<device-ip>:' + state.port.toString() + '/v1';
  String get endpoint => state.lanMode ? lanEndpoint : localEndpoint;
  String get mcpEndpoint => endpoint.replaceFirst('/v1','/mcp');

  Future<void> start() async {
    await stop();
    await _ensureKey();
    final address=state.lanMode?InternetAddress.anyIPv4:InternetAddress.loopbackIPv4;
    try {
      _server=await HttpServer.bind(address,state.port,shared:true);
      _server!.listen(_handleRequest,onError:(e)=>debugPrint('[AI Bridge] server: $e'));
    } catch(e) {
      state=state.copyWith(enabled:false);
      await _secure.write(key:'xcore_ai_bridge_enabled',value:'false');
      debugPrint('[AI Bridge] bind failed: $e');
    }
  }

  Future<void> stop() async { await _server?.close(force:true); _server=null; }

  Future<void> _handleRequest(HttpRequest req) async {
    req.response.headers.contentType=ContentType.json;
    req.response.headers.set('Access-Control-Allow-Origin','*');
    req.response.headers.set('Access-Control-Allow-Headers','Content-Type, Authorization');
    req.response.headers.set('Access-Control-Allow-Methods','GET, POST, OPTIONS');
    if(req.method=='OPTIONS'){req.response.statusCode=204;await req.response.close();return;}
    try {
      if(req.uri.path=='/health'){await _write(req,{'ok':true,'service':'X-Core AI Bridge','version':'1.0'});return;}
      if(req.uri.path!='/mcp' && !req.uri.path.startsWith('/v1/')){await _write(req,{'error':'Not found'},status:404);return;}
      final auth=req.headers.value('authorization')??'';
      final supplied=auth.startsWith('Bearer ')?auth.substring(7):'';
      if(supplied!=state.apiKey){await _write(req,{'error':'Unauthorized'},status:401);return;}
      final body=(req.method=='POST')?await utf8.decoder.bind(req).join():'{}';
      final input=body.trim().isEmpty?<String,dynamic>{}:jsonDecode(body) as Map<String,dynamic>;
      if(req.uri.path=='/mcp'){await _mcp(req,input);return;}
      if(req.uri.path=='/v1/tools' && req.method=='GET'){await _write(req,{'tools':_toolDefinitions()});return;}
      if(req.method!='POST'){await _write(req,{'error':'Method not allowed'},status:405);return;}
      await _write(req,await _dispatch(req.uri.path,input));
    } catch(e,st) {
      debugPrint('[AI Bridge] request error: $e\n$st');
      await _write(req,{'success':false,'error':e.toString()},status:500);
    }
  }

  List<Map<String,dynamic>> _toolDefinitions()=>[
    {'name':'read_file','description':'Read a project file','inputSchema':{'type':'object','properties':{'path':{'type':'string'}},'required':['path']}},
    {'name':'write_file','description':'Write or replace a project file','inputSchema':{'type':'object','properties':{'path':{'type':'string'},'content':{'type':'string'}},'required':['path','content']}},
    {'name':'create_file','description':'Create a project file','inputSchema':{'type':'object','properties':{'path':{'type':'string'},'content':{'type':'string'}},'required':['path']}},
    {'name':'delete_file','description':'Delete a project file','inputSchema':{'type':'object','properties':{'path':{'type':'string'}},'required':['path']}},
    {'name':'search_code','description':'Search text through the active project','inputSchema':{'type':'object','properties':{'query':{'type':'string'},'path':{'type':'string'}},'required':['query']}},
    {'name':'list_projects','description':'List X-Core projects','inputSchema':{'type':'object'}},
    {'name':'create_project','description':'Create a project using X-Core ProjectService','inputSchema':{'type':'object','properties':{'name':{'type':'string'},'type':{'type':'string'}},'required':['name']}},
    {'name':'delete_project','description':'Delete an X-Core project','inputSchema':{'type':'object','properties':{'id':{'type':'string'},'delete_files':{'type':'boolean'}},'required':['id']}},
    {'name':'build_project','description':'Start an X-Core project build','inputSchema':{'type':'object','properties':{'id':{'type':'string'},'target':{'type':'string'}},'required':['id']}},
    {'name':'git_status','description':'Read Git status','inputSchema':{'type':'object','properties':{'cwd':{'type':'string'}}}},
    {'name':'git_diff','description':'Read Git diff summary','inputSchema':{'type':'object','properties':{'cwd':{'type':'string'}}}},
    {'name':'run_command','description':'Run a shell command in the active project','inputSchema':{'type':'object','properties':{'command':{'type':'string'},'cwd':{'type':'string'}},'required':['command']}},
  ];

  Future<void> _mcp(HttpRequest req,Map<String,dynamic> input) async {
    final id=input['id'];
    final method=input['method'];
    dynamic result;
    if(method=='initialize'){
      result={'protocolVersion':'2025-06-18','capabilities':{'tools':{}},'serverInfo':{'name':'X-Core AI Bridge','version':'1.0'}};
    } else if(method=='notifications/initialized'){
      result={};
    } else if(method=='tools/list'){
      result={'tools':_toolDefinitions()};
    } else if(method=='tools/call'){
      final name=input['params']?['name'];
      final args=(input['params']?['arguments'] as Map?)?.cast<String,dynamic>()??{};
      final path=_mcpToolPath(name);
      final value=await _dispatch(path,args);
      result={'content':[{'type':'text','text':jsonEncode(value)}],'isError':value['success']==false};
    } else {
      result={'error':'Unsupported MCP method'};
    }
    await _write(req,{'jsonrpc':'2.0','id':id,'result':result});
  }

  String _mcpToolPath(String? name)=>switch(name){
    'read_file'=>'/v1/files/read',
    'write_file'=>'/v1/files/write',
    'create_file'=>'/v1/files/create',
    'delete_file'=>'/v1/files/delete',
    'search_code'=>'/v1/code/search',
    'list_projects'=>'/v1/project/list',
    'create_project'=>'/v1/project/create',
    'delete_project'=>'/v1/project/delete',
    'build_project'=>'/v1/build',
    'git_status'=>'/v1/git/status',
    'git_diff'=>'/v1/git/diff',
    'run_command'=>'/v1/terminal/run',
    _=>'',
  };

  Future<Map<String,dynamic>> _dispatch(String path,Map<String,dynamic> input) async {
    if(path=='/v1/session/connect') return {'success':true,'session_id':'xcore-local','workspace':_workspacePathOrNull()};
    if(path=='/v1/project/list'){
      _require(AiBridgePermission.projectManagement);
      return {'success':true,'projects':_ref.read(projectServiceProvider).map((x)=>{'id':x.id,'name':x.name,'path':x.path,'type':x.type.name}).toList()};
    }
    if(path=='/v1/project/create'){
      _require(AiBridgePermission.projectManagement);
      final name=_required(input,'name');
      final type=ProjectType.values.firstWhere((x)=>x.name==(input['type']??'flutter'),orElse:()=>ProjectType.flutter);
      final project=await _ref.read(projectServiceProvider.notifier).createProject(name:name,path:'',type:type,sdkVersion:input['sdk_version'] as String?,platforms:(input['platforms'] as List?)?.cast<String>());
      return {'success':true,'project':{'id':project.id,'name':project.name,'path':project.path,'type':project.type.name}};
    }
    if(path=='/v1/project/delete'){
      _require(AiBridgePermission.projectManagement);
      final id=_required(input,'id');
      final removeFiles=input['delete_files']==true;
      await _ref.read(projectServiceProvider.notifier).removeProject(id,deleteFiles:removeFiles);
      return {'success':true,'deleted':id,'files_deleted':removeFiles};
    }
    if(path=='/v1/files/list'){
      _require(AiBridgePermission.readFiles);
      final dir=Directory(_safePath(input['path'] as String? ?? _workspacePath()));
      if(!await dir.exists()) return {'success':false,'error':'Directory not found'};
      final list=<Map<String,dynamic>>[];
      await for(final e in dir.list(followLinks:false)){list.add({'name':p.basename(e.path),'path':e.path,'type':e is Directory?'directory':'file'});}
      return {'success':true,'entries':list};
    }
    if(path=='/v1/files/read'){
      _require(AiBridgePermission.readFiles);
      final file=File(_safePath(_required(input,'path')));
      if(!await file.exists()) return {'success':false,'error':'File not found'};
      return {'success':true,'path':file.path,'content':await file.readAsString()};
    }
    if(path=='/v1/files/create'){
      _require(AiBridgePermission.createFiles);
      final file=File(_safePath(_required(input,'path')));
      if(await file.exists() && input['overwrite']!=true) return {'success':false,'error':'File already exists'};
      await file.parent.create(recursive:true); await file.writeAsString(input['content'] as String???'');
      return {'success':true,'path':file.path};
    }
    if(path=='/v1/files/write'){
      _require(AiBridgePermission.writeFiles);
      final file=File(_safePath(_required(input,'path')));
      await file.parent.create(recursive:true); await file.writeAsString(input['content'] as String???'');
      return {'success':true,'path':file.path};
    }
    if(path=='/v1/files/delete'){
      _require(AiBridgePermission.deleteFiles);
      final file=File(_safePath(_required(input,'path')));
      if(!await file.exists()) return {'success':false,'error':'File not found'};
      await file.delete(recursive:true); return {'success':true,'path':file.path};
    }
    if(path=='/v1/files/rename'){
      _require(AiBridgePermission.writeFiles);
      final source=File(_safePath(_required(input,'path')));
      final target=_safePath(_required(input,'new_path'));
      if(!await source.exists()) return {'success':false,'error':'Source not found'};
      await source.rename(target); return {'success':true,'path':target};
    }
    if(path=='/v1/code/search'){
      _require(AiBridgePermission.readFiles);
      final root=Directory(_safePath(input['path'] as String???_workspacePath()));
      final query=_required(input,'query').toLowerCase(); final matches=<Map<String,dynamic>>[];
      if(await root.exists()){await for(final e in root.list(recursive:true,followLinks:false)){if(e is File && matches.length<100){try{final c=await e.readAsString();final i=c.toLowerCase().indexOf(query);if(i>=0)matches.add({'path':e.path,'line':'\n'.allMatches(c.substring(0,i)).length+1});}catch(_){}}}}
      return {'success':true,'matches':matches};
    }
    if(path=='/v1/build'){
      _require(AiBridgePermission.build);
      final project=_findProject(input); _ref.read(projectServiceProvider.notifier).buildProject(project,target:input['target'] as String?);
      return {'success':true,'status':'started','project':project.name};
    }
    if(path=='/v1/git/status') return _git(['status','--short'],input);
    if(path=='/v1/git/diff') return _git(['diff','--stat'],input);
    if(path=='/v1/terminal/run'){
      _require(AiBridgePermission.terminal);
      final cwd=_safePath(input['cwd'] as String???_workspacePath());
      final r=await Process.run('/system/bin/sh',['-c',_required(input,'command')],workingDirectory:cwd);
      return {'success':r.exitCode==0,'exit_code':r.exitCode,'stdout':r.stdout.toString(),'stderr':r.stderr.toString()};
    }
    throw Exception('Unknown endpoint: $path');
  }

  Future<Map<String,dynamic>> _git(List<String> args,Map<String,dynamic> input) async {
    _require(AiBridgePermission.git);
    final cwd=_safePath(input['cwd'] as String???_workspacePath());
    final r=await Process.run('git',args,workingDirectory:cwd);
    return {'success':r.exitCode==0,'exit_code':r.exitCode,'stdout':r.stdout.toString(),'stderr':r.stderr.toString()};
  }

  Project _findProject(Map<String,dynamic> input){
    final id=input['id'] as String?; final name=input['name'] as String?;
    return _ref.read(projectServiceProvider).firstWhere((x)=>(id!=null&&x.id==id)||(name!=null&&x.name==name),orElse:()=>throw Exception('Project not found'));
  }

  String _workspacePath()=>_ref.read(workspaceProvider).currentPath??(throw Exception('No active X-Core workspace'));
  String? _workspacePathOrNull()=>_ref.read(workspaceProvider).currentPath;

  String _safePath(String raw){
    final root=_workspacePath(); final value=p.normalize(raw);
    final absolute=value.startsWith('/')?value:p.join(root,value);
    final normalized=p.normalize(absolute);
    final relative=p.relative(normalized,from:root);
    if(relative=='..'||relative.startsWith('..'+p.separator)||p.isWithin(root,normalized)==false) throw Exception('Path is outside active workspace');
    return normalized;
  }

  void _require(AiBridgePermission permission){if(!state.permissions.contains(permission))throw Exception('Permission denied: '+permission.label);}
  String _required(Map<String,dynamic> input,String key){final v=input[key];if(v is! String||v.trim().isEmpty)throw Exception('Missing required field: '+key);return v;}

  Future<void> _write(HttpRequest req,Map<String,dynamic> value,{int status=200}) async {req.response.statusCode=status;req.response.write(jsonEncode(value));await req.response.close();}

  @override void dispose(){_server?.close(force:true);super.dispose();}
}

final aiBridgeProvider=StateNotifierProvider<AiBridgeService,AiBridgeSettings>((ref)=>AiBridgeService(ref));
