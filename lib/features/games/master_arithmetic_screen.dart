import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'master_arithmetic/master_arithmetic_games.dart';

class MasterArithmeticScreen extends StatelessWidget {
  const MasterArithmeticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Area
          _buildHeader(context, scale),
          
          // Games List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(25 * scale, 10 * scale, 25 * scale, 40 * scale),
              itemCount: kMasterArithmeticGames.length,
              separatorBuilder: (_, __) => SizedBox(height: 16 * scale),
              itemBuilder: (context, i) => _GameTile(game: kMasterArithmeticGames[i], scale: scale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double scale) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10 * scale,
        left: 20 * scale,
        right: 20 * scale,
        bottom: 20 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(8 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18 * scale,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 20 * scale),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(15 * scale),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: const Color(0xFF22C55E),
                  size: 28 * scale,
                ),
              ),
              SizedBox(width: 16 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master Arithmetic',
                    style: GoogleFonts.montserrat(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'Pick a game and start practising',
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final MasterArithmeticGameInfo game;
  final double scale;

  const _GameTile({required this.game, required this.scale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(game.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22 * scale),
          border: Border.all(
            color: game.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              // Left Icon
              Container(
                width: 65 * scale,
                height: 65 * scale,
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
                child: Center(
                  child: Icon(
                    game.icon,
                    color: game.color,
                    size: 32 * scale,
                  ),
                ),
              ),
              SizedBox(width: 20 * scale),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      game.description,
                      style: GoogleFonts.montserrat(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Button
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: BoxDecoration(
                  color: game.color,
                  borderRadius: BorderRadius.circular(14 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: game.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18 * scale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
