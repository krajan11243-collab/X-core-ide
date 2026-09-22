import 'dart:math' as math;
import 'package:flutter/material.dart';

enum XCoreTechLogo {
  flutter,
  python,
  nodejs,
  web,
  androidJava,
  androidKotlin,
  rust,
}

enum XCorePlatformLogo { android, apple, web, windows, linux }

class XCoreTechIcon extends StatelessWidget {
  const XCoreTechIcon({
    super.key,
    required this.logo,
    required this.color,
    this.size = 25,
  });

  final XCoreTechLogo logo;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _XCoreTechLogoPainter(logo: logo, color: color),
  );
}

class XCorePlatformIcon extends StatelessWidget {
  const XCorePlatformIcon({
    super.key,
    required this.logo,
    required this.color,
    this.size = 22,
  });

  final XCorePlatformLogo logo;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _XCorePlatformLogoPainter(logo: logo, color: color),
  );
}

class _XCoreTechLogoPainter extends CustomPainter {
  const _XCoreTechLogoPainter({required this.logo, required this.color});
  final XCoreTechLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 32;
    final c = Offset(size.width / 2, size.height / 2);
    final fill = Paint()..isAntiAlias = true..style = PaintingStyle.fill..color = color;
    final line = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    switch (logo) {
      case XCoreTechLogo.flutter:
        final p = Path()
          ..moveTo(4*s, 20*s)..lineTo(17*s, 7*s)..lineTo(27*s, 7*s)
          ..lineTo(15*s, 19*s)..lineTo(21*s, 19*s)..lineTo(27*s, 25*s)
          ..lineTo(18*s, 25*s)..lineTo(13*s, 20*s)..lineTo(8*s, 25*s)..lineTo(4*s, 21*s)..close();
        canvas.drawPath(p, fill);
        break;
      case XCoreTechLogo.python:
        final top = Path()
          ..moveTo(16*s, 3*s)..cubicTo(9*s,3*s,7*s,7*s,7*s,12*s)
          ..lineTo(7*s,16*s)..lineTo(14*s,16*s)..lineTo(14*s,9*s)
          ..cubicTo(14*s,7*s,16*s,6*s,18*s,6*s)..lineTo(24*s,6*s)
          ..lineTo(24*s,3*s)..close();
        final bottom = Path()
          ..moveTo(16*s,29*s)..cubicTo(23*s,29*s,25*s,25*s,25*s,20*s)
          ..lineTo(25*s,16*s)..lineTo(18*s,16*s)..lineTo(18*s,23*s)
          ..cubicTo(18*s,25*s,16*s,26*s,14*s,26*s)..lineTo(8*s,26*s)
          ..lineTo(8*s,29*s)..close();
        canvas.drawPath(top, Paint()..color=const Color(0xFF3776AB));
        canvas.drawPath(bottom, Paint()..color=const Color(0xFFFFD43B));
        canvas.drawCircle(18*s > 0 ? Offset(18*s,8*s) : c, 1*s, Paint()..color=Colors.white);
        canvas.drawCircle(14*s > 0 ? Offset(14*s,24*s) : c, 1*s, Paint()..color=Colors.white);
        break;
      case XCoreTechLogo.nodejs:
        final p=Path();
        for(int i=0;i<6;i++){
          final a=-math.pi/2+i*math.pi/3;
          final pt=Offset(c.dx+13*s*math.cos(a),c.dy+13*s*math.sin(a));
          if(i==0)p.moveTo(pt.dx,pt.dy);else p.lineTo(pt.dx,pt.dy);
        }
        p.close();
        canvas.drawPath(p, Paint()..color=const Color(0xFF68A063));
        final tp=TextPainter(
          text: const TextSpan(text:'node',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900)),
          textDirection:TextDirection.ltr,
        )..layout();
        tp.paint(canvas,Offset(c.dx-tp.width/2,c.dy-tp.height/2));
        break;
      case XCoreTechLogo.web:
        canvas.drawCircle(c,11.5*s,line);
        canvas.drawOval(Rect.fromCenter(center:c,width:11*s,height:23*s),line);
        canvas.drawLine(Offset(4*s,c.dy),Offset(28*s,c.dy),line);
        canvas.drawLine(Offset(c.dx,5*s),Offset(c.dx,27*s),line);
        break;
      case XCoreTechLogo.androidJava:
        canvas.drawArc(Rect.fromLTWH(7*s,13*s,18*s,13*s),math.pi,math.pi,true,fill);
        canvas.drawRect(Rect.fromLTWH(7*s,18*s,18*s,8*s),fill);
        canvas.drawLine(Offset(11*s,12*s),Offset(8*s,8*s),line);
        canvas.drawLine(Offset(21*s,12*s),Offset(24*s,8*s),line);
        canvas.drawCircle(Offset(12*s,18*s),1*s,Paint()..color=Colors.black);
        canvas.drawCircle(Offset(20*s,18*s),1*s,Paint()..color=Colors.black);
        break;
      case XCoreTechLogo.androidKotlin:
        final p=Path()
          ..moveTo(5*s,4*s)..lineTo(27*s,4*s)..lineTo(16*s,15*s)
          ..lineTo(27*s,28*s)..lineTo(18*s,28*s)..lineTo(11*s,21*s)
          ..lineTo(5*s,27*s)..close();
        fill.shader=const LinearGradient(
          colors:[Color(0xFF7F52FF),Color(0xFFFF3D81),Color(0xFF00C8FF)],
          begin:Alignment.topLeft,end:Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0,0,size.width,size.height));
        canvas.drawPath(p,fill); fill.shader=null;
        break;
      case XCoreTechLogo.rust:
        canvas.drawCircle(c,10*s,line);
        for(int i=0;i<8;i++){
          final a=i*math.pi/4;
          canvas.drawLine(
            Offset(c.dx+10*s*math.cos(a),c.dy+10*s*math.sin(a)),
            Offset(c.dx+14*s*math.cos(a),c.dy+14*s*math.sin(a)),line);
        }
        canvas.drawCircle(c,4*s,line);
        canvas.drawCircle(c,1.5*s,fill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _XCoreTechLogoPainter oldDelegate) =>
      oldDelegate.logo != logo || oldDelegate.color != color;
}

