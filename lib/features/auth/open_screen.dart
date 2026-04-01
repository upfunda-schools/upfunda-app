import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OpenScreen extends StatelessWidget {
  const OpenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- BACKGROUND DECORATIONS ---

          // Yellow Blob - Top Left
          Positioned(
            top: size.height * 0.02,
            left: -size.width * 0.1,
            child: Image.asset(
              'assets/images/blob_top_right.png',
              width: size.width * 0.5,
            ),
          ),

          // Yellow Blob - Bottom Right
          Positioned(
            bottom: 0,
            right: -size.width * 0.03,
            child: Image.asset(
              'assets/images/blob_bottom_left.png',
              width: size.width * 0.4,
            ),
          ),

          // Grid Pattern - Top Right Area
          Positioned(
            top: size.height * 0.02,
            right: -size.width * 0.03,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/grid_pattern.png',
                width: size.width * 0.6,
              ),
            ),
          ),

          // Grid Pattern - Bottom Left Area
          Positioned(
            bottom: size.height * 0.05,
            left: -size.width * 0.05,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/grid_pattern.png',
                width: size.width * 0.5,
              ),
            ),
          ),

          // Brain character
          Positioned(
            top: 40, // 👈 INCREASE move DOWN, DECREASE move UP
            right: 50, // 👈 INCREASE move LEFT, DECREASE move RIGHT
            child: Image.asset('assets/images/brain_character.png', width: 100),
          ),

          // Pi symbol
          Positioned(
            top: 50, // 👈 INCREASE move DOWN, DECREASE move UP
            right: 20, // 👈 INCREASE move LEFT, DECREASE move RIGHT
            child: Image.asset('assets/images/pi_symbol.png', width: 35),
          ),

          // Book asset
          Positioned(
            top: 150, // 👈 INCREASE move DOWN, DECREASE move UP
            right: -40, // 👈 INCREASE move LEFT, DECREASE move RIGHT
            child: Image.asset('assets/images/Book.png', width: 100),
          ),

          // // Math symbols (E=mc2 etc)
          // Positioned(
          //   top: 160, // 👈 INCREASE move DOWN, DECREASE move UP
          //   right: 0, // 👈 INCREASE move LEFT, DECREASE move RIGHT
          //   child: Image.asset('assets/images/math_symbols.png', width: 50),
          // ),

          // School objects (Bottom Left)
          Positioned(
            bottom: 0, // 👈 INCREASE move UP, DECREASE move DOWN
            left: 0, // 👈 INCREASE move RIGHT, DECREASE move LEFT
            child: Image.asset('assets/images/school_objects.png', width: 210),
          ),

          // Overlapping circles (Bottom Left area)
          Positioned(
            bottom: 110, // 👈 INCREASE move UP, DECREASE move DOWN
            left: 0, // 👈 INCREASE move RIGHT, DECREASE move LEFT
            child: Image.asset('assets/images/decor_7.png', width: 60),
          ),

          // --- MAIN CENTERED CONTENT (KITE & LOGO) ---
          Center(
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: size.height * 0.18,
                ), // 👈 INCREASE move DOWN, DECREASE move UP
                // Kite Logo
                Transform.translate(
                  offset: const Offset(
                    10,
                    20,
                  ), // 👈 X: MOVE RIGHT(+)/LEFT(-), Y: MOVE DOWN(+)/UP(-)
                  child: Image.asset(
                    'assets/images/splash_kite.png',
                    width: (size.width * 0.45).clamp(0, size.height * 0.35),
                  ),
                ),

                const SizedBox(
                  height: 40,
                ), // 👈 INCREASE move DOWN, DECREASE move UP
                // App Logo Text
                Transform.translate(
                  offset: const Offset(
                    0,
                    0,
                  ), // 👈 X: MOVE RIGHT(+)/LEFT(-), Y: MOVE DOWN(+)/UP(-)
                  child: Image.asset(
                    'assets/images/app_logo_text.png',
                    width: size.width * 0.70,
                  ),
                ),

                // Brush Stroke and Subtext (Moved Up)
                Transform.translate(
                  offset: Offset(
                    0,
                    -size.height * 0.11,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/yellow_brush_stroke.png',
                        width: size.width * 0.70,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: size.height * 0.001,
                        ),
                        child: Image.asset(
                          'assets/images/splash_text.png',
                          width: size.width * 0.60,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 5,
                ), // 👈 INCREASE move DOWN, DECREASE move UP
                // Get Started Button (Moved Up)
                Transform.translate(
                  offset: Offset(
                    0,
                    -size.height * 0.20,
                  ),
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/btn_bg.png',
                          width: size.width * 0.50,
                        ),
                        Image.asset(
                          'assets/images/btn_get_started_text.png',
                          width: size.width * 0.30,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}
