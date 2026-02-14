import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PDFExportService {
  final Logger _logger = Logger();

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
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child:
                              pw.Text('Name: _______________________________'),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Text('Roll No: _______________'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                              'Class: ${exam.metadata?['class'] ?? '_____________'}'),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Text(
                              'Subject: ${exam.metadata?['subject'] ?? '_____________'}'),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Text('Date: _______________'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Marks: ${exam.totalMarks}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Time: ${_formatTime(exam.timerMinutes)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 15),

              // ✅ ENHANCED: Instructions with attempt logic
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
                    pw.Text(
                        '• This paper consists of ${sections.length} sections'),
                    pw.Text(
                        '• All questions in Section A and Section B are compulsory'),
                    pw.Text(
                        '• In Section C and Section D: Answer any 5 out of 7 questions'),
                    pw.Text('• Write answers in the space provided'),
                    pw.Text('• Marks are indicated against each question'),
                    pw.Text('• Read questions carefully before answering'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Sections
              if (exam.questions.isNotEmpty) ...[
                ...sections.entries.map((entry) {
                  final sectionName = entry.key;
                  final questions = entry.value;
                  final sectionMarks = _calculateSectionMarks(questions);

                  // ✅ Add attempt instruction for Sections C & D
                  String attemptNote = '';
                  if (sectionName == 'Section C' ||
                      sectionName == 'Section D') {
                    attemptNote = ' (Attempt any 5 out of 7)';
                  }

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
                          '$sectionName ($sectionMarks marks)$attemptNote',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Questions
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
              ] else ...[
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Text(
                      '⚠️ No questions generated yet',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ];
          },
        ),
      );

      // Save to Downloads
      final filePath = await _saveToDownloads(pdf, exam.title);
      return filePath;
    } catch (e) {
      _logger.e('Error exporting PDF: $e');
      return null;
    }
  }

  // Format time correctly
  String _formatTime(int minutes) {
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? "hour" : "hours"}';
      } else {
        return '$hours hrs $mins mins';
      }
    }
    return '$minutes minutes';
  }

  // ✅ Save to Downloads folder
  Future<String?> _saveToDownloads(pw.Document pdf, String examTitle) async {
    try {
      String downloadsPath;

      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            _logger.w('Storage permission denied');
            return null;
          }
        }

        downloadsPath = '/storage/emulated/0/Download';

        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          final externalDir = await getExternalStorageDirectory();
          downloadsPath = externalDir?.path ?? '/storage/emulated/0/Download';
        }
      } else if (Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        downloadsPath = docDir.path;
      } else {
        final docDir = await getDownloadsDirectory();
        downloadsPath =
            docDir?.path ?? (await getApplicationDocumentsDirectory()).path;
      }

      // Clean filename
      String cleanTitle = examTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .substring(0, examTitle.length > 50 ? 50 : examTitle.length);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${cleanTitle}_$timestamp.pdf';
      final filePath = '$downloadsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      _logger.i('✅ PDF saved to: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('❌ Error saving to Downloads: $e');

      // Fallback
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${appDir.path}/exam_$timestamp.pdf');
        await file.writeAsBytes(await pdf.save());
        _logger.w('⚠️ Saved to app directory: ${file.path}');
        return file.path;
      } catch (e2) {
        _logger.e('❌ Fallback failed: $e2');
        return null;
      }
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
          if (question.imagePath != null) ...[
            _buildImageWidget(question.imagePath!),
            pw.SizedBox(height: 8),
          ],
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
      _logger.w('Image not found: $imagePath');
    }
    return pw.SizedBox.shrink();
  }
}
