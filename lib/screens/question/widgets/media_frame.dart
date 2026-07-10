import 'package:flutter/material.dart';

/// Container for media (image/video/audio) with loading and error states
class MediaFrame extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final BorderRadius? borderRadius;

  const MediaFrame({
    super.key,
    required this.child,
    this.height = 200,
    this.width,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: Colors.grey.shade200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isLoading && !hasError) child,
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (hasError)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage ?? 'Failed to load media',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Overlay widget for media player controls
class MediaOverlay extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayTap;
  final double? opacity;

  const MediaOverlay({
    super.key,
    required this.isPlaying,
    required this.onPlayTap,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: opacity!),
      child: Center(
        child: GestureDetector(
          onTap: onPlayTap,
          child: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Audio player UI container for question audio
class AudioPlayerFrame extends StatelessWidget {
  final String? audioUrl;
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onSeek;
  final Duration? duration;
  final Duration? position;

  const AudioPlayerFrame({
    super.key,
    this.audioUrl,
    this.isLoading = false,
    this.isPlaying = false,
    required this.onPlayPause,
    this.onSeek,
    this.duration,
    this.position,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.audiotrack,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Question',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Listen to the audio and answer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const CircularProgressIndicator()
          else
            IconButton(
              onPressed: onPlayPause,
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 56,
                color: Colors.blue.shade600,
              ),
            ),
          if (duration != null) ...[
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: Colors.blue.shade600,
                inactiveTrackColor: Colors.blue.shade200,
              ),
              child: Slider(
                value: duration != null && duration!.inMilliseconds > 0
                    ? (position?.inMilliseconds ?? 0) / duration!.inMilliseconds
                    : 0.0,
                onChanged: (value) {
                  if (duration != null && onSeek != null) {
                    onSeek!();
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
