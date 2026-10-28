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

          // 2. Division: Sets Filter Header (Collectr style modal)
          _buildSetSelector(availableSets, rawList, primary),

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

  CardSet? _getCardSet(String code) {
    try {
      return _officialSets.firstWhere(
        (s) => s.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildSetSelector(
    Map<String, String> availableSets,
    List<Map<String, dynamic>> rawList,
    Color primary,
  ) {
    if (availableSets.isEmpty) return const SizedBox.shrink();

    final selectedSet = _selectedSetCode != null ? _getCardSet(_selectedSetCode!) : null;
    final selectedSetName = selectedSet?.name ?? availableSets[_selectedSetCode] ?? 'Todos los Sets';
    final hasFilter = _selectedSetCode != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withOpacity(0.85),
        border: const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.8)),
      ),
      child: Row(
        children: [
          // Filter Button (Opens Collectr-style modal)
          Expanded(
            child: InkWell(
              onTap: () => _openSetPickerModal(context, availableSets, rawList, primary),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hasFilter
                      ? primary.withOpacity(0.18)
                      : AppTheme.surfaceContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasFilter ? primary.withOpacity(0.7) : AppTheme.glassBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon or Logo Thumbnail
                    if (selectedSet?.iconUrl != null &&
                        selectedSet!.iconUrl!.isNotEmpty &&
                        !selectedSet.iconUrl!.endsWith('.svg'))
                      Container(
                        width: 38,
                        height: 24,
                        margin: const EdgeInsets.only(right: 10),
                        child: CachedNetworkImage(
                          imageUrl: selectedSet.iconUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(Icons.style_rounded, size: 20, color: primary),
                        ),
                      )
                    else if (selectedSet?.boosterArtUrl != null && selectedSet!.boosterArtUrl!.isNotEmpty)
                      Container(
                        width: 24,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: selectedSet.boosterArtUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(Icons.style_rounded, size: 20, color: primary),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          hasFilter ? Icons.filter_alt_rounded : Icons.layers_rounded,
                          size: 20,
                          color: hasFilter ? primary : AppTheme.textSecondary,
                        ),
                      ),

                    // Label: "EXPANSIÓN" + Set Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasFilter ? 'FILTRANDO POR EXPANSIÓN' : 'EXPANSIÓN',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: hasFilter ? primary : AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            selectedSetName,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Dropdown chevron
                    Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: hasFilter ? primary : AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Clear Button if filter is active
          if (hasFilter) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
              tooltip: 'Mostrar todos los sets',
              onPressed: () => setState(() => _selectedSetCode = null),
            ),
          ],
        ],
      ),
    );
  }

  void _openSetPickerModal(
    BuildContext context,
    Map<String, String> availableSets,
    List<Map<String, dynamic>> rawList,
    Color primary,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String modalSearch = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Count cards collected per set code
            final Map<String, int> collectedCountBySet = {};
            for (final item in rawList) {
              final c = CardModel.fromJson(item['card'] as Map<String, dynamic>);
              final key = c.setCode.toLowerCase();
              collectedCountBySet[key] = (collectedCountBySet[key] ?? 0) + 1;
            }

            // Filter sets by search query
            final entries = availableSets.entries.where((e) {
              if (modalSearch.isEmpty) return true;
              final q = modalSearch.toLowerCase();
              return e.value.toLowerCase().contains(q) || e.key.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppTheme.glassBorder, width: 1.5),
                  left: BorderSide(color: AppTheme.glassBorder, width: 1.5),
                  right: BorderSide(color: AppTheme.glassBorder, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECCIONAR EXPANSIÓN',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${availableSets.length} EXPANSIONES DISPONIBLES',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Modal Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                      onChanged: (val) {
                        setModalState(() {
                          modalSearch = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar expansión por nombre o código (ej. 151, OP-05)...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh.withOpacity(0.7),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sets List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: entries.length + (modalSearch.isEmpty ? 1 : 0),
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        // "Todas las expansiones" tile at the top
                        if (modalSearch.isEmpty && idx == 0) {
                          final isSelected = _selectedSetCode == null;
                          return _buildAllSetsModalTile(
                            isSelected: isSelected,
                            totalCards: rawList.length,
                            primary: primary,
                            onTap: () {
                              setState(() => _selectedSetCode = null);
                              Navigator.pop(ctx);
                            },
                          );
                        }

                        final entryIndex = modalSearch.isEmpty ? idx - 1 : idx;
                        final entry = entries[entryIndex];
                        final setObj = _getCardSet(entry.key);
                        final isSelected = _selectedSetCode != null &&
                            _selectedSetCode!.toLowerCase() == entry.key.toLowerCase();
                        final collected = collectedCountBySet[entry.key.toLowerCase()] ?? 0;

                        return _buildSetModalTile(
                          setEntry: entry,
                          cardSet: setObj,
                          collectedCount: collected,
                          isSelected: isSelected,
                          primary: primary,
                          onTap: () {
                            setState(() => _selectedSetCode = entry.key);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllSetsModalTile({
    required bool isSelected,
    required int totalCards,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.18) : AppTheme.surfaceContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : AppTheme.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? primary.withOpacity(0.25) : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? primary.withOpacity(0.5) : AppTheme.glassBorder),
              ),
              child: Icon(
                Icons.all_inclusive_rounded,
                color: isSelected ? primary : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Todas las expansiones',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Ver todas las cartas conseguidas ($totalCards en total)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSetModalTile({
    required MapEntry<String, String> setEntry,
    required CardSet? cardSet,
    required int collectedCount,
    required bool isSelected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.18) : AppTheme.surfaceContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : AppTheme.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Set Logo / Rótulo Box
            Container(
              width: 56,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: _buildModalSetThumbnail(cardSet, primary),
            ),
            const SizedBox(width: 14),

            // Set Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setEntry.value,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        setEntry.key.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (cardSet?.releaseDate != null && cardSet!.releaseDate!.isNotEmpty) ...[
                        Text(
                          ' • ${cardSet.releaseDate!.split('-').first}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Collected Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: collectedCount > 0
                    ? primary.withOpacity(0.15)
                    : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: collectedCount > 0
                      ? primary.withOpacity(0.4)
                      : AppTheme.glassBorder,
                  width: 0.8,
                ),
              ),
              child: Text(
                collectedCount > 0
                    ? '$collectedCount cartas'
                    : '0',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: collectedCount > 0 ? primary : AppTheme.textMuted,
                ),
              ),
            ),

            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModalSetThumbnail(CardSet? cardSet, Color primary) {
    if (cardSet?.iconUrl != null &&
        cardSet!.iconUrl!.isNotEmpty &&
        !cardSet.iconUrl!.endsWith('.svg')) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: CachedNetworkImage(
          imageUrl: cardSet.iconUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: primary),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackSetLogo(cardSet, primary),
        ),
      );
    } else if (cardSet?.boosterArtUrl != null && cardSet!.boosterArtUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: cardSet.boosterArtUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: primary),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackSetLogo(cardSet, primary),
        ),
      );
    } else {
      return _buildFallbackSetLogo(cardSet, primary);
    }
  }

  Widget _buildFallbackSetLogo(CardSet? cardSet, Color primary) {
    final code = cardSet?.code.toUpperCase() ?? 'TCG';
    return Center(
      child: Text(
        code.length > 5 ? code.substring(0, 5) : code,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: primary,
          letterSpacing: 0.5,
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
