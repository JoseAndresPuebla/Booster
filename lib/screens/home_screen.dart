import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../core/services/update_service.dart';
import '../models/game_type.dart';
import '../widgets/daily_timer_badge.dart';
import 'set_selector_screen.dart';
import 'collection_binder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nickname = 'Coleccionista';
  int _totalCards = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      _nickname = profile.nickname;
    }

    int count = 0;
    for (final game in GameType.values) {
      count += StorageService.getTotalCardsCollected(game);
    }

    setState(() {
      _totalCards = count;
    });
  }

  Future<void> _manualCheckUpdates() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buscando actualizaciones en GitHub...'),
        duration: Duration(seconds: 1),
      ),
    );

    final info = await UpdateService.checkForUpdates();
    if (!mounted) return;

    if (info.hasUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Versión ${info.latestVersion} disponible!'),
          action: SnackBarAction(
            label: 'Descargar',
            onPressed: () {
              if (info.apkDownloadUrl != null) {
                UpdateService.launchUpdateUrl(info.apkDownloadUrl!);
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Tienes la versión más reciente!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_rounded, color: AppTheme.pokemonColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'BOOSTER TCG',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Buscar Actualización',
            onPressed: _manualCheckUpdates,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER STATS HEADER
            _buildUserHeader(),

            const SizedBox(height: 28),

            // SECTION TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Elige tu Juego',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollectionBinderScreen(),
                      ),
                    ).then((_) => _loadProfileData());
                  },
                  icon: const Icon(Icons.auto_stories_rounded, size: 16),
                  label: const Text('Mi Álbum'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // GAME CARDS LIST
            ...GameType.values.map((game) => _buildGameCard(game)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.riftboundColor.withOpacity(0.2),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: AppTheme.riftboundColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $_nickname!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.collections_bookmark_rounded,
                        size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalCards cartas en tu colección',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameType game) {
    final cardsCount = StorageService.getTotalCardsCollected(game);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: game.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: game.primaryColor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SetSelectorScreen(game: game),
              ),
            ).then((_) => _loadProfileData());
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: game.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            game.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DailyTimerBadge(game: game),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$cardsCount cartas obtenidas',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'ELEGIR SET',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: game.primaryColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: game.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
