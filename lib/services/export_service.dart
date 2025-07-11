import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../models/item.dart';
import '../models/transaction.dart' as app_transaction;
import 'database_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormatter = DateFormat('dd/MM/yyyy');
  final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  Future<Uint8List> _generateQRBytes(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(200, 200);

    qrPainter.paint(canvas, size);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(200, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<File> exportItemsToPDF(List<Item> items) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Data Barang',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: 'Tanggal: ${_dateFormatter.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Nama Barang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Kode',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Lokasi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Stok',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Tanggal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...items.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.barcode),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.location),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.currentStock.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_dateFormatter.format(item.dateAdded)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_barang_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> exportItemsToExcelWithQR(List<Item> items) async {
    final excel = Excel.createExcel();
    final sheetObject = excel['Sheet1'];

    // Headers
    sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
      'Nama Barang',
    );
    sheetObject.cell(CellIndex.indexByString("B1")).value = TextCellValue(
      'Barcode',
    );
    sheetObject.cell(CellIndex.indexByString("C1")).value = TextCellValue(
      'Kategori ID',
    );
    sheetObject.cell(CellIndex.indexByString("D1")).value = TextCellValue(
      'Stok',
    );
    sheetObject.cell(CellIndex.indexByString("E1")).value = TextCellValue(
      'Lokasi',
    );
    sheetObject.cell(CellIndex.indexByString("F1")).value = TextCellValue(
      'Deskripsi',
    );
    sheetObject.cell(CellIndex.indexByString("G1")).value = TextCellValue(
      'QR Code',
    );

    // Data
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 2;

      sheetObject.cell(CellIndex.indexByString("A$row")).value = TextCellValue(
        item.name,
      );
      sheetObject.cell(CellIndex.indexByString("B$row")).value = TextCellValue(
        item.barcode,
      );
      sheetObject.cell(CellIndex.indexByString("C$row")).value = IntCellValue(
        item.categoryId,
      );
      sheetObject.cell(CellIndex.indexByString("D$row")).value = IntCellValue(
        item.currentStock,
      );
      sheetObject.cell(CellIndex.indexByString("E$row")).value = TextCellValue(
        item.location,
      );
      sheetObject.cell(CellIndex.indexByString("F$row")).value = TextCellValue(
        item.description ?? '',
      );

      // Put barcode text for QR reference
      sheetObject.cell(CellIndex.indexByString("G$row")).value = TextCellValue(
        item.barcode,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/barang_qr_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    return file;
  }

  Future<File> exportItemsToPDFWithQR(List<Item> items) async {
    final pdf = pw.Document();

    // Generate QR codes for all items
    final qrImages = <String, pw.MemoryImage>{};
    for (final item in items) {
      try {
        final qrBytes = await _generateQRBytes(item.barcode);
        qrImages[item.barcode] = pw.MemoryImage(qrBytes);
      } catch (e) {
        debugPrint('Error generating QR for ${item.barcode}: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Data Barang dengan QR Code',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: 'Tanggal: ${_dateFormatter.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Nama Barang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Barcode',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Kategori ID',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Stok',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Lokasi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Deskripsi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'QR Code',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.barcode),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.categoryId.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.currentStock.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.location),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.description ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: qrImages[item.barcode] != null
                            ? pw.Container(
                                width: 40,
                                height: 40,
                                child: pw.Image(qrImages[item.barcode]!),
                              )
                            : pw.Text(
                                'QR Error',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/barang_qr_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> exportTransactionsToPDF(
    List<app_transaction.Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Transaksi Barang',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: 'Tanggal: ${_dateFormatter.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Tanggal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Jenis',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Jumlah',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Supplier/Penerima',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Catatan',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...transactions.map(
                  (transaction) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_dateFormatter.format(transaction.date)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(transaction.type.displayName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(transaction.quantity.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          transaction.type ==
                                  app_transaction.TransactionType.incoming
                              ? transaction.supplier ?? '-'
                              : transaction.recipient ?? '-',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(transaction.notes ?? '-'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> exportItemsToExcel(List<Item> items) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Data Barang'];

    // Header
    sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
      'Nama Barang',
    );
    sheetObject.cell(CellIndex.indexByString("B1")).value = TextCellValue(
      'Kode',
    );
    sheetObject.cell(CellIndex.indexByString("C1")).value = TextCellValue(
      'Barcode',
    );
    sheetObject.cell(CellIndex.indexByString("D1")).value = TextCellValue(
      'Lokasi',
    );
    sheetObject.cell(CellIndex.indexByString("E1")).value = TextCellValue(
      'Stok',
    );
    sheetObject.cell(CellIndex.indexByString("F1")).value = TextCellValue(
      'Tanggal Ditambah',
    );
    sheetObject.cell(CellIndex.indexByString("G1")).value = TextCellValue(
      'Deskripsi',
    );

    // Data
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 2;

      sheetObject.cell(CellIndex.indexByString("A$row")).value = TextCellValue(
        item.name,
      );
      sheetObject.cell(CellIndex.indexByString("B$row")).value = TextCellValue(
        item.barcode,
      );
      sheetObject.cell(CellIndex.indexByString("C$row")).value = TextCellValue(
        item.barcode,
      );
      sheetObject.cell(CellIndex.indexByString("D$row")).value = TextCellValue(
        item.location,
      );
      sheetObject.cell(CellIndex.indexByString("E$row")).value = IntCellValue(
        item.currentStock,
      );
      sheetObject.cell(CellIndex.indexByString("F$row")).value = TextCellValue(
        _dateFormatter.format(item.dateAdded),
      );
      sheetObject.cell(CellIndex.indexByString("G$row")).value = TextCellValue(
        item.description ?? '',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/data_barang_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    return file;
  }

  Future<File> exportTransactionsToExcel(
    List<app_transaction.Transaction> transactions,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Transaksi'];

    // Header
    sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
      'Tanggal',
    );
    sheetObject.cell(CellIndex.indexByString("B1")).value = TextCellValue(
      'Jenis Transaksi',
    );
    sheetObject.cell(CellIndex.indexByString("C1")).value = TextCellValue(
      'ID Barang',
    );
    sheetObject.cell(CellIndex.indexByString("D1")).value = TextCellValue(
      'Jumlah',
    );
    sheetObject.cell(CellIndex.indexByString("E1")).value = TextCellValue(
      'Supplier',
    );
    sheetObject.cell(CellIndex.indexByString("F1")).value = TextCellValue(
      'Penerima',
    );
    sheetObject.cell(CellIndex.indexByString("G1")).value = TextCellValue(
      'Catatan',
    );

    // Data
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final row = i + 2;

      sheetObject.cell(CellIndex.indexByString("A$row")).value = TextCellValue(
        _dateTimeFormatter.format(transaction.date),
      );
      sheetObject.cell(CellIndex.indexByString("B$row")).value = TextCellValue(
        transaction.type.displayName,
      );
      sheetObject.cell(CellIndex.indexByString("C$row")).value = TextCellValue(
        transaction.itemBarcode,
      );
      sheetObject.cell(CellIndex.indexByString("D$row")).value = IntCellValue(
        transaction.quantity,
      );
      sheetObject.cell(CellIndex.indexByString("E$row")).value = TextCellValue(
        transaction.supplier ?? '',
      );
      sheetObject.cell(CellIndex.indexByString("F$row")).value = TextCellValue(
        transaction.recipient ?? '',
      );
      sheetObject.cell(CellIndex.indexByString("G$row")).value = TextCellValue(
        transaction.notes ?? '',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/transaksi_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    return file;
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  // Database Export/Import Functions
  Future<File> exportDatabase() async {
    try {
      final dbService = DatabaseService();
      final dbPath = await dbService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file tidak ditemukan');
      }

      // Create backup with timestamp
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        '${directory.path}/inventaris_backup_$timestamp.db',
      );

      // Copy database file
      await dbFile.copy(backupFile.path);

      // Create archive with database and additional info
      final archive = Archive();

      // Add database file to archive
      final dbBytes = await backupFile.readAsBytes();
      final dbArchiveFile = ArchiveFile('database.db', dbBytes.length, dbBytes);
      archive.addFile(dbArchiveFile);

      // Add metadata
      final metadata = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'database_version': '1',
      };
      final metadataString = metadata.entries
          .map((e) => '${e.key}=${e.value}')
          .join('\n');
      final metadataBytes = metadataString.codeUnits;
      final metadataArchiveFile = ArchiveFile(
        'metadata.txt',
        metadataBytes.length,
        metadataBytes,
      );
      archive.addFile(metadataArchiveFile);

      // Create final backup file
      final finalBackupFile = File(
        '${directory.path}/inventaris_backup_$timestamp.zip',
      );
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes != null) {
        await finalBackupFile.writeAsBytes(zipBytes);
      }

      // Clean up temporary file
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      return finalBackupFile;
    } catch (e) {
      throw Exception('Gagal export database: $e');
    }
  }

  Future<bool> importDatabase() async {
    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'db'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final pickedFile = result.files.first;
      if (pickedFile.path == null) {
        throw Exception('File path tidak valid');
      }

      final backupFile = File(pickedFile.path!);

      if (!await backupFile.exists()) {
        throw Exception('File backup tidak ditemukan');
      }

      File? dbFileToRestore;

      if (pickedFile.extension?.toLowerCase() == 'zip') {
        // Extract ZIP file
        final backupBytes = await backupFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(backupBytes);

        // Find database file in archive
        final dbArchiveFile = archive.files.firstWhere(
          (file) => file.name == 'database.db',
          orElse: () =>
              throw Exception('Database file tidak ditemukan dalam backup'),
        );

        // Extract database file
        final directory = await getApplicationDocumentsDirectory();
        final tempDbFile = File('${directory.path}/temp_restore.db');
        await tempDbFile.writeAsBytes(dbArchiveFile.content as List<int>);
        dbFileToRestore = tempDbFile;
      } else if (pickedFile.extension?.toLowerCase() == 'db') {
        // Direct database file
        dbFileToRestore = backupFile;
      } else {
        throw Exception('Format file tidak didukung');
      }

      // Verify database file
      if (!await _verifyDatabaseFile(dbFileToRestore)) {
        throw Exception('File database tidak valid atau rusak');
      }

      // Get current database path
      final dbService = DatabaseService();
      final currentDbPath = await dbService.getDatabasePath();
      final currentDbFile = File(currentDbPath);

      // Create backup of current database before replacing
      if (await currentDbFile.exists()) {
        final backupCurrentPath =
            '${currentDbPath}.backup.${DateTime.now().millisecondsSinceEpoch}';
        await currentDbFile.copy(backupCurrentPath);
      }

      // Close current database connection
      await dbService.close();

      // Replace current database with restored one
      await dbFileToRestore.copy(currentDbPath);

      // Clean up temporary file if it was extracted from ZIP
      if (pickedFile.extension?.toLowerCase() == 'zip') {
        await dbFileToRestore.delete();
      }

      // Reinitialize database connection
      await dbService.initDatabase();

      return true;
    } catch (e) {
      throw Exception('Gagal import database: $e');
    }
  }

  Future<bool> _verifyDatabaseFile(File dbFile) async {
    try {
      // Basic verification - check if file exists and has content
      if (!await dbFile.exists()) {
        return false;
      }

      final size = await dbFile.length();
      if (size == 0) {
        return false;
      }

      // Read first few bytes to check SQLite header
      final bytes = await dbFile.openRead(0, 16).toList();
      final headerBytes = bytes.expand((x) => x).toList();

      // SQLite files start with "SQLite format 3\0"
      const sqliteHeader = [
        0x53,
        0x51,
        0x4C,
        0x69,
        0x74,
        0x65,
        0x20,
        0x66,
        0x6F,
        0x72,
        0x6D,
        0x61,
        0x74,
        0x20,
        0x33,
        0x00,
      ];

      if (headerBytes.length < sqliteHeader.length) {
        return false;
      }

      for (int i = 0; i < sqliteHeader.length; i++) {
        if (headerBytes[i] != sqliteHeader[i]) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
