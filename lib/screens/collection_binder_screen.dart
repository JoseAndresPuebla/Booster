import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../models/card_model.dart';
import '../models/card_set.dart';
import '../models/game_type.dart';
import '../services/pack_generator_service.dart';
import 'card_detail_screen.dart';

class CollectionBinderScreen extends StatefulWidget {
  final GameType initialGame;

  const CollectionBinderScreen({
    super.key,
    this.initialGame = GameType.pokemon,
  });

  @override
  State<CollectionBinderScreen> createState() => _CollectionBinderScreenState();
}

class _CollectionBinderScreenState extends State<CollectionBinderScreen> {
  late GameType _selectedGame;
  String? _selectedSetCode; // null = 'Todos los Sets'
  Rarity? _filterRarity; // null = 'Todas'
  String _searchQuery = '';
  List<CardSet> _officialSets = [];

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.initialGame;
    _loadOfficialSets();
  }

  Future<void> _loadOfficialSets() async {
    try {
      final sets = await PackGeneratorService.getSetsForGame(_selectedGame);
      if (mounted) {
        setState(() {
          _officialSets = sets;
        });
      }
    } catch (_) {}
  }

  void _onGameChanged(GameType game) {
    setState(() {
      _selectedGame = game;
      _selectedSetCode = null; // Reset set filter when game changes
      _filterRarity = null;
    });
    _loadOfficialSets();
  }

  @override
  Widget build(BuildContext context) {
    final primary = _selectedGame.primaryColor;
    final rawList = StorageService.getLocalCollection(_selectedGame);

    // Build unique sets present in user collection + official sets
    final Map<String, String> availableSets = {};
    for (final s in _officialSets) {
      availableSets[s.code] = s.name;
    }
    for (final item in rawList) {
      final c = CardModel.fromJson(item['card'] as Map<String, dynamic>);
      if (!availableSets.containsKey(c.setCode)) {
        availableSets[c.setCode] = c.setName;
      }
    }

    // Filter collection
    final filtered = rawList.where((item) {
      final card = CardModel.fromJson(item['card'] as Map<String, dynamic>);

      // 1. Set filter
      if (_selectedSetCode != null && card.setCode.toLowerCase() != _selectedSetCode!.toLowerCase()) {
        return false;
      }

      // 2. Rarity filter
      if (_filterRarity != null && card.rarity != _filterRarity) {
        return false;
      }

      // 3. Name search
      if (_searchQuery.isNotEmpty && !card.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ÁLBUM DE COLECCIÓN',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'BÓVEDA DE CARTAS • ${rawList.length} OBTENIDAS',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Division: Game Selector Pills Carousel
          _buildGameSelector(primary),

          // 2. Division: Sets Horizontal Carousel
          _buildSetSelector(availableSets, primary),

          // 3. Search and Rarity Filter Bar
          _buildSearchAndRarityBar(primary),

          const Divider(color: AppTheme.glassBorder, height: 1),

          // 4. Cards Pocket Grid (The Binder Page)
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(primary, rawList.isEmpty)
                : _buildBinderGrid(filtered, primary),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSelector(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.85),
        border: const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1.0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: GameType.values.map((game) {
            final isSelected = game == _selectedGame;
            final count = StorageService.getTotalCardsCollected(game);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onGameChanged(game),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? game.primaryColor.withOpacity(0.2) : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? game.primaryColor : AppTheme.glassBorder,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: game.primaryColor.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? game.primaryColor : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? game.primaryColor : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSetSelector(Map<String, String> availableSets, Color primary) {
    if (availableSets.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withOpacity(0.6),
        border: const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "Todos los Sets" chip
            _buildSetChip(
              label: 'Todos los Sets',
              isSelected: _selectedSetCode == null,
              onTap: () => setState(() => _selectedSetCode = null),
              primary: primary,
            ),

            // Individual Sets chips
            ...availableSets.entries.map((entry) {
              final isSelected = _selectedSetCode != null &&
                  _selectedSetCode!.toLowerCase() == entry.key.toLowerCase();

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildSetChip(
                  label: entry.value,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedSetCode = entry.key),
                  primary: primary,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.18) : AppTheme.surfaceContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary.withOpacity(0.8) : AppTheme.glassBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndRarityBar(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppTheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar carta por nombre...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Rarity Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRarityPill(null, 'Todas', primary),
                const SizedBox(width: 6),
                _buildRarityPill(Rarity.common, 'Común', AppTheme.rarityCommon),
                const SizedBox(width: 6),
                _buildRarityPill(Rarity.uncommon, 'Infrecuente', AppTheme.rarityUncommon),
                const SizedBox(width: 6),
                _buildRarityPill(Rarity.rare, 'Rara', AppTheme.rarityRare),
                const SizedBox(width: 6),
                _buildRarityPill(Rarity.ultraRare, 'Ultra Rara', AppTheme.rarityUltraRare),
                const SizedBox(width: 6),
                _buildRarityPill(Rarity.secretRare, 'Secreta', AppTheme.raritySecret),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityPill(Rarity? rarity, String label, Color color) {
    final isSelected = _filterRarity == rarity;

    return GestureDetector(
      onTap: () => setState(() => _filterRarity = rarity),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.glassBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rarity != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary, bool hasNoCardsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasNoCardsAtAll ? Icons.auto_stories_rounded : Icons.filter_alt_off_rounded,
              size: 54,
              color: primary.withOpacity(0.35),
            ),
            const SizedBox(height: 14),
            Text(
              hasNoCardsAtAll
                  ? 'Aún no tienes cartas de ${_selectedGame.title}'
                  : 'No se encontraron cartas con esos filtros',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasNoCardsAtAll
                  ? 'Abre sobres gratuitos desde la Bóveda para llenar tu álbum.'
                  : 'Prueba a cambiar de set o seleccionar "Todas" las rarezas.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinderGrid(List<dynamic> items, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.69,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final card = CardModel.fromJson(item['card'] as Map<String, dynamic>);
          final count = item['count'] as int? ?? 1;

          return _buildBinderPocketCard(card, count, primary);
        },
      ),
    );
  }

  Widget _buildBinderPocketCard(CardModel card, int count, Color primary) {
    final Color rarityColor = card.rarity.tier >= 5
        ? AppTheme.raritySecret
        : (card.rarity.tier >= 4
            ? AppTheme.rarityUltraRare
            : (card.rarity.tier >= 3
                ? AppTheme.rarityRare
                : (card.rarity.tier >= 2 ? AppTheme.rarityUncommon : AppTheme.rarityCommon)));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardDetailScreen(card: card, count: count),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.rarity.tier >= 4 ? rarityColor.withOpacity(0.5) : AppTheme.glassBorder,
            width: card.rarity.tier >= 4 ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: card.rarity.tier >= 4 ? rarityColor.withOpacity(0.2) : Colors.black.withOpacity(0.4),
              blurRadius: card.rarity.tier >= 4 ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Card Artwork
              CachedNetworkImage(
                imageUrl: card.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceContainerLow,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceContainerLow,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
              ),

              // Plastic Sleeve Specular Glare (Top Right Corner Sheen)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // Rarity Dot Badge (Top Left)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rarityColor,
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withOpacity(0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

              // Count Badge (Bottom Right, e.g. x2)
              if (count > 1)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F111A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.pokemonColor.withOpacity(0.7), width: 0.8),
                    ),
                    child: Text(
                      'x$count',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.pokemonColor,
                      ),
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
