import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/transaction.dart' as app_transaction;

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormatter = DateFormat('dd/MM/yyyy');
  final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

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
                        child: pw.Text(item.code),
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
        item.code,
      );
      sheetObject.cell(CellIndex.indexByString("C$row")).value = TextCellValue(
        item.barcode ?? '',
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
      sheetObject.cell(CellIndex.indexByString("C$row")).value = IntCellValue(
        transaction.itemId,
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
}
