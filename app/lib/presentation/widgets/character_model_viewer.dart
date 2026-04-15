import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/character.dart';

/// 3D character model viewer widget using model_viewer_plus.
/// Supports rotation, zoom, and auto-play with fallback for errors.
class CharacterModelViewer extends StatefulWidget {
  final Character character;
  final double? width;
  final double? height;
  final bool autoRotate;
  final bool showControls;
  final Color? backgroundColor;

  const CharacterModelViewer({
    super.key,
    required this.character,
    this.width,
    this.height,
    this.autoRotate = true,
    this.showControls = true,
    this.backgroundColor,
  });

  @override
  State<CharacterModelViewer> createState() => _CharacterModelViewerState();
}

class _CharacterModelViewerState extends State<CharacterModelViewer> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.height ?? 320;

    if (_hasError) {
      return _buildErrorState(effectiveHeight);
    }

    return Container(
      width: widget.width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 3D Model
            ModelViewer(
              src: widget.character.modelPath,
              alt: '${widget.character.name} 3D Model',
              autoRotate: widget.autoRotate,
              autoRotateDelay: 0,
              rotationPerSecond: '30deg',
              cameraControls: widget.showControls,
              disableZoom: false,
              backgroundColor: const Color(0x00000000),
              loading: Loading.eager,
              reveal: Reveal.auto,
              onError: (Object error) {
                if (mounted) {
                  setState(() => _hasError = true);
                }
              },
              onLoad: () {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
            ),

            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.accentGold,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading 3D Model...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Model label badge
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.threed_rotation,
                      color: AppTheme.accentGold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.character.name,
                      style: const TextStyle(
                        color: AppTheme.textGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Element badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.character.element.cn,
                  style: TextStyle(
                    color: _getElementColor(widget.character.element),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double effectiveHeight) {
    return Container(
      width: widget.width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.healthRed.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.healthRed.withOpacity(0.8),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load 3D model',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.character.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.character.modelPath,
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(CharacterElement element) {
    switch (element) {
      case CharacterElement.fire:
        return Colors.orange;
      case CharacterElement.water:
        return Colors.blue;
      case CharacterElement.wind:
        return Colors.teal;
      case CharacterElement.earth:
        return Colors.brown;
      case CharacterElement.thunder:
        return Colors.purple;
      case CharacterElement.dark:
        return Colors.deepPurple;
      case CharacterElement.light:
        return Colors.amber;
      case CharacterElement.neutral:
        return Colors.grey;
    }
  }
}
