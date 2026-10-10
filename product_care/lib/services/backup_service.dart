import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'product_store.dart';

class BackupService {
  const BackupService();

  Future<File> createBackup(ProductStore store) async {
    final directory = await _backupDirectory();
    await directory.create(recursive: true);
    final now = DateTime.now();
    final stamp =
        '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_'
        '${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}';
    final backup = File('${directory.path}/ProductCare-backup-$stamp.json');
    final temporary = File('${backup.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(store.toJson(includeBackupMetadata: true)),
      flush: true,
    );
    await temporary.rename(backup.path);
    return backup;
  }

  Future<List<File>> listBackups() async {
    final directory = await _backupDirectory();
    if (!await directory.exists()) return [];
    final files = await directory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<ProductCareSnapshot> readBackup(File file) async {
    final allowedDirectory = await _backupDirectory();
    if (file.parent.path != allowedDirectory.path ||
        !file.path.endsWith('.json')) {
      throw const FormatException('That file is not a Product Care backup.');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The backup file is not valid JSON data.');
    }
    return ProductCareSnapshot.fromJson(decoded);
  }

  Future<Directory> _backupDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/ProductCareBackups');
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
