import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
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
    // Silent update check after UI settles
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkUpdatesSilently();
    });
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

  Future<void> _checkUpdatesSilently() async {
    final info = await UpdateService.checkForUpdates();
    if (!mounted || !info.hasUpdate) return;
    _showUpdateDialog(info);
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
      _showUpdateDialog(info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Tienes la versión más reciente (v${info.currentVersion})!'),
        ),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppTheme.pokemonColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Actualización v${info.latestVersion}!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu versión actual: v${info.currentVersion}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Novedades:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                info.releaseNotes.isNotEmpty
                    ? info.releaseNotes
                    : 'Nuevas portadas oficiales de sobres, corrección de rarezas y filtros de cartas.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pokemonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (info.apkDownloadUrl != null) {
                UpdateService.launchUpdateUrl(info.apkDownloadUrl!);
              }
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Descargar e Instalar'),
          ),
        ],
      ),
    );
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
    final bool isAdmin = StorageService.isAdminUser();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin ? Colors.purpleAccent.withOpacity(0.5) : AppTheme.cardBorder,
          width: isAdmin ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAdmin
                ? Colors.purpleAccent.withOpacity(0.15)
                : Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isAdmin
                ? Colors.purpleAccent.withOpacity(0.2)
                : AppTheme.riftboundColor.withOpacity(0.2),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
              size: 32,
              color: isAdmin ? Colors.purpleAccent : AppTheme.riftboundColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '¡Hola, $_nickname!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purpleAccent, width: 0.8),
                        ),
                        child: const Text(
                          'TESTER ∞',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
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
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.white54),
            tooltip: 'Cambiar apodo',
            onPressed: _showChangeNicknameDialog,
          ),
        ],
      ),
    );
  }

  void _showChangeNicknameDialog() {
    final controller = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cambiar Nombre de Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu nuevo apodo.\n(Usa "admin01" para activar el modo de sobres ilimitados)',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ej. admin01',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await SupabaseService.syncOrCreateProfile(newName);
                _loadProfileData();
              }
            },
            child: const Text('Guardar'),
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