class _XCorePlatformLogoPainter extends CustomPainter {
  const _XCorePlatformLogoPainter({required this.logo, required this.color});
  final XCorePlatformLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s=size.shortestSide/32;
    final c=Offset(size.width/2,size.height/2);
    final fill=Paint()..isAntiAlias=true..style=PaintingStyle.fill..color=color;
    final line=Paint()..isAntiAlias=true..style=PaintingStyle.stroke..strokeWidth=2*s..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..color=color;

    switch(logo){
      case XCorePlatformLogo.android:
        canvas.drawArc(Rect.fromLTWH(6*s,12*s,20*s,17*s),math.pi,math.pi,true,fill);
        canvas.drawRect(Rect.fromLTWH(6*s,18*s,20*s,11*s),fill);
        canvas.drawLine(Offset(11*s,11*s),Offset(8*s,6*s),line);
        canvas.drawLine(Offset(21*s,11*s),Offset(24*s,6*s),line);
        canvas.drawCircle(Offset(12*s,17*s),1.1*s,Paint()..color=Colors.black);
        canvas.drawCircle(Offset(20*s,17*s),1.1*s,Paint()..color=Colors.black);
        break;
      case XCorePlatformLogo.apple:
        final p=Path()
          ..moveTo(19*s,8*s)..cubicTo(18*s,5*s,21*s,3*s,23*s,3*s)
          ..cubicTo(23*s,6*s,21*s,8*s,19*s,8*s)..close();
        canvas.drawPath(p,fill);
        final body=Path()
          ..moveTo(18*s,10*s)..cubicTo(13*s,7*s,7*s,10*s,7*s,17*s)
          ..cubicTo(7*s,23*s,11*s,29*s,15*s,29*s)
          ..cubicTo(17*s,29*s,18*s,27*s,20*s,27*s)
          ..cubicTo(22*s,27*s,24*s,29*s,26*s,28*s)
          ..cubicTo(29*s,24*s,30*s,20*s,29*s,17*s)
          ..cubicTo(28*s,13*s,24*s,11*s,22*s,11*s)
          ..cubicTo(20*s,11*s,19*s,11*s,18*s,10*s)..close();
        canvas.drawPath(body,fill);
        break;
      case XCorePlatformLogo.web:
        canvas.drawCircle(c,12*s,line);
        canvas.drawOval(Rect.fromCenter(center:c,width:12*s,height:24*s),line);
        canvas.drawLine(Offset(4*s,c.dy),Offset(28*s,c.dy),line);
        break;
      case XCorePlatformLogo.windows:
        canvas.drawRect(Rect.fromLTWH(3*s,5*s,12*s,10*s),fill);
        canvas.drawRect(Rect.fromLTWH(17*s,4*s,12*s,11*s),fill);
        canvas.drawRect(Rect.fromLTWH(3*s,17*s,12*s,10*s),fill);
        canvas.drawRect(Rect.fromLTWH(17*s,16*s,12*s,12*s),fill);
        break;
      case XCorePlatformLogo.linux:
        final head=Path()
          ..moveTo(16*s,4*s)..cubicTo(10*s,4*s,8*s,10*s,9*s,16*s)
          ..cubicTo(7*s,19*s,9*s,25*s,13*s,27*s)
          ..lineTo(19*s,27*s)..cubicTo(24*s,26*s,26*s,21*s,23*s,18*s)
          ..cubicTo(24*s,11*s,22*s,4*s,16*s,4*s)..close();
        canvas.drawPath(head,fill);
        canvas.drawCircle(13*s,15*s,1.1*s,Paint()..color=Colors.black);
        canvas.drawCircle(19*s,15*s,1.1*s,Paint()..color=Colors.black);
        final beak=Path()..moveTo(15*s,17*s)..lineTo(20*s,18*s)..lineTo(15*s,20*s)..close();
        canvas.drawPath(beak,Paint()..color=Colors.black);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _XCorePlatformLogoPainter oldDelegate) =>
      oldDelegate.logo != logo || oldDelegate.color != color;
}
