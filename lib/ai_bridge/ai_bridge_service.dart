import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import 'package:quantum_ide/ai_bridge/models/ai_bridge_models.dart';
import 'package:quantum_ide/models/project_model.dart';
import 'package:quantum_ide/core/services/project_service.dart';
import 'package:quantum_ide/core/services/runtime_service.dart';
import 'package:quantum_ide/core/services/workspace_service.dart';
import 'package:quantum_ide/core/utils/path_mapper.dart';

/// X-Core's local/ LAN AI control gateway.
///
/// This service is deliberately layered on top of the existing X-Core
/// ProjectService, WorkspaceService and terminal/build systems. It does not
/// replace the existing AI providers or project UI.
class AiBridgeService extends StateNotifier<AiBridgeSettings> {
  AiBridgeService(this._ref) : super(const AiBridgeSettings()) {
    _load();
  }

  final Ref _ref;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  HttpServer? _server;

  Future<void> _load() async {
    try {
      final enabled =
          await _secure.read(key: 'xcore_ai_bridge_enabled') == 'true';
      final lan =
          await _secure.read(key: 'xcore_ai_bridge_lan') == 'true';
      final key =
          await _secure.read(key: 'xcore_ai_bridge_key') ?? '';
      final port = int.tryParse(
            await _secure.read(key: 'xcore_ai_bridge_port') ?? '',
          ) ??
          8765;

      var permissions = AiBridgePermissionSetCodec.defaults;
      final raw =
          await _secure.read(key: 'xcore_ai_bridge_permissions');
      if (raw != null) {
        try {
          permissions = AiBridgePermissionSetCodec.decodeSet(jsonDecode(raw));
        } catch (_) {}
      }

      state = state.copyWith(
        enabled: enabled,
        lanMode: lan,
        apiKey: key,
        port: port,
        permissions: permissions,
      );

      if (enabled) {
        await start();
      }
    } catch (e) {
      debugPrint('[AI Bridge] load failed: $e');
    }
  }

