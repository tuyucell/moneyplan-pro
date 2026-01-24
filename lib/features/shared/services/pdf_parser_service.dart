import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfParserService {
  static Future<String> extractText(List<int> bytes) async {
    // Load the PDF document
    final document = PdfDocument(inputBytes: bytes);

    // Create the PDF text extractor
    final extractor = PdfTextExtractor(document);

    // Extract all the text from the document
    final text = extractor.extractText();

    // Dispose the document
    document.dispose();

    return text;
  }
}
