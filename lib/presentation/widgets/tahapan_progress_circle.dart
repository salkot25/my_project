import 'package:flutter/material.dart';

/// TahapanProgressCircle widget for showing progress as a circular indicator with percentage text.
class TahapanProgressCircle extends StatelessWidget {
  final int total;
  final int done;
  final double size;
  final Color? mainColor;
  final Color? bgColor;
  final TextStyle? textStyle;

  const TahapanProgressCircle({
    super.key,
    required this.total,
    required this.done,
    this.size = 48,
    this.mainColor,
    this.bgColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = total == 0 ? 0 : done / total;
    final Color effectiveMainColor = mainColor ?? Colors.orangeAccent.shade200;
    final Color effectiveBgColor = bgColor ?? Colors.white.withOpacity(0.18);
    final int percentValue = (percent * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(
            width: size - 8,
            height: size - 8,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveBgColor),
            ),
          ),
          SizedBox(
            width: size - 8,
            height: size - 8,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveMainColor),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            '$percentValue%',
            style:
                textStyle ??
                const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  shadows: [
                    Shadow(
                      color: Colors.white24,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
