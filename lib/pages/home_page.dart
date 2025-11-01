import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/photo.dart';
import '../models/album.dart';
import '../utils/file_utils.dart';
import 'edit_photo_page.dart';
import 'photo_detail_page.dart';

enum PhotoSort { dateDesc, titleAsc }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Box<Photo> photosBox;
  late final Box<Album> albumsBox;

  int? selectedAlbumId; // null = wszystkie
  PhotoSort sort = PhotoSort.dateDesc;
  bool gridView = true;

  @override
  void initState() {
    super.initState();
    photosBox = Hive.box<Photo>('photos');
    albumsBox = Hive.box<Album>('albums');
    selectedAlbumId = albumsBox.isNotEmpty ? albumsBox.values.first.id : 0;
  }

  String get currentAlbumName {
    if (selectedAlbumId == null) return 'Wszystkie zdjęcia';
    final a = albumsBox.values.firstWhere(
          (x) => x.id == selectedAlbumId,
      orElse: () => Album(id: 0, name: 'Domyślny', createdAt: DateTime.now()),
    );
    return a.name;
  }

  Future<int> _createAlbum(String name) async {
    final temp = Album(id: -1, name: name, createdAt: DateTime.now());
    final key = await albumsBox.add(temp);
    await albumsBox.put(key, Album(id: key, name: name, createdAt: temp.createdAt));
    return key;
  }

  Future<void> _addAlbumDialog() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nowy album'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nazwa albumu'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Dodaj')),
        ],
      ),
    );
    if ((name ?? '').isEmpty) return;
    final k = await _createAlbum(name!.trim());
    if (!mounted) return;
    setState(() => selectedAlbumId = k);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dodano album: $name')));
  }

  List<MapEntry<dynamic, Photo>> _filteredSorted(Box<Photo> box, {String query = ''}) {
    final keys = box.keys.toList(growable: false);
    final values = keys.map((k) => box.get(k)!).toList(growable: false);

    final out = <MapEntry<dynamic, Photo>>[];
    for (var i = 0; i < values.length; i++) {
      final p = values[i];
      final inAlbum = (selectedAlbumId == null) || p.albumId == selectedAlbumId;
      final matches = query.isEmpty
          ? true
          : (p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query));
      if (inAlbum && matches) out.add(MapEntry(keys[i], p));
    }

    out.sort((a, b) {
      switch (sort) {
        case PhotoSort.dateDesc:
          return b.value.createdAt.compareTo(a.value.createdAt);
        case PhotoSort.titleAsc:
          return a.value.title.toLowerCase().compareTo(b.value.title.toLowerCase());
      }
    });

    return out;
  }

  Future<void> _showItemMenu(BuildContext context, dynamic key, Photo photo) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edytuj'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Usuń'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditPhotoPage(photoKey: key, defaultAlbumId: selectedAlbumId),
        ),
      );
      setState(() {});
    } else if (choice == 'delete') {
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
        await FileUtils.deleteImageIfExists(photo.imagePath);
        await photosBox.delete(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentAlbumName),
        actions: [
          // WYSZUKIWANIE
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String?>(
                context: context,
                delegate: _PhotoSearchDelegate(
                  source: photosBox,
                  filterAlbumId: selectedAlbumId,
                  sort: sort,
                ),
              );
              if (result != null && mounted) setState(() {});
            },
          ),
          // SORTOWANIE
          PopupMenuButton<String>(
            tooltip: 'Sortuj',
            onSelected: (v) => setState(() {
              sort = (v == 'title') ? PhotoSort.titleAsc : PhotoSort.dateDesc;
            }),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'date', child: Text('Sortuj wg daty (najnowsze)')),
              PopupMenuItem(value: 'title', child: Text('Sortuj wg nazwy (A→Z)')),
            ],
          ),
          // GRID / LIST
          IconButton(
            tooltip: gridView ? 'Widok listy' : 'Widok siatki',
            icon: Icon(gridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => gridView = !gridView),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text('Twoje albumy', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Wszystkie zdjęcia'),
                selected: selectedAlbumId == null,
                onTap: () {
                  setState(() => selectedAlbumId = null);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 0),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: albumsBox.listenable(),
                  builder: (context, Box<Album> box, _) {
                    final albums = box.values.toList()
                      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    if (albums.isEmpty) {
                      return const Center(child: Text('Brak albumów'));
                    }
                    return ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (_, i) {
                        final album = albums[i];
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(album.name, overflow: TextOverflow.ellipsis),
                          selected: selectedAlbumId == album.id,
                          onTap: () {
                            setState(() => selectedAlbumId = album.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addAlbumDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj album'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: photosBox.listenable(),
        builder: (context, Box<Photo> box, _) {
          final items = _filteredSorted(box);

          if (items.isEmpty) {
            return const Center(child: Text('Brak zdjęć'));
          }

          if (!gridView) {
            // LISTA
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final key = items[i].key;
                final p = items[i].value;
                final leading = p.imagePath.startsWith('/')
                    ? Image.file(File(p.imagePath), width: 64, height: 64, fit: BoxFit.cover)
                    : Image.asset(p.imagePath, width: 64, height: 64, fit: BoxFit.cover);
                return ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: leading),
                  title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailPage(photo: p, photoKey: key),
                      ),
                    );
                    if (res == 'refresh') setState(() {});
                  },
                  onLongPress: () => _showItemMenu(context, key, p),
                );
              },
            );
          }

          // SIATKA
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 3 / 4,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final key = items[i].key;
                final photo = items[i].value;

                final imageWidget = photo.imagePath.startsWith('/')
                    ? Image.file(File(photo.imagePath), fit: BoxFit.cover)
                    : Image.asset(photo.imagePath, fit: BoxFit.cover);

                return GestureDetector(
                  onTap: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailPage(photo: photo, photoKey: key),
                      ),
                    );
                    if (res == 'refresh') setState(() {});
                  },
                  onLongPress: () => _showItemMenu(context, key, photo),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(child: imageWidget),
                        ListTile(
                          dense: true,
                          title: Text(photo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(photo.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditPhotoPage(defaultAlbumId: selectedAlbumId),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Wyszukiwarka zdjęć w aktualnym albumie
class _PhotoSearchDelegate extends SearchDelegate<String?> {
  _PhotoSearchDelegate({
    required this.source,
    required this.filterAlbumId,
    required this.sort,
  });

  final Box<Photo> source;
  final int? filterAlbumId;
  final PhotoSort sort;

  List<MapEntry<dynamic, Photo>> _queryItems() {
    final q = query.toLowerCase();
    final keys = source.keys.toList(growable: false);
    final values = keys.map((k) => source.get(k)!).toList(growable: false);
    final out = <MapEntry<dynamic, Photo>>[];
    for (var i = 0; i < values.length; i++) {
      final p = values[i];
      final inAlbum = (filterAlbumId == null) || p.albumId == filterAlbumId;
      final matches = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      if (inAlbum && matches) out.add(MapEntry(keys[i], p));
    }
    out.sort((a, b) {
      switch (sort) {
        case PhotoSort.dateDesc:
          return b.value.createdAt.compareTo(a.value.createdAt);
        case PhotoSort.titleAsc:
          return a.value.title.toLowerCase().compareTo(b.value.title.toLowerCase());
      }
    });
    return out;
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);
  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final items = _queryItems();
    if (items.isEmpty) {
      return const Center(child: Text('Brak wyników'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final p = items[i].value;
        final thumb = p.imagePath.startsWith('/')
            ? Image.file(File(p.imagePath), width: 56, height: 56, fit: BoxFit.cover)
            : Image.asset(p.imagePath, width: 56, height: 56, fit: BoxFit.cover);
        return ListTile(
          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: thumb),
          title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            close(context, p.title);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PhotoDetailPage(photo: p)),
            );
          },
        );
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
}
