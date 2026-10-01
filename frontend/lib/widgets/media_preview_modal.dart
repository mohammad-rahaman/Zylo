import 'package:flutter/material.dart';

class MediaPreviewModal extends StatelessWidget {
  final String mediaUrl;
  final String title;
  final String? mimeType;

  const MediaPreviewModal({
    super.key,
    required this.mediaUrl,
    required this.title,
    this.mimeType,
  });

  static void show(BuildContext context, {required String mediaUrl, required String title, String? mimeType}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaPreviewModal(
          mediaUrl: mediaUrl,
          title: title,
          mimeType: mimeType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = mimeType == null || mimeType!.startsWith('image/');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $title...')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: isImage
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 64),
                        SizedBox(height: 12),
                        Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                      ],
                    );
                  },
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.white70, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open File'),
                  ),
                ],
              ),
      ),
    );
  }
}
