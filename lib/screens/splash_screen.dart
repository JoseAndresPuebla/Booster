import 'package:flutter/material.dart';
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

              const Text(
                'BOOSTER TCG',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pokémon • Magic • Riftbound • One Piece',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white60),
              ),

              const SizedBox(height: 48),

              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.riftboundColor)
              else ...[
                const Text(
                  'Elige tu apodo de coleccionista',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Ej. MaestroTCG',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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
                    child: const Text(
                      'EMPEZAR A COLECCIONAR',
                      style: TextStyle(
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
