import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Step 1: Teacher picks the PDF from local storage
  Future<File?> pickTextbook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Step 2: Read Chapters/Bookmarks from the PDF
  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    List<Map<String, dynamic>> chapters = [];
    
    // Access the internal bookmarks (Table of Contents)
    PdfBookmarkBase bookmarks = document.bookmarks;

    for (int i = 0; i < bookmarks.count; i++) {
      PdfBookmark bookmark = bookmarks[i];
      
      // Get the page index where the chapter starts
      int startPage = document.pages.indexOf(bookmark.destination!.page) + 1;
      
      // Estimate end page (next bookmark's start or end of book)
      int endPage = (i + 1 < bookmarks.count) 
          ? document.pages.indexOf(bookmarks[i + 1].destination!.page)
          : document.pages.count;

      chapters.add({
        'title': bookmark.title,
        'startPage': startPage,
        'endPage': endPage,
      });
    }

    document.dispose();
    return chapters;
  }

  /// Step 3: Extract only the text from a specific chapter (Page Range)
  Future<String> extractChapterText(File file, int startPage, int endPage) async {
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    // Extract text from the specific range selected by the teacher
    PdfTextExtractor extractor = PdfTextExtractor(document);
    String text = extractor.extractText(
      startPageIndex: startPage - 1, 
      endPageIndex: endPage - 1
    );

    document.dispose();
    return text;
  }
}