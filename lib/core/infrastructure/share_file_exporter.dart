import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/file_exporter.dart';

/// Guarda el archivo en el directorio de documentos de la app (path_provider)
/// y abre la hoja de compartir del sistema (share_plus).
class ShareFileExporter implements FileExporter {
  @override
  Future<void> saveAndShare({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimeType)], subject: fileName),
    );
  }
}
