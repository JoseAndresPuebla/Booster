import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../models/card_model.dart';
import '../models/game_type.dart';
import 'card_detail_screen.dart';

class CollectionBinderScreen extends StatefulWidget {
  const CollectionBinderScreen({super.key});

  @override
  State<CollectionBinderScreen> createState() => _CollectionBinderScreenState();
}

class _CollectionBinderScreenState extends State<CollectionBinderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Rarity? _filterRarity;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: GameType.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MI ÁLBUM',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.pokemonColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: GameType.values.map((game) {
            final count = StorageService.getTotalCardsCollected(game);
            return Tab(
              text: '${game.title} ($count)',
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar carta...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<Rarity?>(
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filtrar por rareza',
                  onSelected: (rarity) => setState(() => _filterRarity = rarity),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('Todas las rarezas'),
                    ),
                    ...Rarity.values.map(
                      (r) => PopupMenuItem(
                        value: r,
                        child: Text(r.label),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: GameType.values.map((game) {
                return _buildGameGrid(game);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(GameType game) {
    final rawList = StorageService.getLocalCollection(game);

    if (rawList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded,
                size: 60, color: game.primaryColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes cartas de ${game.title}',
              style: const TextStyle(fontSize: 16, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            const Text(
              'Abre tu sobre diario gratuito para empezar a coleccionar',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    // Filter by search & rarity
    final filtered = rawList.where((item) {
      final cardJson = item['card'] as Map<String, dynamic>;
      final card = CardModel.fromJson(cardJson);

      if (_searchQuery.isNotEmpty &&
          !card.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_filterRarity != null && card.rarity != _filterRarity) {
        return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron cartas con esos filtros',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final card = CardModel.fromJson(item['card'] as Map<String, dynamic>);
        final count = item['count'] as int? ?? 1;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: card, count: count),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.surfaceLight,
                    child: Center(
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),

              // Rarity indicator dot
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.rarity.tier >= 4
                        ? Colors.amberAccent
                        : (card.rarity.tier >= 3
                            ? Colors.cyanAccent
                            : Colors.white38),
                  ),
                ),
              ),

              // Count badge (e.g. x2)
              if (count > 1)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amberAccent, width: 0.8),
                    ),
                    child: Text(
                      'x$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
