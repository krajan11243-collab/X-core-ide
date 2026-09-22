import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_ide/models/project_model.dart';
import 'package:quantum_ide/core/services/project_service.dart';
import 'xcore_project_icons.dart';

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
                padding: EdgeInsets.fromLTRB(18, 8, 18, bottom + 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _projectName(),
                    const SizedBox(height: 16),
                    _section(LucideIcons.layout_grid, 'PROJECT TYPE', 'Choose your technology'),
                    const SizedBox(height: 8),
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
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cyan.withValues(alpha: .15)),
      boxShadow: [BoxShadow(color: purple.withValues(alpha: .05), blurRadius: 18)],
    ),
    child: Row(children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: purple.withValues(alpha: .28)),
        ),
        child: const Icon(LucideIcons.box, color: Color(0xFFB873FF), size: 27),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Name', style: GoogleFonts.inter(color: const Color(0xFFB4A9C9), fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: field,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Project Name',
                  hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: .58), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
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
    const gap = 8.0;
    final unit = (constraints.maxWidth - gap * 3) / 4;

    final items = <Map<String, dynamic>>[
      {'name':'FLUTTER','type':ProjectType.flutter,'logo':XCoreTechLogo.flutter,'color':cyan},
      {'name':'PYTHON','type':ProjectType.python,'logo':XCoreTechLogo.python,'color':const Color(0xFFFFD43B)},
      {'name':'NODEJS','type':ProjectType.nodejs,'logo':XCoreTechLogo.nodejs,'color':const Color(0xFF68A063)},
      {'name':'WEB','type':ProjectType.web,'logo':XCoreTechLogo.web,'color':const Color(0xFF4F7CFF)},
      {'name':'ANDROID JAVA','type':ProjectType.androidJava,'logo':XCoreTechLogo.androidJava,'color':const Color(0xFF72DE4A)},
      {'name':'ANDROID KOTLIN','type':ProjectType.androidKotlin,'logo':XCoreTechLogo.androidKotlin,'color':const Color(0xFF8B5CF6)},
      {'name':'RUST','type':ProjectType.rust,'logo':XCoreTechLogo.rust,'color':const Color(0xFFFF8A4C)},
    ];

    Widget card(Map<String, dynamic> item, {required double width}) {
      final selected = type == item['type'];
      final color = item['color'] as Color;
      final logo = item['logo'] as XCoreTechLogo;

      return SizedBox(
        width: width,
        height: 66,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() {
              type = item['type'] as ProjectType;
              if (type == ProjectType.flutter) sdkCtrl.text = '34';
              if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) {
                sdkCtrl.text = 'com.example.app';
              }
            }),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .105) : panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? color : Colors.white.withValues(alpha: .105),
                  width: selected ? 1.7 : 1.0,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: color.withValues(alpha: .22), blurRadius: 15, spreadRadius: -4)]
                    : null,
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 33,
                        height: 33,
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: .12) : Colors.white.withValues(alpha: .025),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: XCoreTechIcon(
                          logo: logo,
                          color: selected ? color : Colors.white70,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(
                            item['name'] as String,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: GoogleFonts.inter(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 7.7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .01,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: panel,
                          border: Border.all(color: color, width: 1.2),
                        ),
                        child: Icon(LucideIcons.check, color: color, size: 9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              card(items[i], width: unit),
              if (i < 3) const SizedBox(width: gap),
            ],
          ],
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(flex: 3, child: card(items[4], width: double.infinity)),
            const SizedBox(width: gap),
            Expanded(flex: 3, child: card(items[5], width: double.infinity)),
            const SizedBox(width: gap),
            Expanded(flex: 2, child: card(items[6], width: double.infinity)),
          ],
        ),
      ],
    );
  });
  Widget _platformGrid() => LayoutBuilder(builder: (context, constraints) {
    const gap = 8.0;
    final width = (constraints.maxWidth - gap * 2) / 3;

    final data = <Map<String, dynamic>>[
      {'name':'ANDROID','key':'android','logo':XCorePlatformLogo.android},
      {'name':'IOS','key':'ios','logo':XCorePlatformLogo.apple},
      {'name':'WEB','key':'web','logo':XCorePlatformLogo.web},
      {'name':'WINDOWS','key':'windows','logo':XCorePlatformLogo.windows},
      {'name':'MACOS','key':'macos','logo':XCorePlatformLogo.apple},
      {'name':'LINUX','key':'linux','logo':XCorePlatformLogo.linux},
    ];

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: data.map((item) {
        final key = item['key'] as String;
        final selected = platforms.contains(key);

        return SizedBox(
          width: width,
          height: 58,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                if (!selected) {
                  platforms.add(key);
                } else if (platforms.length > 1) {
                  platforms.remove(key);
                }
              }),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? pink.withValues(alpha: .09) : panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? pink : Colors.white.withValues(alpha: .105),
                    width: selected ? 1.7 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: pink.withValues(alpha: .18), blurRadius: 15, spreadRadius: -4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    XCorePlatformIcon(
                      logo: item['logo'] as XCorePlatformLogo,
                      color: selected ? pink : Colors.white70,
                      size: 21,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 9.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 3),
                      Icon(LucideIcons.check, color: pink, size: 12),
                    ],
                  ],
                ),
              ),
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
    width: double.infinity,
    height: 92,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF16D8), Color(0xFFB02CFF), Color(0xFF3F64FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF16D8),
              blurRadius: 30,
              spreadRadius: -9,
              offset: Offset(0, 9),
            ),
            BoxShadow(
              color: Color(0xFF5A52FF),
              blurRadius: 24,
              spreadRadius: -12,
              offset: Offset(8, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: busy ? null : save,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white.withValues(alpha: .14),
          highlightColor: Colors.white.withValues(alpha: .06),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        widget.project == null ? 'Create Project' : 'Save Changes',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Icon(
                        LucideIcons.arrow_right,
                        color: Colors.white,
                        size: 31,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}


class _WizardBackdropPainter extends CustomPainter {
  const _WizardBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Reference-style black/cosmic background: a restrained purple glow and
    // partial orbital arc at the top-right. No large bottom planet/blob.
    final center = Offset(size.width * .86, size.height * .055);
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x552F0BFF), Color(0x0012002B)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .48));
    canvas.drawCircle(center, size.width * .48, glow);

    final orb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = const LinearGradient(
        colors: [Color(0x005E2CFF), Color(0xFF7B2CFF), Color(0x001A7BFF)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .91, size.height * .07),
        radius: size.width * .36,
      ));
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * .91, size.height * .07),
        width: size.width * .72,
        height: size.width * .72,
      ),
      math.pi * .52,
      math.pi * .88,
      false,
      orb,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
