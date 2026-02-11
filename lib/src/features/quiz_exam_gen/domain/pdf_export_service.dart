import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class PDFExportService {
  Future<String?> exportExamToPDF(ExamModel exam) async {
    try {
      final pdf = pw.Document();

      // Group questions by section
      final sections = _groupBySection(exam.questions);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Center(
                child: pw.Text(
                  'GOVERNMENT SCHOOL EXAMINATION',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  exam.title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Student info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Class: ${exam.metadata?['class'] ?? '___________'}'),
                  pw.Text('Roll No: ___________'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Subject: ${exam.metadata?['subject'] ?? '___________'}'),
                  pw.Text('Date: ___________'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Marks: ${exam.totalMarks}'),
                  pw.Text('Time: ${exam.timerMinutes} minutes'),
                ],
              ),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 15),

              // Instructions
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INSTRUCTIONS:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('• All questions are compulsory'),
                    pw.Text('• Write answers in the space provided'),
                    pw.Text('• Marks are indicated against each question'),
                    pw.Text('• Read questions carefully before answering'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Sections
              ...sections.entries.map((entry) {
                final sectionName = entry.key;
                final questions = entry.value;
                final sectionMarks = _calculateSectionMarks(questions);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Section header
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        '$sectionName ($sectionMarks marks)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // Questions in this section
                    ...questions.asMap().entries.map((qEntry) {
                      int globalNumber = 1;
                      for (var prevSection in sections.entries) {
                        if (prevSection.key == sectionName) {
                          globalNumber += qEntry.key;
                          break;
                        }
                        globalNumber += prevSection.value.length;
                      }

                      return _buildQuestionWidget(globalNumber, qEntry.value);
                    }),

                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ];
          },
        ),
      );

      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File(
          '${output.path}/exam_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      // print('Error exporting PDF: $e');
      return null;
    }
  }

  Map<String, List<QuestionModel>> _groupBySection(
      List<QuestionModel> questions) {
    final Map<String, List<QuestionModel>> sections = {
      'Section A': [],
      'Section B': [],
      'Section C': [],
      'Section D': [],
    };

    for (var question in questions) {
      if (question.type == 'MCQ' ||
          question.type == 'Fill-up' ||
          question.type == 'True/False' ||
          question.type == 'OddOneOut') {
        sections['Section A']!.add(question);
      } else if (question.type == 'Match' || question.type == 'MatchIt') {
        sections['Section B']!.add(question);
      } else if (question.type == 'ShortAns') {
        sections['Section C']!.add(question);
      } else if (question.type == 'LongAns' || question.type == 'CaseStudy') {
        sections['Section D']!.add(question);
      }
    }

    sections.removeWhere((key, value) => value.isEmpty);
    return sections;
  }

  int _calculateSectionMarks(List<QuestionModel> questions) {
    return questions.fold(0, (sum, q) => sum + q.marks);
  }

  pw.Widget _buildQuestionWidget(int number, QuestionModel question) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Question text with marks
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 12),
                    children: [
                      pw.TextSpan(
                        text: '$number. ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: question.questionText),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '[${question.marks} ${question.marks == 1 ? "mark" : "marks"}]',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // ✅ NEW: Image if attached (for exam papers)
          if (question.imagePath != null) ...[
            _buildImageWidget(question.imagePath!),
            pw.SizedBox(height: 8),
          ],

          // Options for MCQ/True-False
          if (question.options.isNotEmpty &&
              (question.type == 'MCQ' ||
                  question.type == 'True/False' ||
                  question.type == 'OddOneOut')) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: question.options.asMap().entries.map((entry) {
                  final letter = String.fromCharCode(97 + entry.key);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text('($letter) ${entry.value}'),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 5),
          ],

          // Answer space
          if (question.type == 'Fill-up' ||
              question.type == 'ShortAns' ||
              question.type == 'LongAns' ||
              question.type == 'CaseStudy') ...[
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Answer:',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 3),
                  ...List.generate(
                    question.type == 'LongAns' || question.type == 'CaseStudy'
                        ? 8
                        : 3,
                    (i) => pw.Text(
                      '_' * 80,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ NEW: Build image widget for PDF
  pw.Widget _buildImageWidget(String imagePath) {
    try {
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        final imageBytes = imageFile.readAsBytesSync();
        final image = pw.MemoryImage(imageBytes);

        return pw.Container(
          margin: const pw.EdgeInsets.only(left: 20, top: 5, bottom: 5),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(image, height: 150, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 5),
              pw.Text(
                '[Refer to the diagram above]',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // print('Error adding image to PDF: $e');
    }

    return pw.SizedBox.shrink();
  }
}
