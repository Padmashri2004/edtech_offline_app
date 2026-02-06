import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ParentProgressPdfService {
  static Future<void> generateAndPrint({
    required String studentName,
    required String studentClass,
    required int quizAverage,
    required int assignmentsSubmitted,
    required int assignmentsTotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(),
              pw.SizedBox(height: 20),
              _studentDetails(studentName, studentClass),
              pw.SizedBox(height: 20),
              _sectionTitle("Academic Performance"),
              pw.SizedBox(height: 10),
              _performanceRow(
                "Quiz Average",
                "$quizAverage%",
                PdfColors.blue,
              ),
              _performanceRow(
                "Assignments",
                "$assignmentsSubmitted / $assignmentsTotal",
                PdfColors.green,
              ),
              pw.SizedBox(height: 20),
              ParentProgressPdfService.overallProgressBar(quizAverage),
              pw.Spacer(),
              _footer(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _header() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Student Progress Report",
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            "EdTech Offline App",
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _studentDetails(String name, String className) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Student Name: $name"),
          pw.SizedBox(height: 4),
          pw.Text("Class & Section: $className"),
          pw.SizedBox(height: 4),
          pw.Text(
              "Report Generated: ${DateTime.now().toLocal().toString().split(' ').first}"),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _performanceRow(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget overallProgressBar(int quizAverage) {
    final double progress = quizAverage / 100;
    const double barWidth = 400; // FIXED width for PDF

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Overall Performance",
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: barWidth,
          height: 12,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Container(
            width: barWidth * progress,
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo,
              borderRadius: pw.BorderRadius.circular(6),
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          "$quizAverage%",
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          "This report is system generated and does not require signature.",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }
}
