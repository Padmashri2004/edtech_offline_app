import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/exam_model.dart';

class PdfExportService {
  final Logger _logger = Logger();

  Future<String> generateExamPdf(ExamModel exam) async {
    try {
      _logger.i("📝 Generating PDF for: ${exam.title}");

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildGovHeader(exam),
            pw.SizedBox(height: 10),
            _buildInstructions(exam),
            pw.SizedBox(height: 15),
            ..._buildQuestionsWithHeaders(exam),
          ],
        ),
      );

      String fileName = "${exam.title.replaceAll(' ', '_')}_${exam.difficulty}";
      return await _save(pdf, fileName);
    } catch (e) {
      _logger.e("❌ Export error: $e");
      rethrow;
    }
  }

  Future<String> _save(pw.Document pdf, String fileName) async {
    try {
      Directory? directory;
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }

      final String filePath = '${directory?.path}/$fileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      _logger.i("✅ PDF Saved: $filePath");
      return filePath;
    } catch (e) {
      _logger.e("❌ PDF Save Error: $e");
      rethrow;
    }
  }

  pw.Widget _buildGovHeader(ExamModel exam) {
    // Calculate total marks manually since it's not in the model
    int totalMarks = exam.questions.fold(0, (sum, q) => sum + q.marks);

    return pw.Column(
      children: [
        pw.Text("GOVERNMENT HIGH SCHOOL",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text("Class 6 Science - ${exam.difficulty} Tier",
            style: pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Total Marks: $totalMarks"), // Fixed dynamic calculation
            pw.Text("Time: 3 hours"),
          ],
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  pw.Widget _buildInstructions(ExamModel exam) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Instructions:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text('• All questions are compulsory unless specified.',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('• Write neatly and legibly.',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  List<pw.Widget> _buildQuestionsWithHeaders(ExamModel exam) {
    List<pw.Widget> widgets = [];
    int qCounter = 1;

    for (int i = 0; i < exam.questions.length; i++) {
      var question = exam.questions[i];
      String text = question.questionText;

      // 1. Detect and Extract Section Header
      if (text.startsWith("///SECTION:")) {
        final endIdx = text.indexOf("///", 11);
        if (endIdx != -1) {
          String headerTitle = text.substring(11, endIdx).trim();
          text = text.substring(endIdx + 3).trim();

          widgets.add(pw.Container(
            margin: const pw.EdgeInsets.only(top: 15, bottom: 8),
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Text(
              headerTitle,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ));
        }
      }

      // 2. Build the Question Row
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Q$qCounter. ",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Text(text)),
                  pw.Text("  [${question.marks}]",
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                ],
              ),

              if (question.imagePath != null &&
                  File(question.imagePath!).existsSync())
                pw.Container(
                  height: 120,
                  margin: const pw.EdgeInsets.symmetric(vertical: 5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(pw.MemoryImage(
                      File(question.imagePath!).readAsBytesSync())),
                ),

              if (question.options != null &&
                  (question.options as List).isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5, left: 15),
                  child: pw.Wrap(
                    spacing: 15,
                    runSpacing: 5,
                    children: (question.options as List)
                        .map((o) => pw.Text("• $o",
                            style: const pw.TextStyle(fontSize: 10)))
                        .toList(),
                  ),
                ),

              // Fixed: Replaced Divider with Container for dotted line effect
              if ((question.options == null ||
                  (question.options as List).isEmpty))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20),
                  child: pw.Container(
                    height: 1,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                          style: pw.BorderStyle.dotted, // Correct dotted style
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      qCounter++;
    }
    return widgets;
  }
}
