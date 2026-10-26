import 'dart:async';
import 'package:flutter/material.dart';
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
    final bool hasPacks = _remainingPacks > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasPacks
            ? Colors.green.withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPacks ? Colors.greenAccent : Colors.redAccent.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPacks ? Icons.check_circle_outline_rounded : Icons.access_time_rounded,
            size: 14,
            color: hasPacks ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            hasPacks
                ? '$_remainingPacks/${ApiConstants.dailyPacksPerGame} Sobres'
                : 'Recarga en ${_formatDuration(_timeRemaining)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasPacks ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