  String _newKey() {
    final r = Random.secure();
    return 'xcore_' +
        List.generate(48, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  Future<void> _ensureKey() async {
    if (state.apiKey.isNotEmpty) return;
    final key = _newKey();
    await _secure.write(key: 'xcore_ai_bridge_key', value: key);
    state = state.copyWith(apiKey: key);
  }

  Future<void> regenerateKey() async {
    final key = _newKey();
    await _secure.write(key: 'xcore_ai_bridge_key', value: key);
    state = state.copyWith(apiKey: key);
  }

  Future<void> setEnabled(bool value) async {
    if (value) await _ensureKey();

    state = state.copyWith(enabled: value);
    await _secure.write(
      key: 'xcore_ai_bridge_enabled',
      value: value.toString(),
    );

    if (value) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> setLanMode(bool value) async {
    state = state.copyWith(lanMode: value);
    await _secure.write(
      key: 'xcore_ai_bridge_lan',
      value: value.toString(),
    );

    if (state.enabled) {
      await stop();
      await start();
    }
  }

  Future<void> setPort(int value) async {
    final port = value.clamp(1024, 65535);
    state = state.copyWith(port: port);
    await _secure.write(
      key: 'xcore_ai_bridge_port',
      value: port.toString(),
    );

    if (state.enabled) {
      await stop();
      await start();
    }
  }

  Future<void> setPermission(
    AiBridgePermission permission,
    bool allowed,
  ) async {
    final next = {...state.permissions};
    if (allowed) {
      next.add(permission);
    } else {
      next.remove(permission);
    }

    state = state.copyWith(permissions: next);
    await _secure.write(
      key: 'xcore_ai_bridge_permissions',
      value: jsonEncode(next.map((e) => e.name).toList()),
    );
  }

  Future<void> setFullAccess(bool enabled) async {
    final next = enabled
        ? AiBridgePermission.values.toSet()
        : AiBridgePermission.defaults;
    state = state.copyWith(permissions: next);
    await _secure.write(
      key: 'xcore_ai_bridge_permissions',
      value: jsonEncode(next.map((e) => e.name).toList()),
    );
  }

  String get localEndpoint =>
      'http://127.0.0.1:${state.port}/v1';

  String get localMcpEndpoint =>
      'http://127.0.0.1:${state.port}/mcp';

  String get lanEndpoint =>
      'http://<device-ip>:${state.port}/v1';

  String get lanMcpEndpoint =>
      'http://<device-ip>:${state.port}/mcp';

  String get endpoint => state.lanMode ? lanEndpoint : localEndpoint;

  String get mcpEndpoint =>
      state.lanMode ? lanMcpEndpoint : localMcpEndpoint;

  bool get fullAccess =>
      state.permissions.length == AiBridgePermission.values.length;

  Future<String?> getDeviceIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } catch (e) {
      debugPrint('[AI Bridge] network lookup failed: $e');
    }
    return null;
  }

  Future<String> resolvedEndpoint() async {
    if (!state.lanMode) return localEndpoint;
    final ip = await getDeviceIpv4();
    return ip == null
        ? lanEndpoint
        : 'http://$ip:${state.port}/v1';
  }

  Future<String> resolvedMcpEndpoint() async {
    if (!state.lanMode) return localMcpEndpoint;
    final ip = await getDeviceIpv4();
    return ip == null
        ? lanMcpEndpoint
        : 'http://$ip:${state.port}/mcp';
  }

  Future<bool> testConnection() async {
    await _ensureKey();
    final client = HttpClient();
    try {
      final base = await resolvedEndpoint();
      final request = await client.getUrl(Uri.parse('$base/health'));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${state.apiKey}',
      );
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AI Bridge] health check failed: $e');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> start() async {
    await stop();
    await _ensureKey();

    final address = state.lanMode
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;

    try {
      _server = await HttpServer.bind(
        address,
        state.port,
        shared: false,
      );
      _server!.listen(
        _handleRequest,
        onError: (e) => debugPrint('[AI Bridge] server error: $e'),
      );
      debugPrint(
        '[AI Bridge] listening on ${address.address}:${state.port}',
      );
    } catch (e) {
      state = state.copyWith(enabled: false);
      await _secure.write(
        key: 'xcore_ai_bridge_enabled',
        value: 'false',
      );
      debugPrint('[AI Bridge] bind failed: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest req) async {
    req.response.headers.contentType = ContentType.json;
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization',
    );
    req.response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );

    if (req.method == 'OPTIONS') {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }

    try {
      if (req.uri.path == '/health') {
        await _write(req, {
          'success': true,
          'service': 'X-Core AI Bridge',
          'version': '1.1.0',
          'enabled': state.enabled,
          'lan_mode': state.lanMode,
        });
        return;
      }

      final protectedPath =
          req.uri.path == '/mcp' ||
          req.uri.path.startsWith('/v1/');
      if (!protectedPath) {
        await _write(req, {'success': false, 'error': 'Not found'}, status: 404);
        return;
      }

      final auth = req.headers.value('authorization') ?? '';
      final supplied =
          auth.startsWith('Bearer ') ? auth.substring(7) : '';
      if (state.apiKey.isEmpty || supplied != state.apiKey) {
        await _write(
          req,
          {'success': false, 'error': 'Unauthorized'},
          status: 401,
        );
        return;
      }

      final rawBody = req.method == 'POST'
          ? await utf8.decoder.bind(req).join()
          : '{}';
      final decoded = rawBody.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rawBody);

      if (decoded is! Map) {
        await _write(
          req,
          {'success': false, 'error': 'JSON object expected'},
          status: 400,
        );
        return;
      }

      final input = decoded.cast<String, dynamic>();

      if (req.uri.path == '/mcp') {
        await _mcp(req, input);
        return;
      }

      if (req.uri.path == '/v1/tools' && req.method == 'GET') {
        await _write(req, {
          'success': true,
          'tools': _toolDefinitions(),
        });
        return;
      }

      if (req.method != 'POST') {
        await _write(
          req,
          {'success': false, 'error': 'Method not allowed'},
          status: 405,
        );
        return;
      }

      await _write(req, await _dispatch(req.uri.path, input));
    } catch (e, st) {
      debugPrint('[AI Bridge] request error: $e\n$st');
      await _write(
        req,
        {'success': false, 'error': e.toString()},
        status: 500,
      );
    }
  }

  List<Map<String, dynamic>> _toolDefinitions() => [
        _tool(
          'read_file',
          'Read a file from the active X-Core workspace.',
          {
            'path': {'type': 'string'},
          },
          ['path'],
        ),
        _tool(
          'write_file',
          'Replace the contents of an existing or new workspace file.',
          {
            'path': {'type': 'string'},
            'content': {'type': 'string'},
          },
          ['path', 'content'],
        ),
        _tool(
          'create_file',
          'Create a workspace file without overwriting by default.',
          {
            'path': {'type': 'string'},
            'content': {'type': 'string'},
            'overwrite': {'type': 'boolean'},
          },
          ['path'],
        ),
        _tool(
          'delete_file',
          'Delete a workspace file or directory.',
          {
            'path': {'type': 'string'},
          },
          ['path'],
        ),
        _tool(
          'rename_file',
          'Rename or move a workspace file.',
          {
            'path': {'type': 'string'},
            'new_path': {'type': 'string'},
          },
          ['path', 'new_path'],
        ),
        _tool(
          'list_files',
          'List a workspace directory.',
          {
            'path': {'type': 'string'},
          },
          [],
        ),
        _tool(
          'search_code',
          'Search text recursively through workspace files.',
          {
            'query': {'type': 'string'},
            'path': {'type': 'string'},
          },
          ['query'],
        ),
        _tool(
          'list_projects',
          'List projects known by X-Core.',
          {},
          [],
        ),
        _tool(
          'create_project',
          'Create a project through the existing X-Core ProjectService.',
          {
            'name': {'type': 'string'},
            'type': {'type': 'string'},
            'sdk_version': {'type': 'string'},
            'platforms': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          ['name'],
        ),
        _tool(
          'open_project',
          'Open an X-Core project as the active workspace.',
          {'id': {'type': 'string'}, 'name': {'type': 'string'}},
          [],
        ),
        _tool(
          'delete_project',
          'Remove a project from X-Core, optionally deleting its files.',
          {
            'id': {'type': 'string'},
            'delete_files': {'type': 'boolean'},
          },
          ['id'],
        ),
        _tool(
          'build_project',
          'Start a project build using X-Core build logic.',
          {
            'id': {'type': 'string'},
            'target': {'type': 'string'},
          },
          ['id'],
        ),
        _tool(
          'install_dependency',
          'Install a dependency using the project type package manager.',
          {
            'id': {'type': 'string'},
            'package': {'type': 'string'},
          },
          ['id', 'package'],
        ),
        _tool(
          'remove_dependency',
          'Remove a dependency using the project type package manager.',
          {
            'id': {'type': 'string'},
            'package': {'type': 'string'},
          },
          ['id', 'package'],
        ),
        _tool(
          'git_status',
          'Read Git status.',
          {'cwd': {'type': 'string'}},
          [],
        ),
        _tool(
          'git_diff',
          'Read Git diff.',
          {'cwd': {'type': 'string'}},
          [],
        ),
        _tool(
          'git_commit',
          'Create a Git commit.',
          {
            'cwd': {'type': 'string'},
            'message': {'type': 'string'},
          },
          ['message'],
        ),
        _tool(
          'git_pull',
          'Pull Git changes.',
          {'cwd': {'type': 'string'}},
          [],
        ),
        _tool(
          'git_push',
          'Push Git changes.',
          {'cwd': {'type': 'string'}},
          [],
        ),
        _tool(
          'run_command',
          'Run a shell command in the active project environment.',
          {
            'command': {'type': 'string'},
            'cwd': {'type': 'string'},
          },
          ['command'],
        ),
      ];

  Map<String, dynamic> _tool(
    String name,
    String description,
    Map<String, dynamic> properties,
    List<String> required,
  ) {
    return {
      'name': name,
      'description': description,
      'inputSchema': {
        'type': 'object',
        'properties': properties,
        'required': required,
      },
    };
  }

  Future<void> _mcp(
    HttpRequest req,
    Map<String, dynamic> input,
  ) async {
    final id = input['id'];
    final method = input['method'];

    if (method == 'notifications/initialized') {
      await _write(req, {
        'jsonrpc': '2.0',
        'id': id,
        'result': {},
      });
      return;
    }

    dynamic result;
    if (method == 'initialize') {
      result = {
        'protocolVersion': '2025-06-18',
        'capabilities': {'tools': {}},
        'serverInfo': {
          'name': 'X-Core AI Bridge',
          'version': '1.1.0',
        },
      };
    } else if (method == 'tools/list') {
      result = {'tools': _toolDefinitions()};
    } else if (method == 'tools/call') {
      final name = input['params']?['name'];
      final args =
          (input['params']?['arguments'] as Map?)?.cast<String, dynamic>() ??
              {};
      final path = _mcpToolPath(name);
      if (path.isEmpty) {
        result = {
          'content': [
            {'type': 'text', 'text': 'Unknown tool: $name'},
          ],
          'isError': true,
        };
      } else {
        final value = await _dispatch(path, args);
        result = {
          'content': [
            {'type': 'text', 'text': jsonEncode(value)},
          ],
          'isError': value['success'] == false,
        };
      }
    } else {
      result = {'error': 'Unsupported MCP method: $method'};
    }

    await _write(req, {
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });
  }

  String _mcpToolPath(String? name) => switch (name) {
        'read_file' => '/v1/files/read',
        'write_file' => '/v1/files/write',
        'create_file' => '/v1/files/create',
        'delete_file' => '/v1/files/delete',
        'rename_file' => '/v1/files/rename',
        'list_files' => '/v1/files/list',
        'search_code' => '/v1/code/search',
        'list_projects' => '/v1/project/list',
        'create_project' => '/v1/project/create',
        'open_project' => '/v1/project/open',
        'delete_project' => '/v1/project/delete',
        'build_project' => '/v1/build',
        'install_dependency' => '/v1/dependencies/install',
        'remove_dependency' => '/v1/dependencies/remove',
        'git_status' => '/v1/git/status',
        'git_diff' => '/v1/git/diff',
        'git_commit' => '/v1/git/commit',
        'git_pull' => '/v1/git/pull',
        'git_push' => '/v1/git/push',
        'run_command' => '/v1/terminal/run',
        _ => '',
      };

  Future<Map<String, dynamic>> _dispatch(
    String path,
    Map<String, dynamic> input,
  ) async {
    if (path == '/v1/session/connect') {
      return {
        'success': true,
        'session_id': 'xcore-local',
        'workspace': _workspacePathOrNull(),
        'permissions': state.permissions.map((e) => e.name).toList(),
      };
    }

    if (path == '/v1/project/list') {
      _require(AiBridgePermission.projectManagement);
      return {
        'success': true,
        'projects': _ref.read(projectServiceProvider).map((x) {
          return {
            'id': x.id,
            'name': x.name,
            'path': x.path,
            'type': x.type.name,
            'is_internal': x.isInternal,
          };
        }).toList(),
      };
    }

    if (path == '/v1/project/create') {
      _require(AiBridgePermission.projectManagement);
      final name = _required(input, 'name');
      final type = ProjectType.values.firstWhere(
        (x) => x.name == (input['type'] ?? 'flutter'),
        orElse: () => ProjectType.flutter,
      );

      final project = await _ref
          .read(projectServiceProvider.notifier)
          .createProject(
            name: name,
            path: '',
            type: type,
            sdkVersion: input['sdk_version'] as String?,
            platforms: (input['platforms'] as List?)?.cast<String>(),
          );

      await _ref.read(workspaceProvider.notifier).setWorkspace(project.path);

      return {
        'success': true,
        'project': {
          'id': project.id,
          'name': project.name,
          'path': project.path,
          'type': project.type.name,
        },
      };
    }

    if (path == '/v1/project/open') {
      _require(AiBridgePermission.projectManagement);
      final project = _findProject(input);
      await _ref.read(workspaceProvider.notifier).setWorkspace(project.path);
      return {
        'success': true,
        'project': {
          'id': project.id,
          'name': project.name,
          'path': project.path,
          'type': project.type.name,
        },
      };
    }

    if (path == '/v1/project/delete') {
      _require(AiBridgePermission.projectManagement);
      final id = _required(input, 'id');
      final removeFiles = input['delete_files'] == true;

      if (removeFiles && !state.permissions.contains(AiBridgePermission.deleteFiles)) {
        throw Exception(
          'Delete files permission is required when delete_files=true',
        );
      }

      await _ref
          .read(projectServiceProvider.notifier)
          .removeProject(id, deleteFiles: removeFiles);

      return {
        'success': true,
        'deleted': id,
        'files_deleted': removeFiles,
      };
    }

    if (path == '/v1/files/list') {
      _require(AiBridgePermission.readFiles);
      final dir = Directory(
        _safePath(input['path'] as String? ?? '.'),
      );
      if (!await dir.exists()) {
        return {'success': false, 'error': 'Directory not found'};
      }

      final list = <Map<String, dynamic>>[];
      await for (final e in dir.list(followLinks: false)) {
        list.add({
          'name': p.basename(e.path),
          'path': e.path,
          'type': e is Directory ? 'directory' : 'file',
        });
      }
      return {'success': true, 'entries': list};
    }

    if (path == '/v1/files/read') {
      _require(AiBridgePermission.readFiles);
      final file = File(_safePath(_required(input, 'path')));
      if (!await file.exists()) {
        return {'success': false, 'error': 'File not found'};
      }
      return {
        'success': true,
        'path': file.path,
        'content': await file.readAsString(),
      };
    }

    if (path == '/v1/files/create') {
      _require(AiBridgePermission.createFiles);
      final file = File(_safePath(_required(input, 'path')));
      if (await file.exists() && input['overwrite'] != true) {
        return {'success': false, 'error': 'File already exists'};
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(input['content'] as String? ?? '');
      return {'success': true, 'path': file.path};
    }

    if (path == '/v1/files/write') {
      _require(AiBridgePermission.writeFiles);
      final file = File(_safePath(_required(input, 'path')));
      await file.parent.create(recursive: true);
      await file.writeAsString(input['content'] as String? ?? '');
      return {'success': true, 'path': file.path};
    }

    if (path == '/v1/files/delete') {
      _require(AiBridgePermission.deleteFiles);
      final entity = FileSystemEntity.typeSync(
        _safePath(_required(input, 'path')),
      );
      final target = _safePath(_required(input, 'path'));
      if (entity == FileSystemEntityType.notFound) {
        return {'success': false, 'error': 'Path not found'};
      }
      if (entity == FileSystemEntityType.directory) {
        await Directory(target).delete(recursive: true);
      } else {
        await File(target).delete();
      }
      return {'success': true, 'path': target};
    }

    if (path == '/v1/files/rename') {
      _require(AiBridgePermission.writeFiles);
      final source = _safePath(_required(input, 'path'));
      final target = _safePath(_required(input, 'new_path'));
      if (!await FileSystemEntity.isFile(source) &&
          !await FileSystemEntity.isDirectory(source)) {
        return {'success': false, 'error': 'Source not found'};
      }
      final sourceType = await FileSystemEntity.type(source);
      if (sourceType == FileSystemEntityType.directory) {
        await Directory(source).rename(target);
      } else {
        await File(source).rename(target);
      }
      return {'success': true, 'path': target};
    }

    if (path == '/v1/code/search') {
      _require(AiBridgePermission.readFiles);
      final root = Directory(
        _safePath(input['path'] as String? ?? '.'),
      );
      final query = _required(input, 'query').toLowerCase();
      final matches = <Map<String, dynamic>>[];

      if (await root.exists()) {
        await for (final e in root.list(
          recursive: true,
          followLinks: false,
        )) {
          if (e is! File || matches.length >= 200) continue;
          try {
            final c = await e.readAsString();
            final lower = c.toLowerCase();
            var offset = 0;
            while (offset < lower.length && matches.length < 200) {
              final i = lower.indexOf(query, offset);
              if (i < 0) break;
              matches.add({
                'path': e.path,
                'line': '\n'.allMatches(c.substring(0, i)).length + 1,
              });
              offset = i + query.length;
            }
          } catch (_) {
            // Ignore binary/unreadable files.
          }
        }
      }

      return {'success': true, 'matches': matches};
    }

    if (path == '/v1/build') {
      _require(AiBridgePermission.build);
      final project = _findProject(input);
      _ref.read(projectServiceProvider.notifier).buildProject(
            project,
            target: input['target'] as String?,
          );
      return {
        'success': true,
        'status': 'started',
        'project': project.name,
        'target': input['target'] ?? 'default',
      };
    }

    if (path == '/v1/dependencies/install' ||
        path == '/v1/dependencies/remove') {
      _require(AiBridgePermission.dependencies);
      final project = _findProject(input);
      final package = _required(input, 'package');
      _validatePackageName(package);

      final command = _dependencyCommand(
        project.type,
        path == '/v1/dependencies/install',
        package,
      );
      final result = await _runInProjectShell(project.path, command);
      return {
        'success': result.exitCode == 0,
        'exit_code': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
        'package': package,
      };
    }

    if (path == '/v1/git/status') {
      return _git(['status', '--short'], input, requireWrite: false);
    }
    if (path == '/v1/git/diff') {
      return _git(['diff'], input, requireWrite: false);
    }
    if (path == '/v1/git/commit') {
      _require(AiBridgePermission.git);
      final message = _required(input, 'message');
      return _git(
        ['commit', '-am', message],
        input,
        requireWrite: true,
      );
    }
    if (path == '/v1/git/pull') {
      _require(AiBridgePermission.git);
      return _git(['pull'], input, requireWrite: true);
    }
    if (path == '/v1/git/push') {
      _require(AiBridgePermission.git);
      return _git(['push'], input, requireWrite: true);
    }

    if (path == '/v1/terminal/run') {
      _require(AiBridgePermission.terminal);
      final cwd = _safePath(
        input['cwd'] as String? ?? '.',
      );
      final command = _required(input, 'command');
      final result = await _runInProjectShell(cwd, command);
      return {
        'success': result.exitCode == 0,
        'exit_code': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
      };
    }

    throw Exception('Unknown endpoint: $path');
  }

  String _dependencyCommand(
    ProjectType type,
    bool install,
    String package,
  ) {
    switch (type) {
      case ProjectType.flutter:
      case ProjectType.dart:
        return install
            ? 'flutter pub add $package'
            : 'flutter pub remove $package';
      case ProjectType.nodejs:
        return install
            ? 'npm install $package'
            : 'npm uninstall $package';
      case ProjectType.python:
        return install
            ? 'python3 -m pip install $package'
            : 'python3 -m pip uninstall -y $package';
      case ProjectType.rust:
        return install
            ? 'cargo add $package'
            : 'cargo remove $package';
      case ProjectType.androidJava:
      case ProjectType.androidKotlin:
        return install
            ? './gradlew dependencies'
            : './gradlew dependencies';
      default:
        return install
            ? 'echo "No package manager configured for this project type"'
            : 'echo "No package manager configured for this project type"';
    }
  }

  void _validatePackageName(String package) {
    final valid = RegExp(r'^[A-Za-z0-9_@./:+-]+$');
    if (!valid.hasMatch(package) || package.contains('..')) {
      throw Exception('Invalid dependency/package name');
    }
  }

  Future<_CommandResult> _runInProjectShell(
    String cwd,
    String command,
  ) async {
    try {
      final runtime = _ref.read(runtimeServiceProvider);
      final guestCwd = PathMapper.mapToGuest(cwd, runtime.appDirectory);

      final String shell;
      final List<String> args;
      final String workingDirectory;
      if (Platform.isAndroid) {
        shell = '/system/bin/sh';
        args = [
          runtime.prootCommand,
          runtime.appDirectory,
          guestCwd,
          command,
        ];
        workingDirectory = runtime.appDirectory;
      } else if (Platform.isWindows) {
        shell = 'cmd.exe';
        args = ['/c', command];
        workingDirectory = cwd;
      } else {
        shell = Platform.environment['SHELL'] ?? '/bin/sh';
        args = ['-lc', command];
        workingDirectory = cwd;
      }

      final result = await Process.run(
        shell,
        args,
        workingDirectory: workingDirectory,
        environment: Platform.isAndroid ? runtime.env : null,
        runInShell: false,
      );
      return _CommandResult(
        result.exitCode,
        result.stdout.toString(),
        result.stderr.toString(),
      );
    } catch (e) {
      return _CommandResult(1, '', e.toString());
    }
  }

  Future<Map<String, dynamic>> _git(
    List<String> args,
    Map<String, dynamic> input, {
    required bool requireWrite,
  }) async {
    if (requireWrite) {
      _require(AiBridgePermission.git);
    } else {
      _require(AiBridgePermission.readFiles);
    }

    final cwd = _safePath(input['cwd'] as String? ?? '.');
    final result = await Process.run(
      'git',
      args,
      workingDirectory: cwd,
    );

    return {
      'success': result.exitCode == 0,
      'exit_code': result.exitCode,
      'stdout': result.stdout.toString(),
      'stderr': result.stderr.toString(),
    };
  }

  Project _findProject(Map<String, dynamic> input) {
    final id = input['id'] as String?;
    final name = input['name'] as String?;

    return _ref.read(projectServiceProvider).firstWhere(
          (x) =>
              (id != null && x.id == id) ||
              (name != null && x.name == name),
          orElse: () => throw Exception('Project not found'),
        );
  }

  String _workspacePath() {
    final path = _ref.read(workspaceProvider).currentPath;
    if (path == null || path.isEmpty) {
      throw Exception('No active X-Core workspace');
    }
    return path;
  }

  String? _workspacePathOrNull() =>
      _ref.read(workspaceProvider).currentPath;

  String _safePath(String raw) {
    final root = p.normalize(_workspacePath());
    final value = p.normalize(raw);
    final absolute =
        value.startsWith('/') ? value : p.join(root, value);
    final normalized = p.normalize(absolute);
    final relative = p.relative(normalized, from: root);

    if (relative == '..' ||
        relative.startsWith('..' + p.separator) ||
        !p.isWithin(root, normalized)) {
      throw Exception('Path is outside the active workspace');
    }

    return normalized;
  }

  void _require(AiBridgePermission permission) {
    if (!state.permissions.contains(permission)) {
      throw Exception('Permission denied: ${permission.label}');
    }
  }

  String _required(Map<String, dynamic> input, String key) {
    final value = input[key];
    if (value is! String || value.trim().isEmpty) {
      throw Exception('Missing required field: $key');
    }
    return value.trim();
  }

  Future<void> _write(
    HttpRequest req,
    Map<String, dynamic> value, {
    int status = 200,
  }) async {
    req.response.statusCode = status;
    req.response.write(jsonEncode(value));
    await req.response.close();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }
}

class _CommandResult {
  const _CommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

final aiBridgeProvider =
    StateNotifierProvider<AiBridgeService, AiBridgeSettings>(
  (ref) => AiBridgeService(ref),
);
