import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PdfExportService {
  Future<File> generateExamPdf(ExamModel exam) async {
    final pdf = pw.Document();

    final titleStyle =
        pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final headerStyle =
        pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final contentStyle = const pw.TextStyle(fontSize: 12);
    final matchColumnStyle =
        pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic);

    String getType(String raw) {
      if (raw.startsWith('[')) {
        int endTag = raw.indexOf(']');
        if (endTag != -1) return raw.substring(1, endTag);
      }
      return "General";
    }

    String cleanText(String raw) {
      if (raw.startsWith('[')) {
        int endTag = raw.indexOf(']');
        if (endTag != -1) return raw.substring(endTag + 1).trim();
      }
      return raw;
    }

    // SEPARATE Logic: Extract all MatchIt questions first
    List<QuestionModel> matchQuestions = [];
    List<QuestionModel> otherQuestions = [];

    for (var q in exam.questions) {
      if (getType(q.questionText) == 'MatchIt') {
        matchQuestions.add(q);
      } else {
        otherQuestions.add(q);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // 1. Header
          widgets.add(pw.Center(
              child: pw.Text(exam.title.toUpperCase(), style: titleStyle)));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Marks: 100", style: headerStyle),
              pw.Text("Time: ${exam.timerMinutes} Minutes", style: headerStyle),
              if (exam.assignedStudents.isNotEmpty)
                pw.Text("Tier: ${exam.difficulty}", style: headerStyle),
            ],
          ));
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 20));

          // 2. Render Standard Questions (MCQ, Fillups, etc.)
          int qIndex = 1;
          for (var q in otherQuestions) {
            String type = getType(q.questionText);
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                child: _buildPdfQuestion(qIndex, cleanText(q.questionText),
                    type, q.options, contentStyle),
              ),
            );
            qIndex++;
          }

          // 3. Render Match The Following (If any)
          if (matchQuestions.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Text("Match the Following:", style: headerStyle));
            widgets.add(pw.SizedBox(height: 10));

            // Prepare columns
            List<String> colA =
                matchQuestions.map((e) => cleanText(e.questionText)).toList();
            List<String> colB =
                matchQuestions.map((e) => e.correctAnswer).toList();
            List<String> jumbledColB = List.from(colB)..shuffle(Random());

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Column A', style: headerStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Column B', style: headerStyle)),
                    ],
                  ),
                  // Table Rows
                  for (int k = 0; k < matchQuestions.length; k++)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("${qIndex + k}. ${colA[k]}",
                                style: contentStyle)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                "(${String.fromCharCode(97 + k)}) ${jumbledColB[k]}",
                                style: matchColumnStyle)),
                      ],
                    ),
                ],
              ),
            );
          }

          return widgets;
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        "${exam.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${directory.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPdfQuestion(int index, String text, String type,
      dynamic options, pw.TextStyle style) {
    // Rearrange Type
    if (type == 'Rearrange') {
      List<String> parts = _parseOptions(options);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$index. Rearrange to form a sentence:", style: style),
          pw.Text("/ ${parts.join(' / ')} /",
              style: style.copyWith(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: PdfColors.black, width: 200),
        ],
      );
    }
    // Standard Types
    else {
      List<String> opts = _parseOptions(options);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$index. $text", style: style),
          if (opts.isNotEmpty)
            ...opts.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 4),
                child: pw.Text("${String.fromCharCode(65 + e.key)}) ${e.value}",
                    style: style))),
          if (opts.isEmpty && (type.contains('Short') || type.contains('Long')))
            pw.SizedBox(height: 50), // Write space
        ],
      );
    }
  }

  List<String> _parseOptions(dynamic options) {
    if (options is List) return options.map((e) => e.toString()).toList();
    if (options is String && options.isNotEmpty) {
      return options
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
    }
    return [];
  }
}
