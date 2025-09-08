// lib/core/widgets/glassmorphic_container.dart
import 'dart:ui'; // ImageFilter를 위해
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color backgroundColorWithOpacity; // 투명도가 적용된 배경색
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.blurSigmaX = 10.0, // 블러 강도 조절
    this.blurSigmaY = 10.0, // 블러 강도 조절
    this.backgroundColorWithOpacity = const Color.fromRGBO(255, 255, 255, 0.2), // 기본 반투명 흰색
    this.gradient,
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: gradient == null ? backgroundColorWithOpacity : null,
              gradient: gradient,
              border: border, // 예: Border.all(color: Colors.white.withOpacity(0.2))
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
