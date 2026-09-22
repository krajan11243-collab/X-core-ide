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
  static const pink = Color(0xFFFF20D9);
  static const purple = Color(0xFF9B35FF);
  static const blue = Color(0xFF405CFF);
  static const cyan = Color(0xFF00CFFF);
  static const bg = Color(0xFF05060D);
  static const panel = Color(0xFF0B0E18);
  static const field = Color(0xFF0D111D);
  static const muted = Color(0xFF9298AB);

  late final TextEditingController nameCtrl;
  late final TextEditingController sdkCtrl;
  late ProjectType type;
  late List<String> platforms;
  int? colorValue;
  int? iconCodePoint;
  String? iconFontFamily;
  String? iconFontPackage;
  bool busy = false;
  String? error;

  final colors = const [
    Color(0xFFE57373), Color(0xFFF06292), Color(0xFFBA68C8),
    Color(0xFF9575CD), Color(0xFF7986CB), Color(0xFF64B5F6),
    Color(0xFF4FC3F7), Color(0xFF4DD0E1), Color(0xFF4DB6AC),
    Color(0xFF81C784), Color(0xFFAED581), Color(0xFFD4E157), Color(0xFFFFD54F),
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
    sdkCtrl = TextEditingController(
      text: p?.sdkVersion ?? (type == ProjectType.flutter ? '34' : 'com.example.app'),
    );
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
          sdkVersion: (type == ProjectType.flutter ||
                  type == ProjectType.androidJava ||
                  type == ProjectType.androidKotlin)
              ? sdkCtrl.text.trim()
              : null,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: bg,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _projectName(),
                    const SizedBox(height: 20),
                    _section(LucideIcons.layout_grid, 'PROJECT TYPE', 'Choose your technology'),
                    const SizedBox(height: 10),
                    _typeGrid(),
                    if (type == ProjectType.flutter) ...[
                      const SizedBox(height: 20),
                      _section(LucideIcons.cpu, 'ANDROID COMPILE SDK VERSION', 'Android build setting'),
                      const SizedBox(height: 10),
                      _sdkField(),
                      const SizedBox(height: 20),
                      _section(LucideIcons.monitor, 'TARGET DEVICES / PLATFORMS', 'Select target platforms'),
                      const SizedBox(height: 10),
                      _platformGrid(),
                    ],
                    if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) ...[
                      const SizedBox(height: 20),
                      _section(LucideIcons.code, 'PACKAGE NAME (APPLICATION ID)', 'Android package'),
                      const SizedBox(height: 10),
                      _inputField('Package Name', 'com.example.myapp', LucideIcons.code),
                    ],
                    const SizedBox(height: 20),
                    _section(LucideIcons.palette, 'ACCENT COLOR', 'Choose theme color'),
                    const SizedBox(height: 10),
                    _colorRow(),
                    const SizedBox(height: 20),
                    _section(LucideIcons.image, 'PROJECT ICON', 'Choose app icon'),
                    const SizedBox(height: 10),
                    _iconRow(),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      _errorBox(),
                    ],
                    const SizedBox(height: 24),
                    _createButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Create ', style: GoogleFonts.inter(
                  fontSize: 31, fontWeight: FontWeight.w900, color: Colors.white,
                )),
                TextSpan(text: 'Project', style: GoogleFonts.inter(
                  fontSize: 31, fontWeight: FontWeight.w900, color: pink,
                )),
              ])),
              const SizedBox(height: 2),
              Text('Start building something amazing',
                style: GoogleFonts.inter(color: muted, fontSize: 13.5)),
            ],
          ),
        ),
        _closeButton(),
      ],
    ),
  );

  Widget _closeButton() => InkWell(
    onTap: () => Navigator.pop(context),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: const Icon(LucideIcons.x, color: Colors.white, size: 28),
    ),
  );

  Widget _projectName() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cyan.withValues(alpha: .13)),
      boxShadow: [BoxShadow(color: purple.withValues(alpha: .07), blurRadius: 18)],
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: purple.withValues(alpha: .30)),
        ),
        child: const Icon(LucideIcons.box, color: Color(0xFFB873FF), size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(child: TextField(
        controller: nameCtrl,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: 'Project Name',
          labelStyle: GoogleFonts.inter(color: muted, fontSize: 12),
          hintText: 'Project Name',
          hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: .55)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
      )),
    ]),
  );

  Widget _inputField(String label, String hint, IconData icon, {bool number = false}) => TextField(
    controller: sdkCtrl,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: muted, fontSize: 12),
      hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: .55)),
      prefixIcon: Icon(icon, color: pink, size: 23),
      filled: true,
      fillColor: field,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: pink, width: 1.5)),
    ),
  );

  Widget _sdkField() => _inputField('Compile SDK', '34', LucideIcons.cpu, number: true);

  Widget _section(IconData icon, String title, String hint) => Row(
    children: [
      Icon(icon, color: purple, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900))),
      const SizedBox(width: 7),
      Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: purple)),
        const SizedBox(width: 5),
        Flexible(child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: muted, fontSize: 9.5))),
      ])),
    ],
  );

  Widget _typeGrid() => LayoutBuilder(builder: (context, constraints) {
    final count = constraints.maxWidth >= 600 ? 4 : 2;
    const gap = 9.0;
    final width = (constraints.maxWidth - gap * (count - 1)) / count;
    final items = <Map<String, dynamic>>[
      {'name':'FLUTTER','type':ProjectType.flutter,'icon':LucideIcons.layers,'color':cyan},
      {'name':'PYTHON','type':ProjectType.python,'icon':LucideIcons.braces,'color':Color(0xFFFFC107)},
      {'name':'NODEJS','type':ProjectType.nodejs,'icon':LucideIcons.box,'color':Color(0xFF45D483)},
      {'name':'WEB','type':ProjectType.web,'icon':LucideIcons.globe,'color':Color(0xFF4F7CFF)},
      {'name':'ANDROID JAVA','type':ProjectType.androidJava,'icon':Icons.android,'color':Color(0xFF00E676)},
      {'name':'ANDROID KOTLIN','type':ProjectType.androidKotlin,'icon':Icons.code,'color':Color(0xFF8B5CF6)},
      {'name':'RUST','type':ProjectType.rust,'icon':LucideIcons.settings_2,'color':Color(0xFFFF7043)},
    ];
    return Wrap(
      spacing: gap, runSpacing: 9,
      children: items.map((item) {
        final selected = type == item['type'];
        final color = item['color'] as Color;
        return SizedBox(
          width: width, height: 58,
          child: InkWell(
            onTap: () => setState(() {
              type = item['type'] as ProjectType;
              if (type == ProjectType.flutter) sdkCtrl.text = '34';
              if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) sdkCtrl.text = 'com.example.app';
            }),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .11) : panel,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: selected ? color : Colors.white.withValues(alpha: .09), width: selected ? 1.6 : 1),
                boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: .13), blurRadius: 15)] : null,
              ),
              child: Row(children: [
                Icon(item['icon'] as IconData, color: selected ? color : Colors.white70, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(item['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: selected ? Colors.white : Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w900))),
                if (selected) Icon(LucideIcons.circle_check, color: color, size: 16),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  });

  Widget _platformGrid() => LayoutBuilder(builder: (context, constraints) {
    const gap = 9.0;
    final width = (constraints.maxWidth - gap * 2) / 3;
    return Wrap(
      spacing: gap, runSpacing: gap,
      children: ['android','ios','web','windows','macos','linux'].map((p) {
        final selected = platforms.contains(p);
        return SizedBox(
          width: width, height: 52,
          child: InkWell(
            onTap: () => setState(() {
              if (!selected) platforms.add(p);
              else if (platforms.length > 1) platforms.remove(p);
            }),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? pink.withValues(alpha: .10) : panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? pink : Colors.white.withValues(alpha: .09), width: selected ? 1.6 : 1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(p == 'android' ? Icons.android : LucideIcons.globe, color: selected ? pink : Colors.white70, size: 19),
                const SizedBox(width: 6),
                Text(p.toUpperCase(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  });

  Widget _colorRow() => SizedBox(
    height: 58,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: colors.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) => _colorChoice(i == 0 ? null : colors[i - 1]),
    ),
  );

  Widget _colorChoice(Color? c) {
    final selected = c == null ? colorValue == null : colorValue == c.toARGB32();
    return InkWell(
      onTap: () => setState(() => colorValue = c?.toARGB32()),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c ?? panel,
          border: Border.all(color: selected ? pink : Colors.white.withValues(alpha: .10), width: selected ? 2.5 : 1),
          boxShadow: selected ? [BoxShadow(color: (c ?? pink).withValues(alpha: .22), blurRadius: 14)] : null,
        ),
        child: c == null ? Icon(LucideIcons.ban, color: selected ? pink : Colors.white70, size: 20)
          : selected ? const Icon(LucideIcons.check, color: Colors.white, size: 19) : null,
      ),
    );
  }

  Widget _iconRow() => SizedBox(
    height: 58,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: icons.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
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
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: selected ? pink.withValues(alpha: .07) : panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? pink : Colors.white.withValues(alpha: .10), width: selected ? 2 : 1),
              boxShadow: selected ? [BoxShadow(color: pink.withValues(alpha: .15), blurRadius: 13)] : null,
            ),
            child: Icon(icon, color: selected ? pink : Colors.white70, size: 24),
          ),
        );
      },
    ),
  );

  Widget _errorBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.redAccent.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.redAccent.withValues(alpha: .28)),
    ),
    child: Text(error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11)),
  );

  Widget _createButton() => SizedBox(
    width: double.infinity, height: 60,
    child: ElevatedButton(
      onPressed: busy ? null : save,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [pink, purple, blue]),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [BoxShadow(color: pink.withValues(alpha: .22), blurRadius: 24)],
        ),
        child: Center(
          child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(LucideIcons.sparkles, size: 21),
                const SizedBox(width: 10),
                Text(widget.project == null ? 'Create Project' : 'Save Changes',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 9),
                const Icon(LucideIcons.arrow_right, size: 21),
              ]),
        ),
      ),
    ),
  );
}
