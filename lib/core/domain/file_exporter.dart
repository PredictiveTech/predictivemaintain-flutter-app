import 'dart:typed_data';

/// Puerto para entregar un archivo generado al usuario (guardar + compartir).
abstract interface class FileExporter {
  Future<void> saveAndShare({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}
