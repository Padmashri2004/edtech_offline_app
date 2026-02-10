import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // FIXED: Import for PdfPageFormat and PdfColors
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PDFExportService {
  final Logger _logger = Logger();

  /// Export exam as PDF with proper section structure
  Future<String?> exportExamToPDF(ExamModel exam) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat:
              PdfPageFormat.a4, // FIXED: Direct import from pdf/pdf.dart
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Header
            _buildHeader(exam),
            pw.SizedBox(height: 20),

            // Instructions
            _buildInstructions(),
            pw.SizedBox(height: 20),

            // Questions with Section Headers
            ..._buildQuestionsWithSections(exam),
          ],
        ),
      );

      // Save PDF
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "${exam.title.replaceAll(' ', '_')}_$timestamp.pdf";
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      _logger.i("✅ Exam exported to PDF: $filePath");
      return filePath;
    } catch (e) {
      _logger.e("❌ Failed to export exam to PDF: $e");
      return null;
    }
  }

  /// Build exam header
  pw.Widget _buildHeader(ExamModel exam) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            "GOVERNMENT SCHOOL EXAMINATION",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            exam.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Class: ____________",
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text("Roll No: ____________",
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Subject: ____________",
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text("Date: ____________",
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Total Marks: ${exam.totalMarks}",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text("Time: ${exam.timerMinutes} minutes",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build exam instructions
  pw.Widget _buildInstructions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "INSTRUCTIONS:",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          _buildBulletPoint("All questions are compulsory."),
          _buildBulletPoint(
              "Write your answers in neat and clean handwriting."),
          _buildBulletPoint("Use blue or black pen only."),
          _buildBulletPoint(
              "Calculator use is not permitted unless specified."),
        ],
      ),
    );
  }

  /// Build bullet point for instructions
  pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("• ", style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  /// Build questions with proper section headers
  List<pw.Widget> _buildQuestionsWithSections(ExamModel exam) {
    List<pw.Widget> widgets = [];

    // Group questions by section based on tier
    Map<String, List<QuestionModel>> sections = _groupQuestionsBySections(exam);

    int questionNumber = 1;

    sections.forEach((sectionName, questions) {
      // Section Header
      widgets.add(_buildSectionHeader(sectionName, exam.difficulty));
      widgets.add(pw.SizedBox(height: 10));

      // Questions in this section
      for (var q in questions) {
        widgets.add(_buildQuestion(questionNumber, q));
        widgets.add(pw.SizedBox(height: 15));
        questionNumber++;
      }

      widgets.add(pw.SizedBox(height: 10));
    });

    return widgets;
  }

  /// Group questions into sections based on tier structure
  Map<String, List<QuestionModel>> _groupQuestionsBySections(ExamModel exam) {
    Map<String, List<QuestionModel>> sections = {};

    if (exam.difficulty == "Basic") {
      // Basic Tier: Section A (20) + B (15) + C (35) + D (30)
      sections["Section A (20 marks)"] = [];
      sections["Section B (15 marks)"] = [];
      sections["Section C (35 marks)"] = [];
      sections["Section D (30 marks)"] = [];

      for (var q in exam.questions) {
        if (q.type == 'MCQ' ||
            q.type == 'Fill-up' ||
            q.type == 'OddOneOut' ||
            q.type == 'Rearrange') {
          sections["Section A (20 marks)"]!.add(q);
        } else if (q.type == 'MatchIt') {
          sections["Section B (15 marks)"]!.add(q);
        } else if (q.type == 'ShortAns') {
          sections["Section C (35 marks)"]!.add(q);
        } else if (q.type == 'LongAns') {
          sections["Section D (30 marks)"]!.add(q);
        }
      }
    } else {
      // Advanced Tier: Section A (20) + B (25) + C (5) + D (50)
      sections["Section A (20 marks)"] = [];
      sections["Section B (25 marks)"] = [];
      sections["Section C (5 marks)"] = [];
      sections["Section D (50 marks)"] = [];

      for (var q in exam.questions) {
        if (q.type == 'MCQ' ||
            q.type == 'Fill-up' ||
            q.type == 'True/False' ||
            q.type == 'OddOneOut') {
          sections["Section A (20 marks)"]!.add(q);
        } else if (q.type == 'ShortAns') {
          sections["Section B (25 marks)"]!.add(q);
        } else if (q.type == 'CaseStudy') {
          sections["Section C (5 marks)"]!.add(q);
        } else if (q.type == 'LongAns') {
          sections["Section D (50 marks)"]!.add(q);
        }
      }
    }

    // Remove empty sections
    sections.removeWhere((key, value) => value.isEmpty);

    return sections;
  }

  /// Build section header
  pw.Widget _buildSectionHeader(String sectionName, String tier) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300, // FIXED: Direct import from pdf/pdf.dart
        border: pw.Border.all(width: 1),
      ),
      child: pw.Text(
        sectionName,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Build individual question
  pw.Widget _buildQuestion(int number, QuestionModel q) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Question text with marks
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                "$number. ${q.questionText}",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
              "[${q.marks} marks]",
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Options for MCQ/True-False/OddOneOut
        if (q.options.isNotEmpty &&
            (q.type == 'MCQ' ||
                q.type == 'True/False' ||
                q.type == 'OddOneOut'))
          ...q.options.asMap().entries.map((entry) {
            final optionLetter =
                String.fromCharCode(97 + entry.key); // a, b, c, d
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 3),
              child: pw.Text(
                "($optionLetter) ${entry.value}",
                style: const pw.TextStyle(fontSize: 11),
              ),
            );
          }),

        // Answer space for Fill-up/Short/Long answers
        if (q.type == 'Fill-up' || q.type == 'ShortAns' || q.type == 'LongAns')
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, top: 5),
            child: pw.Column(
              children: [
                pw.Container(
                  height: q.type == 'LongAns' ? 80 : 40,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                          width: 0.5, style: pw.BorderStyle.dashed),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
