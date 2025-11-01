import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo.dart';
import '../models/album.dart';
import '../utils/file_utils.dart';

class EditPhotoPage extends StatefulWidget {
  final dynamic photoKey;
  final int? defaultAlbumId;

  const EditPhotoPage({super.key, this.photoKey, this.defaultAlbumId});

  @override
  State<EditPhotoPage> createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _pickedImage;
  int? _albumId;

  late final Box<Photo> _photosBox;
  late final Box<Album> _albumsBox;

  @override
  void initState() {
    super.initState();
    _photosBox = Hive.box<Photo>('photos');
    _albumsBox = Hive.box<Album>('albums');

    _albumId = widget.defaultAlbumId ?? _albumsBox.values.first.id;

    if (widget.photoKey != null) {
      final photo = _photosBox.get(widget.photoKey);
      if (photo != null) {
        _titleCtrl.text = photo.title;
        _descCtrl.text = photo.description;
        _albumId = photo.albumId;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_albumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wybierz album')));
      return;
    }

    String imagePath;
    if (_pickedImage != null) {
      imagePath = await FileUtils.saveImageToAppDir(_pickedImage!);
    } else if (widget.photoKey != null) {
      imagePath = _photosBox.get(widget.photoKey)!.imagePath;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wybierz zdjęcie')));
      return;
    }

    final photo = Photo(
      imagePath: imagePath,
      title: _titleCtrl.text.trim().isEmpty ? 'Bez tytułu' : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      createdAt: DateTime.now(),
      albumId: _albumId!,
    );

    if (widget.photoKey == null) {
      await _photosBox.add(photo);
    } else {
      await _photosBox.put(widget.photoKey, photo);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final albums = _albumsBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(title: Text(widget.photoKey == null ? 'Dodaj zdjęcie' : 'Edytuj zdjęcie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _albumId,
            decoration: const InputDecoration(labelText: 'Album'),
            items: [
              for (final a in albums) DropdownMenuItem<int>(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _albumId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Tytuł'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Opis'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          if (_pickedImage != null)
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(_pickedImage!, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('Galeria'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Aparat'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Zapisz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
