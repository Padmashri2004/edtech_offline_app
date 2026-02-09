import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PDFExportService {
  final Logger _logger = Logger();

  /// Export exam as PDF and return file path
  Future<String?> exportExamToPDF(ExamModel exam) async {
    try {
      final pdf = pw.Document();

      // Add exam header
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                exam.title,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Paragraph(
              text: "Difficulty: ${exam.difficulty}\n"
                  "Duration: ${exam.timerMinutes} minutes\n"
                  "Generated: ${exam.timestamp}",
            ),
            pw.Divider(),

            // Questions
            ...exam.questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final q = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "$index. ${q.questionText}",
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Bullet(
                    text: q.options.isNotEmpty
                        ? q.options.join("   ")
                        : "No options provided",
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      );

      // Save PDF to local storage
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${exam.title.replaceAll(' ', '_')}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      _logger.i("✅ Exam exported to PDF: $filePath");
      return filePath;
    } catch (e) {
      _logger.e("❌ Failed to export exam to PDF: $e");
      return null;
    }
  }
}
