import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/photo.dart';
import 'models/album.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PhotoAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlbumAdapter());

  await Hive.openBox<Photo>('photos');
  await Hive.openBox<Album>('albums');

  // Upewnij się, że istnieje album domyślny (ID = 0),
  // do którego trafią stare rekordy bez albumId.
  final albumsBox = Hive.box<Album>('albums');
  if (!albumsBox.containsKey(0)) {
    albumsBox.put(
      0,
      Album(id: 0, name: 'Domyślny', createdAt: DateTime.now()),
    );
  }

  runApp(const AlbumApp());
}

class AlbumApp extends StatelessWidget {
  const AlbumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album fotograficzny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}
