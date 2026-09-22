
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_ide/models/project_model.dart';
import 'package:quantum_ide/core/services/project_service.dart';

class XCoreProjectWizard extends ConsumerStatefulWidget {
  const XCoreProjectWizard({super.key, this.project});
  final Project? project;

  @override
  ConsumerState<XCoreProjectWizard> createState() => _XCoreProjectWizardState();
}

class _XCoreProjectWizardState extends ConsumerState<XCoreProjectWizard> {
  late TextEditingController nameCtrl;
  late TextEditingController sdkCtrl;
  late ProjectType type;
  late List<String> platforms;
  int? colorValue;
  int? iconCodePoint;
  String? iconFontFamily;
  String? iconFontPackage;
  bool busy = false;
  String? error;

  final colors = const [
    Color(0xFFE57373), Color(0xFFF06292), Color(0xFFBA68C8), Color(0xFF9575CD),
    Color(0xFF7986CB), Color(0xFF64B5F6), Color(0xFF4FC3F7), Color(0xFF4DD0E1),
    Color(0xFF4DB6AC), Color(0xFF81C784), Color(0xFFAED581), Color(0xFFD4E157), Color(0xFFFFD54F),
  ];

  final icons = const [
    LucideIcons.folder, LucideIcons.folder_open, LucideIcons.folder_code,
    LucideIcons.folder_search, LucideIcons.folder_heart, LucideIcons.folder_git,
    LucideIcons.smartphone, LucideIcons.code, LucideIcons.terminal,
    LucideIcons.globe, LucideIcons.server, LucideIcons.database,
    LucideIcons.cpu, LucideIcons.palette, LucideIcons.layers, LucideIcons.puzzle,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    nameCtrl = TextEditingController(text: p?.name ?? '');
    type = p?.type ?? ProjectType.flutter;
    sdkCtrl = TextEditingController(text: p?.sdkVersion ?? (type == ProjectType.flutter ? '34' : 'com.example.app'));
    platforms = [...(p?.platforms ?? const ['android'])];
    colorValue = p?.colorValue;
    iconCodePoint = p?.iconCodePoint;
    iconFontFamily = p?.iconFontFamily;
    iconFontPackage = p?.iconFontPackage;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    sdkCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (nameCtrl.text.trim().isEmpty) {
      setState(() => error = 'Project name is required');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final p = widget.project;
      if (p == null) {
        await ref.read(projectServiceProvider.notifier).createProject(
          name: nameCtrl.text.trim(),
          path: '',
          type: type,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
          iconFontFamily: iconFontFamily,
          iconFontPackage: iconFontPackage,
          platforms: type == ProjectType.flutter ? platforms : null,
          sdkVersion: (type == ProjectType.flutter || type == ProjectType.androidJava || type == ProjectType.androidKotlin) ? sdkCtrl.text.trim() : null,
        );
      } else {
        await ref.read(projectServiceProvider.notifier).saveProject(Project(
          id: p.id,
          name: nameCtrl.text.trim(),
          path: p.path,
          type: type,
          lastOpened: p.lastOpened,
          isInternal: p.isInternal,
          colorValue: colorValue,
          iconCodePoint: iconCodePoint,
          iconFontFamily: iconFontFamily,
          iconFontPackage: iconFontPackage,
          platforms: platforms,
          sdkVersion: sdkCtrl.text.trim(),
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { busy = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: accent.withValues(alpha: .18)),
        ),
        child: SafeArea(
          top: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 3),
              child: Row(children: [
                Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Create ', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                  TextSpan(text: 'Project', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: accent)),
                ]))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 28)),
              ]),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Start building something amazing', style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _field(theme, 'Project Name', 'Project Name', nameCtrl, LucideIcons.box),
                  const SizedBox(height: 20),
                  _section(theme, 'PROJECT TYPE', 'Choose your technology'),
                  const SizedBox(height: 10),
                  _typeGrid(theme),
                  if (type == ProjectType.flutter) ...[
                    const SizedBox(height: 20),
                    _section(theme, 'ANDROID COMPILE SDK VERSION', 'Android build setting'),
                    const SizedBox(height: 10),
                    _field(theme, 'Compile SDK', '34', sdkCtrl, LucideIcons.cpu, number: true),
                    const SizedBox(height: 20),
                    _section(theme, 'TARGET DEVICES / PLATFORMS', 'Select target platforms'),
                    const SizedBox(height: 10),
                    _platformGrid(theme),
                  ],
                  if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) ...[
                    const SizedBox(height: 20),
                    _section(theme, 'PACKAGE NAME (APPLICATION ID)', 'Android package'),
                    const SizedBox(height: 10),
                    _field(theme, 'Package Name', 'com.example.myapp', sdkCtrl, LucideIcons.code_2),
                  ],
                  const SizedBox(height: 20),
                  _section(theme, 'ACCENT COLOR', 'Choose theme color'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (_, i) => _color(theme, i == 0 ? null : colors[i - 1]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(theme, 'PROJECT ICON', 'Choose app icon'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (_, i) {
                        final icon = i == 0 ? LucideIcons.ban : icons[i - 1];
                        final selected = i == 0 ? iconCodePoint == null : iconCodePoint == icon.codePoint;
                        return InkWell(
                          onTap: () => setState(() {
                            if (i == 0) {
                              iconCodePoint = null;
                              iconFontFamily = null;
                              iconFontPackage = null;
                            } else {
                              iconCodePoint = icon.codePoint;
                              iconFontFamily = icon.fontFamily;
                              iconFontPackage = icon.fontPackage;
                            }
                          }),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: selected ? accent.withValues(alpha: .1) : theme.colorScheme.onSurface.withValues(alpha: .035),
                              border: Border.all(color: selected ? accent : theme.colorScheme.onSurface.withValues(alpha: .1), width: selected ? 2 : 1),
                            ),
                            child: Icon(icon, color: selected ? accent : theme.colorScheme.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: .09), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withValues(alpha: .3))),
                      child: Text(error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11)),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: busy ? null : save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(LucideIcons.sparkles, size: 20),
                              const SizedBox(width: 10),
                              Text(widget.project == null ? 'Create Project' : 'Save Changes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrow_right, size: 20),
                            ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(ThemeData theme, String label, String hint, TextEditingController controller, IconData icon, {bool number = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .5)),
          filled: true,
          fillColor: theme.colorScheme.onSurface.withValues(alpha: .045),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: .08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: .08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ],
  );

  Widget _section(ThemeData theme, String title, String hint) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
      Row(children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA855F7))),
        const SizedBox(width: 6),
        Text(hint, style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    ],
  );

  Widget _typeGrid(ThemeData theme) {
    final items = <Map<String, dynamic>>[
      {'name':'FLUTTER','type':ProjectType.flutter,'icon':LucideIcons.layers,'color':const Color(0xFF00B8FF)},
      {'name':'PYTHON','type':ProjectType.python,'icon':LucideIcons.braces,'color':const Color(0xFFFFC107)},
      {'name':'NODEJS','type':ProjectType.nodejs,'icon':LucideIcons.box,'color':const Color(0xFF45D483)},
      {'name':'WEB','type':ProjectType.web,'icon':LucideIcons.globe,'color':const Color(0xFF4F7CFF)},
      {'name':'ANDROID JAVA','type':ProjectType.androidJava,'icon':Icons.android,'color':const Color(0xFF00E676)},
      {'name':'ANDROID KOTLIN','type':ProjectType.androidKotlin,'icon':Icons.code,'color':const Color(0xFF8B5CF6)},
      {'name':'RUST','type':ProjectType.rust,'icon':LucideIcons.settings_2,'color':const Color(0xFFFF7043)},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((x) {
        final selected = type == x['type'];
        final width = (MediaQuery.of(context).size.width - 48) / 2;
        return SizedBox(
          width: width,
          child: InkWell(
            onTap: () => setState(() {
              type = x['type'] as ProjectType;
              if (type == ProjectType.flutter) sdkCtrl.text = '34';
              if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) sdkCtrl.text = 'com.example.app';
            }),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: selected ? (x['color'] as Color).withValues(alpha: .13) : theme.colorScheme.onSurface.withValues(alpha: .035),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: selected ? x['color'] as Color : theme.colorScheme.onSurface.withValues(alpha: .08), width: selected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(x['icon'] as IconData, color: selected ? x['color'] as Color : theme.colorScheme.onSurfaceVariant, size: 22),
                const SizedBox(width: 7),
                Expanded(child: Text(x['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant))),
                if (selected) Icon(LucideIcons.circle_check, color: x['color'] as Color, size: 16),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _platformGrid(ThemeData theme) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: ['android','ios','web','windows','macos','linux'].map((p) {
      final selected = platforms.contains(p);
      return FilterChip(
        selected: selected,
        onSelected: (v) => setState(() {
          if (v && !platforms.contains(p)) platforms.add(p);
          if (!v && platforms.length > 1) platforms.remove(p);
        }),
        label: Text(p.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800)),
        avatar: Icon(p == 'android' ? Icons.android : LucideIcons.globe, size: 16),
        selectedColor: theme.colorScheme.primary.withValues(alpha: .18),
        checkmarkColor: theme.colorScheme.primary,
        side: BorderSide(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: .1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }).toList(),
  );

  Widget _color(ThemeData theme, Color? c) {
    final selected = c == null ? colorValue == null : colorValue == c.toARGB32();
    return InkWell(
      onTap: () => setState(() => colorValue = c?.toARGB32()),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c ?? theme.colorScheme.onSurface.withValues(alpha: .05),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: .1), width: selected ? 2.5 : 1),
          boxShadow: selected && c != null ? [BoxShadow(color: c.withValues(alpha: .3), blurRadius: 12)] : null,
        ),
        child: c == null
            ? Icon(LucideIcons.ban, size: 18, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
            : selected ? const Icon(LucideIcons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}
