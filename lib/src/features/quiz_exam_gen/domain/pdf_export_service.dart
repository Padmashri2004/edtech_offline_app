import 'dart:io';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PdfExportService {
  Future<File> generateExamPdf(ExamModel exam) async {
    final pdf = pw.Document();
    final grouped = _groupQuestions(exam.questions);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _header(exam),
          pw.SizedBox(height: 20),
          _instructions(exam.difficulty),
          pw.Divider(),
          pw.SizedBox(height: 20),
          ..._buildSections(grouped),
        ],
      ),
    );

    return _save(pdf, "${exam.title}_${exam.difficulty}");
  }

  pw.Widget _header(ExamModel exam) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text("GOVERNMENT HIGH SCHOOL",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        pw.SizedBox(height: 5),
        pw.Text(exam.title.toUpperCase(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Duration: ${exam.timerMinutes} Min"),
            pw.Text("Max Marks: 100"),
          ],
        ),
      ],
    );
  }

  pw.Widget _instructions(String diff) {
    return pw.Text(
      diff == 'Basic' ? "Answer all questions." : "Analyze carefully.",
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
    );
  }

  List<pw.Widget> _buildSections(Map<String, List<QuestionModel>> grouped) {
    List<pw.Widget> w = [];
    int sec = 1;

    grouped.forEach((type, qs) {
      if (qs.isEmpty) return;

      String choice = "";
      if (type.contains("Short") || type.contains("Long")) {
        if (qs.length > 5) choice = " (Answer any 5 of ${qs.length})";
      }

      w.add(pw.Container(
        margin: const pw.EdgeInsets.only(top: 15, bottom: 10),
        child: pw.Text(
          "Section ${sec++}: ${_sectionTitle(type)}$choice",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      ));

      if (type == 'MatchIt') {
        w.add(_matchTable(qs));
      } else {
        for (int i = 0; i < qs.length; i++) {
          w.add(_question(qs[i], i + 1));
        }
      }
    });

    return w;
  }

  pw.Widget _question(QuestionModel q, int idx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("$idx. ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Expanded(child: pw.Text(q.questionText)),
              pw.Text("[${q.marks}]", style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          if (q.imagePath != null && File(q.imagePath!).existsSync())
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Container(
                height: 100,
                width: 200,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Image(
                  pw.MemoryImage(File(q.imagePath!).readAsBytesSync()),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          if (q.options is List && (q.options as List).isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5, left: 15),
              child: _mcqOptions(q.options),
            ),
        ],
      ),
    );
  }

  pw.Widget _mcqOptions(List opts) {
    final letters = ['a', 'b', 'c', 'd'];
    return pw.Wrap(
      spacing: 20,
      runSpacing: 5,
      children: List.generate(opts.length, (i) {
        String l = i < 4 ? letters[i] : (i + 1).toString();
        return pw.Text("($l) ${opts[i]}");
      }),
    );
  }

  pw.Widget _matchTable(List<QuestionModel> qs) {
    final colA = qs.map((q) => q.questionText).toList();
    final colB = qs.map((q) => q.correctAnswer).toList();
    colB.shuffle(Random());

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(5), child: pw.Text("No.")),
            pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text("Column A")),
            pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text("Column B")),
          ],
        ),
        for (int i = 0; i < qs.length; i++)
          pw.TableRow(children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text("${i + 1}")),
            pw.Padding(
                padding: const pw.EdgeInsets.all(5), child: pw.Text(colA[i])),
            pw.Padding(
                padding: const pw.EdgeInsets.all(5), child: pw.Text(colB[i])),
          ]),
      ],
    );
  }

  Map<String, List<QuestionModel>> _groupQuestions(List<QuestionModel> all) {
    Map<String, List<QuestionModel>> temp = {};
    for (var q in all) {
      String t = _inferType(q);
      temp.putIfAbsent(t, () => []).add(q);
    }

    final order = [
      'MCQ',
      'Fill-up',
      'True/False',
      'OddOneOut',
      'MatchIt',
      'Rearrange',
      'ShortAns',
      'PictureBased',
      'LongAns'
    ];

    Map<String, List<QuestionModel>> sorted = {};
    for (var t in order) {
      if (temp.containsKey(t)) {
        sorted[t] = temp[t]!;
      }
    }
    return sorted;
  }

  String _inferType(QuestionModel q) {
    if (q.marks == 10) return "LongAns";
    if (q.marks == 5 && q.imagePath != null) return "PictureBased";
    if (q.marks == 5) return "ShortAns";
    if (q.options is List && (q.options as List).isNotEmpty) return "MCQ";
    if (q.questionText.contains("Match")) return "MatchIt";
    return "Fill-up";
  }

  String _sectionTitle(String type) {
    switch (type) {
      case 'MCQ':
        return "Choose the Correct Answer";
      case 'Fill-up':
        return "Fill in the Blanks";
      case 'True/False':
        return "True or False";
      case 'MatchIt':
        return "Match the Following";
      case 'Rearrange':
        return "Rearrange";
      case 'OddOneOut':
        return "Find the Odd One Out";
      case 'ShortAns':
        return "Short Answer Questions";
      case 'PictureBased':
        return "Case Study / Visual Analysis";
      case 'LongAns':
        return "Detailed Answer Questions";
      default:
        return "Miscellaneous";
    }
  }

  Future<File> _save(pw.Document pdf, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
