import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../models/photo.dart';
import '../utils/file_utils.dart';

class EditPhotoPage extends StatefulWidget {
  final int? photoKey; // jeśli null -> dodawanie, jeśli nie -> edycja

  const EditPhotoPage({super.key, this.photoKey});

  @override
  State<EditPhotoPage> createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.photoKey != null) {
      final box = Hive.box<Photo>('photos');
      final photo = box.get(widget.photoKey)!;
      _imagePath = photo.imagePath;
      _titleCtrl.text = photo.title;
      _descCtrl.text = photo.description;
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
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final savedPath = await FileUtils.saveImageToAppDir(File(picked.path));
    setState(() {
      _imagePath = savedPath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz zdjęcie')),
      );
      return;
    }

    final box = Hive.box<Photo>('photos');
    final photo = Photo(
      imagePath: _imagePath!,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    if (widget.photoKey == null) {
      await box.add(photo);
    } else {
      await box.put(widget.photoKey, photo);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.photoKey != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edytuj zdjęcie' : 'Dodaj zdjęcie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null &&
                          File(_imagePath!).existsSync()
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : const Center(child: Text('Brak zdjęcia')),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Aparat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tytuł',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Podaj tytuł' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Zapisz zmiany' : 'Dodaj'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
