import 'dart:io';
import 'dart:ui'; // <--- FIXED: Adds Rect and Offset classes
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PdfExportService {
  
  Future<File> generateExamPdf(ExamModel exam) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    final PdfStandardFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfStandardFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfStandardFont optionFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    // Draw Header
    page.graphics.drawString(
      exam.title.toUpperCase(),
      titleFont,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30),
    );

    page.graphics.drawString(
      "Difficulty Level: ${exam.difficulty}  |  Total Questions: ${exam.questions.length}",
      contentFont,
      bounds: Rect.fromLTWH(0, 30, page.getClientSize().width, 20),
    );

    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      const Offset(0, 55),
      Offset(page.getClientSize().width, 55)
    );

    double yOffset = 70; 
    int qIndex = 1;

    for (var question in exam.questions) {
      // Draw Question Text
      // FIXED: Ensure QuestionModel in the next file has 'questionText'
      String qText = "$qIndex. ${question.questionText}";
      
      page.graphics.drawString(
        qText,
        contentFont,
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 40),
        format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top)
      );
      yOffset += 40;

      List<String> options = _parseOptions(question.options);
      
      for (int i = 0; i < options.length; i++) {
        String optionLabel = String.fromCharCode(65 + i); 
        String optText = "   $optionLabel) ${options[i]}";
        
        page.graphics.drawString(
          optText,
          optionFont,
          bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20)
        );
        yOffset += 25;
      }
      
      yOffset += 15; 
      qIndex++;
    }

    final List<int> bytes = await document.save();
    document.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/${exam.title.replaceAll(' ', '_')}_${exam.difficulty}.pdf";
    final File file = File(path);
    await file.writeAsBytes(bytes);

    return file;
  }

  List<String> _parseOptions(dynamic options) {
    if (options is List) {
      return options.map((e) => e.toString()).toList();
    } else if (options is String) {
      return options
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',');
    }
    return [];
  }
}