import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_ide/ai_bridge/ai_bridge_service.dart';
import 'package:quantum_ide/ai_bridge/models/ai_bridge_models.dart';

class AiBridgePage extends ConsumerStatefulWidget {
  const AiBridgePage({super.key});
  @override ConsumerState<AiBridgePage> createState() => _AiBridgePageState();
}

class _AiBridgePageState extends ConsumerState<AiBridgePage> {
  bool _showKey = false;
  bool _testing = false;
  String? _endpoint;
  String? _mcp;

  Future<void> _refresh(AiBridgeService s) async {
    final e = await s.resolvedEndpoint();
    final m = await s.resolvedMcpEndpoint();
    if (!mounted) return;
    setState(() { _endpoint = e; _mcp = m; });
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(aiBridgeProvider);
    final service = ref.read(aiBridgeProvider.notifier);
    final theme = Theme.of(context);
    if (_endpoint == null && state.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(service));
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrow_left), onPressed: () => context.pop()),
        title: Text('AI Bridge', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
        _card(context, 'Bridge Status', LucideIcons.brainCircuit, Column(children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(state.enabled ? LucideIcons.circleCheck : LucideIcons.circleOff, color: state.enabled ? Colors.greenAccent : theme.colorScheme.outline),
            title: Text(state.enabled ? 'Bridge Running' : 'Bridge Disabled', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            subtitle: Text(state.enabled ? 'Ready for MCP and REST connections.' : 'Turn it on to expose the X-Core API.'),
            trailing: Switch(value: state.enabled, onChanged: service.setEnabled)),
        ])),
        const SizedBox(height: 16),
        _card(context, 'Connection', LucideIcons.wifi, Column(children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('LAN Access'), subtitle: const Text('Allow another device on the same network to connect.'), value: state.lanMode, onChanged: (v) async { await service.setLanMode(v); await _refresh(service); }),
          const Divider(height: 1),
          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.hash, color: theme.colorScheme.primary), title: const Text('Port'), subtitle: Text(state.port.toString()), trailing: const Icon(LucideIcons.chevronRight, size: 17), onTap: () => _editPort(context, state.port, service)),
        ])),
        const SizedBox(height: 16),
        _card(context, 'API & MCP', LucideIcons.plugZap, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(context, 'API Endpoint', _endpoint ?? service.endpoint, () => _copy(context, _endpoint ?? service.endpoint)),
          const SizedBox(height: 12),
          _field(context, 'MCP Endpoint', _mcp ?? service.mcpEndpoint, () => _copy(context, _mcp ?? service.mcpEndpoint)),
          const SizedBox(height: 12),
          _field(context, 'API Key', state.apiKey.isEmpty ? 'Enable Bridge to generate key' : (_showKey ? state.apiKey : '••••••••••••••••••'), state.apiKey.isEmpty ? null : () => _copy(context, state.apiKey), trailing: state.apiKey.isEmpty ? null : IconButton(icon: Icon(_showKey ? LucideIcons.eyeOff : LucideIcons.eye, size: 18), onPressed: () => setState(() => _showKey = !_showKey))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: state.apiKey.isEmpty ? null : () => _copy(context, state.apiKey), icon: const Icon(LucideIcons.copy, size: 16), label: const Text('Copy Key'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () async { await service.regenerateKey(); if (mounted) setState(() => _showKey = true); }, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('Regenerate')))]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: !state.enabled || _testing ? null : () async { setState(() => _testing = true); final ok = await service.testConnection(); if (mounted) { setState(() => _testing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Bridge connection successful' : 'Bridge connection failed'))); } }, icon: _testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.activity, size: 16), label: Text(_testing ? 'Testing...' : 'Test Connection'))),
          const SizedBox(height: 8),
          Text('The API key controls access. External AI clients must support MCP, tools, or custom API connections.', style: GoogleFonts.inter(fontSize: 11, height: 1.45, color: theme.colorScheme.onSurfaceVariant)),
        ])),
        const SizedBox(height: 16),
        _card(context, 'Project Access', LucideIcons.shieldCheck, Column(children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Full Project Access', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Enable every Bridge permission.'), value: service.fullAccess, onChanged: service.setFullAccess),
          const Divider(height: 1),
          ...AiBridgePermission.values.map((p) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(p.label), value: state.permissions.contains(p), onChanged: (v) => service.setPermission(p, v))),
        ])),
        const SizedBox(height: 16),
        _card(context, 'Available Controls', LucideIcons.toolbox, Column(children: const [
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Projects: create, open, delete')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Files: list, read, create, write, delete, rename')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Code: recursive search and edits')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Dependencies: install/remove')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Build: start project builds')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Git: status, diff, commit, pull, push')),
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(LucideIcons.check, size: 17), title: Text('Terminal: execute project commands')),
        ])),
      ]),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, Widget child) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: .06))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 19, color: theme.colorScheme.primary), const SizedBox(width: 9), Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800))]), const SizedBox(height: 14), child]));
  }

  Widget _field(BuildContext context, String label, String value, VoidCallback? copy, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: theme.colorScheme.primary)), const SizedBox(height: 6), Container(padding: const EdgeInsets.only(left: 12, right: 4), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.jetBrainsMono(fontSize: 11))), if (copy != null) IconButton(icon: const Icon(LucideIcons.copy, size: 17), onPressed: copy), if (trailing != null) trailing]))]);
  }

  Future<void> _editPort(BuildContext context, int current, AiBridgeService service) async {
    final c = TextEditingController(text: current.toString());
    final value = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(title: const Text('Bridge Port'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port (1024-65535)')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final n = int.tryParse(c.text.trim()); if (n != null && n >= 1024 && n <= 65535) Navigator.pop(ctx, n); }, child: const Text('Save'))]));
    c.dispose();
    if (value != null) { await service.setPort(value); if (mounted) await _refresh(service); }
  }

  Future<void> _copy(BuildContext context, String value) async { await Clipboard.setData(ClipboardData(text: value)); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'))); }
}