import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/photo.dart';
import 'edit_photo_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Photo>('photos');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Album fotograficzny'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Photo> photosBox, _) {
          if (photosBox.isEmpty) {
            return const Center(
              child: Text('Brak zdjęć. Naciśnij + aby dodać.'),
            );
          }

          final keys = photosBox.keys.cast<int>().toList().reversed.toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final photo = photosBox.get(key)!;

              return GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditPhotoPage(photoKey: key),
                    ),
                  );
                },
                onLongPress: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Usunąć zdjęcie?'),
                      content: const Text('Tej operacji nie można cofnąć.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Anuluj'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Usuń'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await photosBox.delete(key);
                  }
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: photo.imagePath.isNotEmpty &&
                                File(photo.imagePath).existsSync()
                            ? Image.file(
                                File(photo.imagePath),
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported_outlined,
                                size: 64),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(
                          photo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          photo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditPhotoPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
