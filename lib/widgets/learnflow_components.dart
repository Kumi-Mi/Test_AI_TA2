import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class LearnflowCard extends StatelessWidget {
  const LearnflowCard({
    required this.child,
    this.color = AppColors.paperDeep,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {this.color = AppColors.inkMuted, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 11,
        height: 1.2,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ).copyWith(color: color),
    );
  }
}

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    required this.value,
    this.color = AppColors.cyan,
    super.key,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Xác suất ${(value * 100).round()} phần trăm',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: LinearProgressIndicator(
          minHeight: 9,
          value: value.clamp(0, 1),
          backgroundColor: AppColors.rule,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class MemoryMascot extends StatelessWidget {
  const MemoryMascot({this.size = 84, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Linh vật trí nhớ đang tập trung',
      child: CustomPaint(
        size: Size.square(size),
        painter: _MemoryMascotPainter(),
      ),
    );
  }
}

class _MemoryMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = AppColors.coral;
    final ink = Paint()..color = AppColors.ink;
    final highlight = Paint()..color = AppColors.paper;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .08,
        size.height * .18,
        size.width * .84,
        size.height * .68,
      ),
      Radius.circular(size.width * .26),
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.06);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRRect(rect, body);
    canvas.drawCircle(
      Offset(size.width * .36, size.height * .48),
      size.width * .105,
      highlight,
    );
    canvas.drawCircle(
      Offset(size.width * .67, size.height * .48),
      size.width * .105,
      highlight,
    );
    canvas.drawCircle(
      Offset(size.width * .38, size.height * .5),
      size.width * .045,
      ink,
    );
    canvas.drawCircle(
      Offset(size.width * .65, size.height * .5),
      size.width * .045,
      ink,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * .38,
        size.height * .51,
        size.width * .28,
        size.height * .2,
      ),
      .25,
      2.6,
      false,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .035
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
