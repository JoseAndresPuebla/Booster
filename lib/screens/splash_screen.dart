import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_theme.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/update_service.dart';
import '../widgets/update_dialog_widget.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInit();
  }

  Future<void> _checkInit() async {
    await StorageService.init();
    await SupabaseService.init();

    // Check if user profile already exists
    final profile = StorageService.getUserProfile();

    if (mounted) {
      if (profile != null) {
        // Check updates in background and navigate
        _checkUpdatesAndGo();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUpdatesAndGo() async {
    final updateInfo = await UpdateService.checkForUpdates();
    if (mounted && updateInfo.hasUpdate) {
      _showUpdateDialog(updateInfo);
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo update) {
    UpdateDialogWidget.show(
      context,
      update,
      barrierDismissible: false,
      onDismiss: () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
    );
  }

  Future<void> _handleSaveNickname() async {
    final name = _nicknameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await SupabaseService.syncOrCreateProfile(name);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Glow
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.pokemonColor, AppTheme.riftboundColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.riftboundColor.withOpacity(0.5),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.style_rounded,
                  size: 46,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'BOOSTER TCG',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pokémon • Magic • Riftbound • One Piece • WWE',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 48),

              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.riftboundColor)
              else ...[
                Text(
                  'Elige tu apodo de coleccionista',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ej. MaestroTCG',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.pokemonColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pokemonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _handleSaveNickname,
                    child: Text(
                      'EMPEZAR A COLECCIONAR',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
