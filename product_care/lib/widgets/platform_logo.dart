import 'package:flutter/material.dart';

import '../services/restock_search_service.dart';

class PlatformLogo extends StatelessWidget {
  const PlatformLogo(this.platform, {super.key});

  final ShoppingPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, mark) = switch (platform) {
      ShoppingPlatform.google => (Colors.white, const Color(0xFF4285F4), 'G'),
      ShoppingPlatform.amazonIndia => (
        const Color(0xFFFFF4E5),
        const Color(0xFF232F3E),
        'a',
      ),
      ShoppingPlatform.flipkart => (
        const Color(0xFFEAF2FF),
        const Color(0xFF2874F0),
        'F',
      ),
      ShoppingPlatform.zepto => (
        const Color(0xFFF4E9FF),
        const Color(0xFF7B2FE3),
        'Z',
      ),
      null => (const Color(0xFFE8F3EE), const Color(0xFF246B52), '↗'),
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: foreground.withValues(alpha: .13)),
      ),
      alignment: Alignment.center,
      child: platform == ShoppingPlatform.google
          ? ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFF34A853),
                  Color(0xFFFBBC05),
                  Color(0xFFEA4335),
                ],
              ).createShader(bounds),
              child: Text(
                mark,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  mark,
                  style: TextStyle(
                    color: foreground,
                    fontSize: mark == 'a' ? 27 : 23,
                    fontWeight: FontWeight.w900,
                    fontStyle: platform == ShoppingPlatform.amazonIndia
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                if (platform == ShoppingPlatform.amazonIndia)
                  const Positioned(
                    bottom: 7,
                    right: 8,
                    child: Icon(
                      Icons.arrow_right_alt,
                      size: 16,
                      color: Color(0xFFFF9900),
                    ),
                  ),
                if (platform == ShoppingPlatform.flipkart)
                  const Positioned(
                    right: 7,
                    top: 8,
                    child: Icon(
                      Icons.shopping_bag,
                      size: 10,
                      color: Color(0xFFFFC400),
                    ),
                  ),
              ],
            ),
    );
  }
}
