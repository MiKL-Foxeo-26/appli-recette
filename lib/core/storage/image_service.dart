import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service de gestion des photos de recettes.
/// Gère la sélection, compression et stockage local.
class ImageService {
  ImageService() : _picker = ImagePicker();

  final ImagePicker _picker;

  /// Sélectionne une image depuis la galerie.
  /// Retourne le chemin local compressé, ou null si annulé.
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  /// Sélectionne une image depuis la caméra.
  /// Retourne le chemin local compressé, ou null si annulé.
  Future<String?> pickFromCamera() => _pick(ImageSource.camera);

  Future<String?> _pick(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return null;
    return _compressAndSave(xFile.path);
  }

  /// Taille maximale acceptée pour une photo (500 Ko).
  static const _maxSizeBytes = 500 * 1024;

  /// Compresse l'image à < 500 Ko et la stocke dans le répertoire privé de l'app.
  /// Réduit progressivement la qualité JPEG si le fichier dépasse le seuil.
  Future<String?> _compressAndSave(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'recipe_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final targetPath = p.join(photosDir.path, '${const Uuid().v4()}.jpg');

    // Boucle adaptative : réduit la qualité jusqu'à < 500 Ko
    var quality = 85;
    XFile? result;
    while (quality >= 20) {
      result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (result == null) return null;
      final fileSize = await File(result.path).length();
      if (fileSize <= _maxSizeBytes) return result.path;
      quality -= 10;
    }

    // Dernier recours : retourne le résultat même si > 500Ko
    return result?.path;
  }

  /// Supprime une photo stockée localement.
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
