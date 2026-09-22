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
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final bottom = mq.viewInsets.bottom;
    final s = (w / 344.0).clamp(0.88, 1.16);

    return Material(
      color: bg,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _WizardBackdropPainter())),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _header(s),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(18 * s, 6 * s, 18 * s, bottom + 18 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _projectName(s),
                        SizedBox(height: 16 * s),
                        _section(LucideIcons.layout_grid, 'PROJECT TYPE', 'Choose your technology', s),
                        SizedBox(height: 7 * s),
                        _typeGrid(s),
                        if (type == ProjectType.flutter) ...[
                          SizedBox(height: 18 * s),
                          _section(LucideIcons.cpu, 'ANDROID compileSdk VERSION', 'Android build setting', s),
                          SizedBox(height: 8 * s),
                          _sdkField(s),
                          SizedBox(height: 18 * s),
                          _section(LucideIcons.monitor, 'TARGET DEVICES / PLATFORMS', 'Select target platforms', s),
                          SizedBox(height: 8 * s),
                          _platformGrid(s),
                        ],
                        if (type == ProjectType.androidJava || type == ProjectType.androidKotlin) ...[
                          SizedBox(height: 18 * s),
                          _section(LucideIcons.code, 'PACKAGE NAME (APPLICATION ID)', 'Android package', s),
                          SizedBox(height: 8 * s),
                          _inputField('Package Name', 'com.example.myapp', LucideIcons.code),
                        ],
                        SizedBox(height: 18 * s),
                        _section(LucideIcons.palette, 'Accent Color', 'Choose theme color', s),
                        SizedBox(height: 8 * s),
                        _colorRow(s),
                        SizedBox(height: 18 * s),
                        _section(LucideIcons.image, 'Project Icon', 'Choose app icon', s),
                        SizedBox(height: 8 * s),
                        _iconRow(s),
                        if (error != null) ...[
                          SizedBox(height: 10 * s),
                          _errorBox(),
                        ],
                        SizedBox(height: 18 * s),
                        _createButton(s),
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

  Widget _header(double s) => Padding(
    padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 7 * s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Create ', style: GoogleFonts.inter(
                    fontSize: 25 * s, fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: -.8,
                  )),
                  TextSpan(text: 'Project', style: GoogleFonts.inter(
                    fontSize: 25 * s, fontWeight: FontWeight.w900, color: pink,
                    letterSpacing: -.8,
                  )),
                ])),
              ),
              SizedBox(height: 1 * s),
              Text(
                'Start building something amazing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: muted, fontSize: 10.5 * s, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        SizedBox(width: 10 * s),
        _closeButton(s),
      ],
    ),
  );

  Widget _closeButton(double s) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15 * s),
      child: Container(
        width: 32 * s,
        height: 32 * s,
        decoration: BoxDecoration(
          color: const Color(0xFF111624).withValues(alpha: .78),
          borderRadius: BorderRadius.circular(15 * s),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
          boxShadow: [BoxShadow(color: purple.withValues(alpha: .10), blurRadius: 12)],
        ),
        child: Icon(LucideIcons.x, color: const Color(0xFFE7C8FF), size: 18 * s),
      ),
    ),
  );

  Widget _projectName(double s) => Container(
    height: 62 * s,
    padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 8 * s),
    decoration: BoxDecoration(
      color: const Color(0xFF0B0F1B).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(15 * s),
      border: Border.all(color: const Color(0xFF647089).withValues(alpha: .38)),
      boxShadow: [BoxShadow(color: purple.withValues(alpha: .045), blurRadius: 14)],
    ),
    child: Row(children: [
      Container(
        width: 39 * s,
        height: 46 * s,
        decoration: BoxDecoration(
          color: purple.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(color: purple.withValues(alpha: .28)),
        ),
        child: Icon(LucideIcons.box, color: const Color(0xFFB96DFF), size: 21 * s),
      ),
      SizedBox(width: 9 * s),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Project Name',
              style: GoogleFonts.inter(color: const Color(0xFFB9B1CA), fontSize: 9.5 * s, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 3 * s),
            Container(
              height: 32 * s,
              padding: EdgeInsets.symmetric(horizontal: 9 * s),
              decoration: BoxDecoration(
                color: field,
                borderRadius: BorderRadius.circular(9 * s),
                border: Border.all(color: Colors.white.withValues(alpha: .075)),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 9.5 * s, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Project Name',
                  hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: .64), fontSize: 9.5 * s),
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

  Widget _section(IconData icon, String title, String hint, double s) => SizedBox(
    height: 25 * s,
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFA879FF), size: 17 * s),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: const Color(0xFFE7E6EF), fontSize: 10.5 * s, fontWeight: FontWeight.w900),
          ),
        ),
        SizedBox(width: 6 * s),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5 * s, height: 5 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: purple)),
              SizedBox(width: 5 * s),
              Flexible(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(color: muted, fontSize: 6.5 * s, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _typeGrid(double s) => LayoutBuilder(builder: (context, constraints) {
    final gap = 6.5 * s;
    final unit = (constraints.maxWidth - gap * 3) / 4;
    final items = <Map<String, dynamic>>[
      {'name':'FLUTTER','type':ProjectType.flutter,'logo':XCoreTechLogo.flutter,'color':pink},
      {'name':'PYTHON','type':ProjectType.python,'logo':XCoreTechLogo.python,'color':const Color(0xFFFFD43B)},
      {'name':'NODEJS','type':ProjectType.nodejs,'logo':XCoreTechLogo.nodejs,'color':const Color(0xFF68A063)},
      {'name':'WEB','type':ProjectType.web,'logo':XCoreTechLogo.web,'color':const Color(0xFF4F7CFF)},
      {'name':'ANDROID JAVA','type':ProjectType.androidJava,'logo':XCoreTechLogo.androidJava,'color':const Color(0xFF75DF42)},
      {'name':'ANDROID KOTLIN','type':ProjectType.androidKotlin,'logo':XCoreTechLogo.androidKotlin,'color':const Color(0xFF9C55FF)},
      {'name':'RUST','type':ProjectType.rust,'logo':XCoreTechLogo.rust,'color':const Color(0xFFFF8A4C)},
    ];

    Widget card(Map<String, dynamic> item, double width) {
      final selected = type == item['type'];
      final color = item['color'] as Color;
      return SizedBox(
        width: width,
        height: 36 * s,
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
            borderRadius: BorderRadius.circular(10 * s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .11) : panel,
                borderRadius: BorderRadius.circular(10 * s),
                border: Border.all(
                  color: selected ? color : const Color(0xFF4B5368).withValues(alpha: .50),
                  width: selected ? 1.25 * s : .75 * s,
                ),
                boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 11, spreadRadius: -4)] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, 1.5 * s),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20 * s,
                            height: 20 * s,
                            child: Center(
                              child: XCoreTechIcon(
                                logo: item['logo'] as XCoreTechLogo,
                                color: selected ? color : Colors.white70,
                                size: 19 * s,
                              ),
                            ),
                          ),
                          SizedBox(width: 5 * s),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: width - 33 * s),
                            child: Text(
                              item['name'] as String,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: selected ? Colors.white : Colors.white70,
                                fontSize: 7.2 * s,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -1 * s,
                      top: -1 * s,
                      child: Container(
                        width: 12 * s,
                        height: 12 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF181022),
                          border: Border.all(color: color, width: .8 * s),
                        ),
                        child: Icon(LucideIcons.check, color: color, size: 7 * s),
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
        Row(children: [
          for (int i = 0; i < 4; i++) ...[
            card(items[i], unit),
            if (i < 3) SizedBox(width: gap),
          ],
        ]),
        SizedBox(height: gap),
        Row(children: [
          Expanded(flex: 3, child: card(items[4], double.infinity)),
          SizedBox(width: gap),
          Expanded(flex: 3, child: card(items[5], double.infinity)),
          SizedBox(width: gap),
          Expanded(flex: 2, child: card(items[6], double.infinity)),
        ]),
      ],
    );
  });

  Widget _sdkField(double s) => Container(
    height: 45 * s,
    decoration: BoxDecoration(
      color: field,
      borderRadius: BorderRadius.circular(12 * s),
      border: Border.all(color: const Color(0xFF4B5368).withValues(alpha: .42)),
    ),
    child: Row(
      children: [
        SizedBox(width: 7 * s),
        Container(
          width: 33 * s,
          height: 33 * s,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1820),
            borderRadius: BorderRadius.circular(9 * s),
          ),
          child: XCorePlatformIcon(logo: XCorePlatformLogo.android, color: const Color(0xFF7CEB42), size: 20 * s),
        ),
        SizedBox(width: 7 * s),
        Expanded(
          child: TextField(
            controller: sdkCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 10 * s, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Container(
          width: 27 * s,
          height: 29 * s,
          margin: EdgeInsets.only(right: 7 * s),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .055),
            borderRadius: BorderRadius.circular(9 * s),
          ),
          child: Icon(LucideIcons.chevrons_up_down, color: Colors.white70, size: 15 * s),
        ),
      ],
    ),
  );

  Widget _platformGrid(double s) => LayoutBuilder(builder: (context, constraints) {
    final gap = 6.5 * s;
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
          height: 34 * s,
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
              borderRadius: BorderRadius.circular(10 * s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: selected ? pink.withValues(alpha: .09) : panel,
                  borderRadius: BorderRadius.circular(10 * s),
                  border: Border.all(
                    color: selected ? pink : const Color(0xFF4B5368).withValues(alpha: .48),
                    width: selected ? 1.25 * s : .75 * s,
                  ),
                  boxShadow: selected ? [BoxShadow(color: pink.withValues(alpha: .18), blurRadius: 11, spreadRadius: -4)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    XCorePlatformIcon(
                      logo: item['logo'] as XCorePlatformLogo,
                      color: selected ? pink : Colors.white70,
                      size: 16 * s,
                    ),
                    SizedBox(width: 5 * s),
                    Flexible(
                      child: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 7.8 * s,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: 2 * s),
                      Icon(LucideIcons.check, color: pink, size: 7 * s),
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

  Widget _colorRow(double s) => SizedBox(
    height: 44 * s,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 1 * s),
      itemCount: colors.length + 1,
      separatorBuilder: (_, __) => SizedBox(width: 6 * s),
      itemBuilder: (context, index) {
        final Color? c = index == 0 ? null : colors[index - 1];
        return _colorChoice(c, 40 * s, s);
      },
    ),
  );

  Widget _colorChoice(Color? c, double width, double s) {
    final selected = c == null ? colorValue == null : colorValue == c.toARGB32();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => colorValue = c?.toARGB32()),
        borderRadius: BorderRadius.circular(11 * s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: width,
          height: 48 * s,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(11 * s),
            border: Border.all(
              color: selected ? pink : const Color(0xFF4B5368).withValues(alpha: .45),
              width: selected ? 1.4 * s : .75 * s,
            ),
            boxShadow: selected ? [BoxShadow(color: pink.withValues(alpha: .17), blurRadius: 12)] : null,
          ),
          child: Center(
            child: c == null
                ? Container(
                    width: 27 * s,
                    height: 27 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: field,
                      border: Border.all(color: purple, width: 1.4 * s),
                    ),
                    child: Icon(LucideIcons.ban, color: const Color(0xFFCA8CFF), size: 14 * s),
                  )
                : Container(
                    width: 27 * s,
                    height: 27 * s,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _iconRow(double s) => SizedBox(
    height: 44 * s,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 1 * s),
      itemCount: icons.length + 1,
      separatorBuilder: (_, __) => SizedBox(width: 6 * s),
      itemBuilder: (context, index) {
        final IconData? icon = index == 0 ? null : icons[index - 1];
        return _iconChoice(icon, 40 * s, s);
      },
    ),
  );

  Widget _iconChoice(IconData? icon, double width, double s) {
    final selected = icon == null ? iconCodePoint == null : iconCodePoint == icon.codePoint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          if (icon == null) {
            iconCodePoint = null;
            iconFontFamily = null;
            iconFontPackage = null;
          } else {
            iconCodePoint = icon.codePoint;
            iconFontFamily = icon.fontFamily;
            iconFontPackage = icon.fontPackage;
          }
        }),
        borderRadius: BorderRadius.circular(11 * s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: width,
          height: 48 * s,
          decoration: BoxDecoration(
            color: selected ? pink.withValues(alpha: .075) : panel,
            borderRadius: BorderRadius.circular(11 * s),
            border: Border.all(
              color: selected ? pink : const Color(0xFF4B5368).withValues(alpha: .45),
              width: selected ? 1.4 * s : .75 * s,
            ),
            boxShadow: selected ? [BoxShadow(color: pink.withValues(alpha: .17), blurRadius: 12)] : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, 1.5 * s),
                child: Icon(
                  icon ?? LucideIcons.ban,
                  color: selected ? pink : Colors.white70,
                  size: 18 * s,
                ),
              ),
              if (selected)
                Positioned(
                  right: 3 * s,
                  top: 3 * s,
                  child: Container(
                    width: 10 * s,
                    height: 10 * s,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: pink),
                    child: Icon(LucideIcons.check, color: Colors.white, size: 6 * s),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _errorBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.redAccent.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.redAccent.withValues(alpha: .28)),
    ),
    child: Text(error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 9)),
  );

  Widget _createButton(double s) => SizedBox(
    width: double.infinity,
    height: 49 * s,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14 * s),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * s),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF18D8), Color(0xFFB02CFF), Color(0xFF3F64FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x55FF18D8), blurRadius: 20, spreadRadius: -6, offset: Offset(0, 6)),
            BoxShadow(color: Color(0x443F64FF), blurRadius: 18, spreadRadius: -8, offset: Offset(5, 4)),
          ],
        ),
        child: InkWell(
          onTap: busy ? null : save,
          borderRadius: BorderRadius.circular(14 * s),
          child: Center(
            child: busy
                ? SizedBox(width: 18 * s, height: 18 * s, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, color: Colors.white, size: 18 * s),
                      SizedBox(width: 8 * s),
                      Text(
                        widget.project == null ? 'Create Project' : 'Save Changes',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5 * s, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(width: 11 * s),
                      Icon(LucideIcons.arrow_right, color: Colors.white, size: 17 * s),
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
