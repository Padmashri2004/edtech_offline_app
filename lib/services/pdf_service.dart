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

  /// Step 2: INTELLIGENT CHAPTER SCANNING (Replaces JSON Manifest)
  /// This scans the first 15 pages for a "Table of Contents" structure.
  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    List<Map<String, dynamic>> detectedChapters = [];

    try {
      PDFDoc doc = await PDFDoc.fromFile(file);
      int totalPages = doc.length;
      _logger.i("Scanning PDF structure... Total Pages: $totalPages");

      // Heuristic Scan: Look at the first 15 pages for the ToC
      int scanLimit = totalPages < 15 ? totalPages : 15;

      for (int i = 0; i < scanLimit; i++) {
        String pageText = await doc.pageAt(i).text;
        List<String> lines = pageText.split('\n');

        // Check if this page looks like a "Contents" page
        bool isTocPage = pageText.toLowerCase().contains('content') ||
            pageText.toLowerCase().contains('index');

        if (isTocPage) {
          _logger.i("Potential ToC found on Page ${i + 1}");
          var chaptersOnPage = _parseTocLines(lines, totalPages);
          detectedChapters.addAll(chaptersOnPage);
        }
      }

      // Validation: If scan failed, create a fallback "Full Book" chapter
      if (detectedChapters.isEmpty) {
        _logger.w("Auto-scan failed. defaulting to full textbook.");
        return [
          {
            'chapterNumber': "1",
            'title': "Full Textbook Content",
            'startPage': 1,
            'endPage': totalPages,
            'topics': ["General Concepts", "Key Definitions", "Summary"]
          }
        ];
      }

      // Post-Processing: Fill in 'endPage' logic
      for (int k = 0; k < detectedChapters.length; k++) {
        if (k < detectedChapters.length - 1) {
          detectedChapters[k]['endPage'] =
              detectedChapters[k + 1]['startPage'] - 1;
        } else {
          detectedChapters[k]['endPage'] = totalPages;
        }
      }

      return detectedChapters;
    } catch (e) {
      _logger.e("Error reading PDF structure: $e");
      return [];
    }
  }

  /// Helper: Regex Logic to find lines like "1. Food ......... 5"
  List<Map<String, dynamic>> _parseTocLines(
      List<String> lines, int totalPages) {
    List<Map<String, dynamic>> found = [];
    final RegExp tocRegex =
        RegExp(r'^(\d+|Chapter \d+)[\.\s]+([a-zA-Z\s\-\,]+)[\.\s]+(\d+)$');

    for (String line in lines) {
      line = line.trim();
      final match = tocRegex.firstMatch(line);

      if (match != null) {
        try {
          String rawNum = match.group(1)!;
          String title = match.group(2)!.trim();
          int startPage = int.parse(match.group(3)!);

          if (startPage <= totalPages) {
            found.add({
              'chapterNumber': rawNum,
              'title': title,
              'startPage': startPage,
              'endPage': totalPages,
              'topics': [
                "Introduction",
                "Core Concepts",
                "Examples",
                "Exercises"
              ]
            });
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }
    return found;
  }

  /// Step 3: Extract text from specific page range
  Future<String> extractChapterText(
      File file, int startPage, int endPage) async {
    try {
      if (!await file.exists()) return "";
      PDFDoc doc = await PDFDoc.fromFile(file);
      StringBuffer buffer = StringBuffer();
      int totalPages = doc.length;

      if (startPage < 1) startPage = 1;
      if (endPage > totalPages) endPage = totalPages;

      for (int i = startPage; i <= endPage; i++) {
        String pageText = await doc.pageAt(i - 1).text;
        buffer.writeln(pageText);
      }
      return buffer.toString();
    } catch (e) {
      _logger.e("Error extracting text: $e");
      return "";
    }
  }

  /// Step 4: Secondary Scan for Subtopics
  Future<List<String>> scanChapterSubtopics(
      File file, int startPage, int endPage) async {
    List<String> foundTopics = [];
    try {
      if (!await file.exists()) return [];

      PDFDoc doc = await PDFDoc.fromFile(file);
      int totalPages = doc.length;

      if (startPage < 1) startPage = 1;
      if (endPage > totalPages) endPage = totalPages;

      for (int i = startPage; i <= endPage; i++) {
        String pageText = await doc.pageAt(i - 1).text;
        List<String> lines = pageText.split('\n');

        for (String line in lines) {
          String clean = line.trim();
          if (clean.isEmpty) continue;

          // 1. Numbered Sub-headings (e.g., "1.2 Photosynthesis")
          if (RegExp(r'^\d+\.\d+').hasMatch(clean)) {
            foundTopics.add(clean);
            continue;
          }
          // 2. Alphabetic Sub-headings (e.g., "A. Introduction")
          if (RegExp(r'^[A-Za-z]\.').hasMatch(clean) ||
              RegExp(r'^[a-z]\)').hasMatch(clean)) {
            if (clean.length > 5) foundTopics.add(clean);
            continue;
          }
          // 3. All Caps Headings
          if (clean == clean.toUpperCase() &&
              clean.length > 4 &&
              clean.length < 50) {
            if (!clean.contains("CHAPTER") && !clean.contains("PAGE")) {
              foundTopics.add(clean);
            }
          }
        }
      }

      if (foundTopics.isEmpty) {
        foundTopics = [
          "Key Concepts",
          "Detailed Explanation",
          "Summary",
          "Exercises"
        ];
      }

      return foundTopics.toSet().toList();
    } catch (e) {
      _logger.e("Error scanning subtopics: $e");
      return ["General Topic"];
    }
  }
}
