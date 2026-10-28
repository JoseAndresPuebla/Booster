import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _activeFilter = 'todos'; // 'todos', 'recientes', 'especiales'

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
          backgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: Text(
            'Límite Diario Alcanzado',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Ya has abierto tus ${ApiConstants.dailyPacksPerGame} sobres diarios de ${widget.game.title}.\n¡Vuelve tras el reinicio diario para abrir más sobres gratis!',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.game.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Entendido',
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
              ),
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
    final primary = widget.game.primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withOpacity(0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.game.title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: primary,
              ),
            ),
            Text(
              'EXPANSIONES Y SOBRES',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: DailyTimerBadge(game: widget.game),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primary),
            )
          : Column(
              children: [
                // Search Bar + Filter Pills
                _buildHeaderControls(primary),

                // Set List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filtered = _sets.where((s) {
                        // Text search
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          final matches = s.name.toLowerCase().contains(q) ||
                              s.code.toLowerCase().contains(q);
                          if (!matches) return false;
                        }

                        // Category pill filter
                        if (_activeFilter == 'recientes') {
                          final year = s.releaseDate ?? '';
                          return year.contains('2024') || year.contains('2023');
                        } else if (_activeFilter == 'especiales') {
                          final name = s.name.toLowerCase();
                          return name.contains('special') ||
                              name.contains('crown') ||
                              name.contains('151') ||
                              name.contains('legends') ||
                              name.contains('supercard');
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron expansiones',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildSetCard(item, primary);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderControls(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1.0)),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar expansión por nombre o código...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('Todos los Sets', 'todos', primary),
                const SizedBox(width: 8),
                _buildFilterPill('Recientes', 'recientes', primary),
                const SizedBox(width: 8),
                _buildFilterPill('Ediciones Especiales', 'especiales', primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String id, Color primary) {
    final isSelected = _activeFilter == id;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.2) : AppTheme.surfaceContainerHigh.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : AppTheme.glassBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? primary : AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSetCard(CardSet item, Color primary) {
    final bool hasBoosterArt = item.boosterArtUrl != null && item.boosterArtUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                // 3D Foil Booster Pack Thumbnail
                Container(
                  width: 68,
                  height: 100,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primary.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasBoosterArt)
                          CachedNetworkImage(
                            imageUrl: item.boosterArtUrl!,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(color: AppTheme.surfaceContainerLow),
                            errorWidget: (ctx, url, err) => Container(
                              color: primary.withOpacity(0.15),
                              child: Icon(Icons.style_rounded, size: 24, color: primary),
                            ),
                          )
                        else
                          Container(
                            color: primary.withOpacity(0.15),
                            child: Icon(Icons.style_rounded, size: 24, color: primary),
                          ),

                        // Foil Sheen Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Set Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Set Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primary.withOpacity(0.4), width: 0.8),
                        ),
                        child: Text(
                          item.code.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            color: primary,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Set Name
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Meta details: Total Cards & Release Date (NO collected count as requested)
                      Row(
                        children: [
                          if (item.totalCards > 0) ...[
                            Icon(Icons.layers_outlined, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${item.totalCards} cartas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (item.releaseDate != null) ...[
                            Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              item.releaseDate!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
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

            // "ABRIR SOBRE" Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  shadowColor: primary.withOpacity(0.5),
                ),
                onPressed: () => _onOpenPack(item),
                icon: const Icon(Icons.offline_bolt_rounded, size: 20),
                label: Text(
                  'ABRIR SOBRE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13,
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
