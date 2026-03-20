import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrHelper {
  static Future<Map<String, String>> scanImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return {};
    }

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return _parseText(recognizedText.text);
  }

  static Map<String, String> _parseText(String text) {
    final Map<String, String> result = {};

    // Amount
    final amountRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)');
    final amountMatches = amountRegex.allMatches(text);
    if (amountMatches.isNotEmpty) {
      double maxAmount = 0;
      for (final match in amountMatches) {
        final amount = double.tryParse(match.group(0)!.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
      result['amount'] = maxAmount.toStringAsFixed(0);
    }

    // Date
    final dateRegex = RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      result['date'] = dateMatch.group(0)!;
    }

    // Title and Note
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      result['title'] = lines[0].trim();
      if (lines.length > 1) {
        result['note'] = lines.sublist(1).join(' ').trim();
      }
    }
    
    return result;
  }
}
