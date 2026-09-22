import 'dart:math' as math;
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
  static const bg = Color(0xFF02030A);
  static const panel = Color(0xFF090C16);
  static const field = Color(0xFF0B0E18);
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
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _WizardBackdropPainter()))),
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Create ', style: GoogleFonts.inter(
                  fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white,
                )),
                TextSpan(text: 'Project', style: GoogleFonts.inter(
                  fontSize: 31, fontWeight: FontWeight.w900, color: pink,
                )),
              ])),
              const SizedBox(height: 2),
              Text('Start building something amazing',
                style: GoogleFonts.inter(color: muted, fontSize: 14)),
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
      width: 68, height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: const Icon(LucideIcons.x, color: Colors.white, size: 31),
    ),
  );

  Widget _projectName() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cyan.withValues(alpha: .18)),
      boxShadow: [BoxShadow(color: purple.withValues(alpha: .07), blurRadius: 18)],
    ),
    child: Row(children: [
      Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: purple.withValues(alpha: .30)),
        ),
        child: const Icon(LucideIcons.box, color: Color(0xFFB873FF), size: 29),
      ),
      const SizedBox(width: 15),
      Expanded(child: TextField(
        controller: nameCtrl,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
      Container(
        width: 31, height: 31,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: purple.withValues(alpha: .28)),
        ),
        child: Icon(icon, color: purple, size: 18),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12.8, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(width: 7),
      Flexible(
        flex: 0,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: purple)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 155),
            child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: muted, fontSize: 8.8, fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    ],
  );

  Widget _typeGrid() => LayoutBuilder(builder: (context, constraints) {
    const gap = 9.0;
    final count = constraints.maxWidth >= 560 ? 4 : 2;
    final width = (constraints.maxWidth - gap * (count - 1)) / count;
    final items = <Map<String, dynamic>>[
      {'name':'FLUTTER','type':ProjectType.flutter,'icon':LucideIcons.layers,'color':cyan},
      {'name':'PYTHON','type':ProjectType.python,'icon':LucideIcons.braces,'color':const Color(0xFFFFC107)},
      {'name':'NODEJS','type':ProjectType.nodejs,'icon':LucideIcons.box,'color':const Color(0xFF45D483)},
      {'name':'WEB','type':ProjectType.web,'icon':LucideIcons.globe,'color':const Color(0xFF4F7CFF)},
      {'name':'ANDROID JAVA','type':ProjectType.androidJava,'icon':Icons.android,'color':const Color(0xFF00E676)},
      {'name':'ANDROID KOTLIN','type':ProjectType.androidKotlin,'icon':Icons.code_rounded,'color':const Color(0xFF8B5CF6)},
      {'name':'RUST','type':ProjectType.rust,'icon':LucideIcons.sliders_horizontal,'color':const Color(0xFFFF7043)},
    ];
    return Wrap(
      spacing: gap, runSpacing: gap,
      children: items.map((item) {
        final selected = type == item['type'];
        final color = item['color'] as Color;
        return SizedBox(
          width: width, height: 70,
          child: InkWell(
            onTap: () => setState(() {
              type = item['type'] as ProjectType;
              if (type == ProjectType.flutter) sdkCtrl.text = '34';
              if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) {
                sdkCtrl.text = 'com.example.app';
              }
            }),
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .12) : panel,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected ? color : Colors.white.withValues(alpha: .095),
                  width: selected ? 1.7 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: color.withValues(alpha: .18), blurRadius: 17, spreadRadius: -3)]
                    : null,
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? .12 : .055),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'] as IconData,
                    color: selected ? color : Colors.white70, size: 22),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(item['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 10.5, fontWeight: FontWeight.w900,
                      letterSpacing: .1,
                    )),
                ),
                if (selected)
                  Container(
                    width: 19, height: 19,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.4)),
                    child: Icon(LucideIcons.check, color: color, size: 12),
                  ),
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
    final data = <Map<String, dynamic>>[
      {'name':'ANDROID','key':'android','icon':Icons.android},
      {'name':'IOS','key':'ios','icon':Icons.phone_iphone},
      {'name':'WEB','key':'web','icon':LucideIcons.globe},
      {'name':'WINDOWS','key':'windows','icon':Icons.window},
      {'name':'MACOS','key':'macos','icon':Icons.desktop_mac},
      {'name':'LINUX','key':'linux','icon':Icons.terminal},
    ];
    return Wrap(
      spacing: gap, runSpacing: gap,
      children: data.map((item) {
        final key = item['key'] as String;
        final selected = platforms.contains(key);
        return SizedBox(
          width: width, height: 62,
          child: InkWell(
            onTap: () => setState(() {
              if (!selected) {
                platforms.add(key);
              } else if (platforms.length > 1) {
                platforms.remove(key);
              }
            }),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: selected ? pink.withValues(alpha: .105) : panel,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? pink : Colors.white.withValues(alpha: .095),
                  width: selected ? 1.7 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: pink.withValues(alpha: .15), blurRadius: 16, spreadRadius: -4)]
                    : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(item['icon'] as IconData,
                  color: selected ? pink : Colors.white70, size: 20),
                const SizedBox(width: 7),
                Text(item['name'] as String,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 10, fontWeight: FontWeight.w900)),
                if (selected) ...[
                  const SizedBox(width: 5),
                  Icon(LucideIcons.check, color: pink, size: 13),
                ],
              ]),
            ),
          ),
        );
      }).toList(),
    );
  });

  Widget _colorRow() => SizedBox(
    height: 72,
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
    height: 72,
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
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: selected ? pink.withValues(alpha: .075) : panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? pink : Colors.white.withValues(alpha: .10),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: pink.withValues(alpha: .18), blurRadius: 16, spreadRadius: -3)]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: selected ? pink : Colors.white70, size: 25),
                if (selected)
                  Positioned(
                    right: 5, top: 5,
                    child: Container(
                      width: 15, height: 15,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: pink),
                      child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
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
    width: double.infinity, height: 68,
    child: ElevatedButton(
      onPressed: busy ? null : save,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 9),
                const Icon(LucideIcons.arrow_right, size: 21),
              ]),
        ),
      ),
    ),
  );
}


class _WizardBackdropPainter extends CustomPainter {
  const _WizardBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .80, size.height * .10);
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x553B00FF), Color(0x001A0038)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .42));
    canvas.drawCircle(center, size.width * .42, glow);
    final horizon = size.height * .91;
    final planet = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [Color(0xAA3210FF), Color(0x003000FF)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .50, horizon),
        radius: size.width * .72,
      ));
    canvas.drawCircle(Offset(size.width * .50, horizon), size.width * .72, planet);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const LinearGradient(
        colors: [Color(0x00FF00FF), Color(0xCCFF19E8), Color(0xFF00D9FF)],
      ).createShader(Rect.fromLTWH(0, horizon - 65, size.width, 130));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * .50, horizon), width: size.width * 1.45, height: size.width * .55),
      math.pi * 1.03, math.pi * .94, false, ring,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
