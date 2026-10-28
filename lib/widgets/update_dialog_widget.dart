import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../core/constants/app_theme.dart';
import '../core/services/update_service.dart';

class UpdateDialogWidget extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const UpdateDialogWidget({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, UpdateInfo updateInfo, {bool barrierDismissible = true, VoidCallback? onDismiss}) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => UpdateDialogWidget(
        updateInfo: updateInfo,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _downloadedFilePath;
  bool _isInstallReady = false;

  void _startDownload() async {
    final apkUrl = widget.updateInfo.apkDownloadUrl;
    if (apkUrl == null || apkUrl.isEmpty) {
      setState(() {
        _errorMessage = 'No se encontró el enlace de descarga del APK.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _isInstallReady = false;
    });

    await UpdateService.downloadAndInstallApk(
      url: apkUrl,
      onProgress: (progress, received, total) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = err;
          });
        }
      },
      onComplete: (filePath) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isInstallReady = true;
            _downloadedFilePath = filePath;
          });
        }
      },
    );
  }

  void _reopenInstaller() async {
    if (_downloadedFilePath != null && await File(_downloadedFilePath!).exists()) {
      await OpenFilex.open(
        _downloadedFilePath!,
        type: 'application/vnd.android.package-archive',
      );
    } else {
      _startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.glassBorder, width: 1.5),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.pokemonColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: AppTheme.pokemonColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isDownloading
                  ? 'Descargando...'
                  : (_isInstallReady
                      ? '¡Lista para instalar!'
                      : '¡Actualización v${widget.updateInfo.latestVersion}!'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 10,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.pokemonColor),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toInt()}% completado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                if (_totalBytes > 0)
                  Text(
                    '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Descargando directamente el paquete. En cuanto termine, se abrirá el instalador de Android.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
          ] else if (_isInstallReady) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Descarga completada con éxito.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Se ha invocado el instalador de Android. Pulsa "Actualizar" en el aviso del sistema.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Si es la primera vez, activa el interruptor "Permitir desde esta fuente" en Ajustes.',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Actual: v${widget.updateInfo.currentVersion}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.pokemonColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Nueva: v${widget.updateInfo.latestVersion}',
                    style: const TextStyle(
                      color: AppTheme.pokemonColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Novedades de la versión:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.releaseNotes.isNotEmpty
                      ? widget.updateInfo.releaseNotes
                      : 'Mejoras de rendimiento y corrección de errores.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDismiss?.call();
            },
            child: const Text('Más tarde', style: TextStyle(color: Colors.white54)),
          ),
          if (_isInstallReady)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _reopenInstaller,
              icon: const Icon(Icons.install_mobile_rounded, size: 18),
              label: const Text('Instalar de nuevo'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pokemonColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _startDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                'ACTUALIZAR DIRECTAMENTE',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ],
    );
  }
}
