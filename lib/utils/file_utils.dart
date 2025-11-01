import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static Future<String> saveImageToAppDir(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName =
        'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFile.path)}';
    final newPath = p.join(photosDir.path, fileName);
    final newFile = await sourceFile.copy(newPath);
    return newFile.path;
  }
}
