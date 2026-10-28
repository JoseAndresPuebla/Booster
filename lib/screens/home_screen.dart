import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/update_service.dart';
import '../models/game_type.dart';
import '../widgets/daily_timer_badge.dart';
import '../widgets/update_dialog_widget.dart';
import 'set_selector_screen.dart';
import 'collection_binder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nickname = 'Coleccionista';
  int _currentTabIndex = 0;

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
    if (profile != null && mounted) {
      setState(() {
        _nickname = profile.nickname;
      });
    }
  }

  Future<void> _checkUpdatesSilently() async {
    final info = await UpdateService.checkForUpdates();
    if (!mounted || !info.hasUpdate) return;
    _showUpdateDialog(info);
  }

  Future<void> _manualCheckUpdates() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceContainerHigh,
        content: Text(
          'Buscando actualizaciones en GitHub...',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final info = await UpdateService.checkForUpdates();
    if (!mounted) return;

    if (info.hasUpdate) {
      _showUpdateDialog(info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceContainerHigh,
          content: Text(
            '¡Tienes la versión más reciente (v${info.currentVersion})!',
            style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent),
          ),
        ),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    UpdateDialogWidget.show(context, info);
  }

  void _showChangeNicknameDialog() {
    final controller = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa tu nuevo apodo de coleccionista.\n(Usa "admin01" para activar el modo de sobres ilimitados)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ej. admin01',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.pokemonColor),
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pokemonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await SupabaseService.syncOrCreateProfile(newName);
                _loadProfileData();
              }
            },
            child: Text(
              'Guardar',
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = StorageService.isAdminUser();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Ambient Top Spotlight
            Positioned(
              top: -60,
              left: MediaQuery.of(context).size.width / 2 - 140,
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.pokemonColor.withOpacity(0.06),
                ),
              ),
            ),

            // Main Content Area
            Column(
              children: [
                // Top App Bar with Logo & Static Profile Avatar
                _buildTopAppBar(isAdmin),

                // Main Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      110 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.pokemonColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'UNIVERSOS DISPONIBLES',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${GameType.values.length} JUEGOS',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Franchise Cards List
                        ...GameType.values.map((game) => _buildFranchiseCard(game)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Bottom Navigation Bar (Glass Capsule)
            Positioned(
              left: 24,
              right: 24,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _buildFloatingBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.85),
        border: const Border(
          bottom: BorderSide(color: AppTheme.glassBorder, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo Placeholder + Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pokemonColor.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.style_rounded,
                    color: AppTheme.pokemonColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOSTER',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'VAULT HUB',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Action: Sync updates + Profile Avatar Icon
          Row(
            children: [
              if (isAdmin) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.7), width: 1.0),
                  ),
                  child: Text(
                    'TESTER ∞',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.purpleAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 20, color: AppTheme.textSecondary),
                tooltip: 'Buscar Actualización',
                onPressed: _manualCheckUpdates,
              ),
              const SizedBox(width: 4),

              // Profile Avatar with dynamic gradient ring (tap to edit nickname)
              GestureDetector(
                onTap: _showChangeNicknameDialog,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.pokemonColor, Color(0xFF00E5FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.pokemonColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      size: 20,
                      color: isAdmin ? Colors.purpleAccent : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFranchiseCard(GameType game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: game.primaryColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: game.primaryColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
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
                // Game Header: Title + Individual Game Daily Timer Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: game.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            game.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Individual Timer per Game
                    DailyTimerBadge(game: game),
                  ],
                ),

                const SizedBox(height: 18),

                // Card Footer Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: game.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: game.primaryColor.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'EXPLORAR SOBRES',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: game.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: game.primaryColor,
                          ),
                        ],
                      ),
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

  Widget _buildFloatingBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161826).withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Bóveda',
            isSelected: _currentTabIndex == 0,
            onTap: () => setState(() => _currentTabIndex = 0),
          ),
          _buildNavItem(
            icon: Icons.auto_stories_rounded,
            label: 'Mi Álbum',
            isSelected: _currentTabIndex == 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CollectionBinderScreen(),
                ),
              ).then((_) => _loadProfileData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pokemonColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppTheme.pokemonColor.withOpacity(0.5), width: 1.0)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.pokemonColor : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
