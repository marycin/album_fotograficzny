import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/photo.dart';
import '../utils/file_utils.dart';
import 'edit_photo_page.dart';

class PhotoDetailPage extends StatefulWidget {
  final Photo photo;
  final dynamic photoKey;

  const PhotoDetailPage({super.key, required this.photo, this.photoKey});

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  late final Box<Photo> photosBox;

  @override
  void initState() {
    super.initState();
    photosBox = Hive.box<Photo>('photos');
  }

  Future<void> _editPhoto() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPhotoPage(
          photoKey: widget.photoKey,
          defaultAlbumId: widget.photo.albumId,
        ),
      ),
    );
    if (mounted) Navigator.pop(context, 'refresh');
  }

  Future<void> _deletePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć zdjęcie?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (ok == true) {
      await FileUtils.deleteImageIfExists(widget.photo.imagePath);
      await photosBox.delete(widget.photoKey);
      if (mounted) Navigator.pop(context, 'refresh');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final image = photo.imagePath.startsWith('/')
        ? Image.file(File(photo.imagePath), fit: BoxFit.contain)
        : Image.asset(photo.imagePath, fit: BoxFit.contain);

    return Scaffold(
      appBar: AppBar(
        title: Text(photo.title.isEmpty ? 'Szczegóły zdjęcia' : photo.title),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Więcej',
            onSelected: (value) {
              if (value == 'edit') {
                _editPhoto();
              } else if (value == 'delete') {
                _deletePhoto();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edytuj')),
              PopupMenuItem(value: 'delete', child: Text('Usuń')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(child: InteractiveViewer(child: image)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title.isEmpty ? 'Bez tytułu' : photo.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  photo.description.isEmpty ? 'Brak opisu' : photo.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Data: ${photo.createdAt}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
