import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:logger/logger.dart';

class PdfService {
  final Logger _logger = Logger();

  /// Step 1: Teacher picks the PDF from local storage
  Future<File?> pickTextbook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      _logger.e("Error picking file: $e");
    }
    return null;
  }

  /// Step 2: Read PDF Info
  /// Returns the total page count so the app knows the valid range.
  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    try {
      // PDFDoc is the main class in pdf_text
      PDFDoc doc = await PDFDoc.fromFile(file);
      int totalPages = doc.length;

      _logger.i("PDF Loaded. Total pages: $totalPages");

      return [
        {
          'title': "Imported Textbook (Full)",
          'startPage': 1,
          'endPage': totalPages,
        }
      ];
    } catch (e) {
      _logger.e("Error reading PDF info: $e");
      return [];
    }
  }

  /// Step 3: Extract text from specific page range
  Future<String> extractChapterText(
      File file, int startPage, int endPage) async {
    try {
      if (!await file.exists()) return "";

      PDFDoc doc = await PDFDoc.fromFile(file);
      StringBuffer buffer = StringBuffer();
      int totalPages = doc.length;

      // Validate inputs
      if (startPage < 1) startPage = 1;
      if (endPage > totalPages) endPage = totalPages;

      // Loop through pages
      for (int i = startPage; i <= endPage; i++) {
        // pdf_text uses 0-based indexing for pages (0 is Page 1).
        // We use (i - 1) to access the correct page.
        String pageText = await doc.pageAt(i - 1).text;
        buffer.writeln(pageText);
      }

      return buffer.toString();
    } catch (e) {
      _logger.e("Error extracting text: $e");
      return "";
    }
  }
}
