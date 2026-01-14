import 'dart:io';
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
                child: pw.Text(exam.title.toUpperCase(), style: titleStyle)),
            pw.SizedBox(height: 10),
            pw.Text("Total Marks: 100  |  Time: 2 Hours", style: headerStyle),
            pw.Divider(),
            pw.SizedBox(height: 20),
            ...exam.questions.asMap().entries.map((entry) {
              int index = entry.key + 1;
              var q = entry.value;

              // 1. Detect Type from Tag
              String rawText = q.questionText;
              String type = "General";
              if (rawText.startsWith('[')) {
                int endTag = rawText.indexOf(']');
                if (endTag != -1) {
                  type = rawText.substring(1, endTag); // e.g., "MatchIt"
                  rawText = rawText.substring(endTag + 1).trim();
                }
              }

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                child: _buildPdfQuestion(
                    index, rawText, type, q.options, contentStyle),
              );
            }),
          ];
        },
      ),
    );

    // ... (Answer Key Page Logic remains similar to original, omitted for brevity but recommended) ...

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        "${exam.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${directory.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPdfQuestion(int index, String text, String type,
      dynamic options, pw.TextStyle style) {
    if (type == 'MatchIt') {
      return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text("$index. $text", style: style)),
            pw.Text("_______", style: style), // Blank line for matching
          ]);
    } else if (type == 'Rearrange') {
      List<String> parts = _parseOptions(options);
      return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("$index. Rearrange: ${parts.join(' / ')}", style: style),
            pw.SizedBox(height: 10),
            pw.Container(height: 1, color: PdfColors.black),
          ]);
    } else {
      // Standard MCQ / Text
      List<String> opts = _parseOptions(options);
      return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("$index. $text", style: style),
            if (opts.isNotEmpty)
              ...opts.asMap().entries.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10, top: 2),
                  child: pw.Text(
                      "${String.fromCharCode(65 + e.key)}) ${e.value}",
                      style: style)))
          ]);
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
