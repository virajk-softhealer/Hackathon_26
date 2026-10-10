import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class ProductCareSplash extends StatefulWidget {
  const ProductCareSplash({super.key});

  @override
  State<ProductCareSplash> createState() => _ProductCareSplashState();
}

class _ProductCareSplashState extends State<ProductCareSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _zoom;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();
    _zoom = Tween<double>(
      begin: .08,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.12, .72, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F7F3), Color(0xFFE7F0E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(scale: _zoom.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withValues(alpha: .16),
                      blurRadius: 34,
                      spreadRadius: 3,
                      offset: const Offset(0, 13),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/branding/product_care_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Product Care',
                style: TextStyle(
                  color: brandInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your home, well cared for',
                style: TextStyle(color: Color(0xFF69766F), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
