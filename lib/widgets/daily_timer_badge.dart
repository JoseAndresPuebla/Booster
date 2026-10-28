import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_type.dart';
import '../core/constants/api_constants.dart';
import '../core/services/storage_service.dart';

class DailyTimerBadge extends StatefulWidget {
  final GameType game;

  const DailyTimerBadge({super.key, required this.game});

  @override
  State<DailyTimerBadge> createState() => _DailyTimerBadgeState();
}

class _DailyTimerBadgeState extends State<DailyTimerBadge> {
  Timer? _timer;
  late Duration _timeRemaining;
  late int _remainingPacks;

  @override
  void initState() {
    super.initState();
    _refreshState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _refreshState() {
    _remainingPacks = StorageService.getRemainingPacksToday(
      widget.game,
      ApiConstants.dailyPacksPerGame,
    );
    _timeRemaining = StorageService.getTimeUntilNextDailyReset();
  }

  void _tick() {
    if (mounted) {
      setState(() {
        _timeRemaining = StorageService.getTimeUntilNextDailyReset();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = StorageService.isAdminUser();
    final bool hasPacks = isAdmin || _remainingPacks > 0;

    final Color badgeColor = isAdmin
        ? const Color(0xFFE040FB)
        : hasPacks
            ? const Color(0xFF00E5FF)
            : const Color(0xFFFFA000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withOpacity(0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin
                ? 'TESTER: ILIMITADO'
                : hasPacks
                    ? '$_remainingPacks/${ApiConstants.dailyPacksPerGame} SOBRES'
                    : _formatDuration(_timeRemaining),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
