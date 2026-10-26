import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../core/services/storage_service.dart';
import '../models/card_set.dart';
import '../models/game_type.dart';
import '../services/pack_generator_service.dart';
import '../widgets/daily_timer_badge.dart';
import 'pack_opening_screen.dart';

class SetSelectorScreen extends StatefulWidget {
  final GameType game;

  const SetSelectorScreen({super.key, required this.game});

  @override
  State<SetSelectorScreen> createState() => _SetSelectorScreenState();
}

class _SetSelectorScreenState extends State<SetSelectorScreen> {
  List<CardSet> _sets = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    final sets = await PackGeneratorService.getSetsForGame(widget.game);
    if (mounted) {
      setState(() {
        _sets = sets;
        _isLoading = false;
      });
    }
  }

  void _onOpenPack(CardSet cardSet) {
    final bool isAdmin = StorageService.isAdminUser();
    final remaining = StorageService.getRemainingPacksToday(
      widget.game,
      ApiConstants.dailyPacksPerGame,
    );

    if (!isAdmin && remaining <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Límite diario alcanzado'),
          content: Text(
            'Ya has abierto tus ${ApiConstants.dailyPacksPerGame} sobres diarios de ${widget.game.title}.\n¡Vuelve mañana para abrir más sobres gratis!',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.amberAccent)),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackOpeningScreen(
          game: widget.game,
          cardSet: cardSet,
        ),
      ),
    ).then((_) {
      setState(() {}); // Refresh daily packs badge
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: widget.game.primaryColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.riftboundColor),
            )
          : Column(
              children: [
                // Top Info Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expansiones Disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      DailyTimerBadge(game: widget.game),
                    ],
                  ),
                ),

                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar expansión por nombre o código...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const Divider(color: Colors.white10),

                // Set List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filtered = _sets.where((s) {
                        if (_searchQuery.isEmpty) return true;
                        final q = _searchQuery.toLowerCase();
                        return s.name.toLowerCase().contains(q) ||
                            s.code.toLowerCase().contains(q);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No se encontraron expansiones',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildSetCard(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSetCard(CardSet item) {
    final bool hasBoosterArt = item.boosterArtUrl != null && item.boosterArtUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBoosterArt)
                  Container(
                    width: 50,
                    height: 74,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.game.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: item.boosterArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: Colors.white10),
                        errorWidget: (ctx, url, err) => Container(
                          color: widget.game.primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.style_rounded,
                            size: 20,
                            color: widget.game.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.game.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.code.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: widget.game.primaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (item.totalCards > 0) ...[
                            const Icon(Icons.style_outlined,
                                size: 13, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              '${item.totalCards} cartas',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (item.releaseDate != null) ...[
                            const Icon(Icons.calendar_today_rounded,
                                size: 13, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              item.releaseDate!,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _onOpenPack(item),
                icon: const Icon(Icons.offline_bolt_rounded, color: Colors.black),
                label: const Text(
                  'ABRIR SOBRE',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
