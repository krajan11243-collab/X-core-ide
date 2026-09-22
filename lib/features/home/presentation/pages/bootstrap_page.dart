import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/runtime_service.dart';
import '../../../../core/services/workspace_service.dart';

class BootstrapPage extends ConsumerStatefulWidget {
  const BootstrapPage({super.key});
  @override
  ConsumerState<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends ConsumerState<BootstrapPage> {
  static const bg = Color(0xFF020205);
  static const pink = Color(0xFFFF3B6B);
  static const hotPink = Color(0xFFFF168D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReady();
      _startInit();
    });
  }

  void _checkReady() {
    if (ref.read(runtimeServiceProvider).isInitialized) context.go('/');
  }

  Future<void> _startInit() async {
    final runtime = ref.read(runtimeServiceProvider);
    final router = GoRouter.of(context);
    await runtime.init();
    if (runtime.isInitialized) {
      try {
        await ref.read(workspaceProvider.notifier).restoreLastWorkspace();
      } catch (e) {
        debugPrint('Failed to restore last workspace: $e');
      }
      if (mounted) router.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(runtimeServiceProvider);
    final progress = runtime.progress.clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _BootBackgroundPainter())),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 3),
            _brand(),
            const SizedBox(height: 62),
            _runtimeCard(runtime, progress),
            const SizedBox(height: 46),
            _cleanButton(runtime),
            const Spacer(flex: 2),
          ]),
        ),
      ]),
    );
  }

  Widget _brand() => Column(children: [
    SizedBox(width: 185, height: 185, child: CustomPaint(painter: _XCoreLogoPainter())),
    const SizedBox(height: 14),
    RichText(text: const TextSpan(children: [
      TextSpan(text: 'X-core ', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
      TextSpan(text: 'IDE', style: TextStyle(color: Color(0xFFFF6687), fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
    ])),
  ]);

  Widget _runtimeCard(RuntimeService runtime, double progress) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 34),
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 21),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .025),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: pink.withValues(alpha: .85), width: 1.2),
      boxShadow: [BoxShadow(color: pink.withValues(alpha: .10), blurRadius: 26)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.download_rounded, color: Color(0xFFFF5A3D), size: 30),
        ),
        const SizedBox(width: 15),
        Expanded(child: Text(
          runtime.status.isEmpty ? 'Starting X-core IDE...' : runtime.status,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        )),
      ]),
      const SizedBox(height: 20),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Container(height: 8, color: Colors.white.withValues(alpha: .09)),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(height: 8, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [pink, hotPink]),
            )),
          ),
        ]),
      ),
      const SizedBox(height: 13),
      const Text('Preparing packages...', style: TextStyle(color: Colors.white54, fontSize: 13)),
    ]),
  );

  Widget _cleanButton(RuntimeService runtime) => TextButton(
    onPressed: () => runtime.reset(),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 15),
      side: BorderSide(color: pink.withValues(alpha: .85), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      foregroundColor: pink,
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.refresh_rounded, size: 22),
      SizedBox(width: 12),
      Text('Clean Reinstall', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _XCoreLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.width / 185;
    final glow = Paint()..color = const Color(0xFFFF245E).withValues(alpha: .18)..style = PaintingStyle.stroke..strokeWidth = 2*s;
    final ring = Paint()..color = const Color(0xFFFF245E).withValues(alpha: .7)..style = PaintingStyle.stroke..strokeWidth = 1.5*s;
    for (final r in [60.0, 73.0]) canvas.drawCircle(c, r*s, glow);
    canvas.drawArc(Rect.fromCircle(center:c,radius:82*s),-.8,1.35,false,ring);
    canvas.drawArc(Rect.fromCircle(center:c,radius:82*s),2.2,1.1,false,ring);
    canvas.drawArc(Rect.fromCircle(center:c,radius:82*s),4.25,.95,false,ring);
    final box=RRect.fromRectAndRadius(Rect.fromCenter(center:c,width:116*s,height:116*s),Radius.circular(25*s));
    final border=Paint()..shader=const LinearGradient(colors:[Color(0xFFFF5A77),Color(0xFFFF1D66)],begin:Alignment.topLeft,end:Alignment.bottomRight).createShader(box.outerRect)..style=PaintingStyle.stroke..strokeWidth=3*s;
    canvas.drawRRect(box,border);
    final slider=Paint()..color=const Color(0xFFFF7186)..strokeWidth=9*s..strokeCap=StrokeCap.square;
    for(final dx in [-27.0,0.0,27.0]){
      canvas.drawLine(Offset(c.dx+dx*s,c.dy-38*s),Offset(c.dx+dx*s,c.dy+38*s),slider);
      canvas.drawRect(Rect.fromCenter(center:Offset(c.dx+dx*s,c.dy+5*s),width:20*s,height:31*s),Paint()..color=const Color(0xFFFF7186));
    }
    canvas.drawRect(Rect.fromLTWH(c.dx-54*s,c.dy-2*s,108*s,7*s),Paint()..color=const Color(0xFF020205));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class _BootBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow=Paint()..shader=const RadialGradient(colors:[Color(0x33FF145E),Color(0x00000000)]).createShader(Rect.fromCircle(center:Offset(size.width/2,size.height*.44),radius:size.width*.48));
    canvas.drawCircle(Offset(size.width/2,size.height*.44),size.width*.48,glow);
    final wave=Paint()..color=const Color(0x66FF164D)..style=PaintingStyle.stroke..strokeWidth=1.2;
    final path=Path();
    for(double x=-20;x<=size.width+20;x+=5){
      final y=size.height*.78+math.sin(x/65)*15+math.sin(x/130)*8;
      if(x==-20) path.moveTo(x,y); else path.lineTo(x,y);
    }
    canvas.drawPath(path,wave);
    canvas.drawPath(path.shift(const Offset(0,8)),wave);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
