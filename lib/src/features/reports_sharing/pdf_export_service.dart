import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfExportService {
  Future<void> generateProgressReportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(
            'Student Progress Report',
            style: pw.TextStyle(fontSize: 24),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/progress_report.pdf');

    await file.writeAsBytes(await pdf.save());
  }
}
