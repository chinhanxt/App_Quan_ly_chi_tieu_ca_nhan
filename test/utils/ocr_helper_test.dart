import 'package:app/utils/ocr_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OcrHelper.parseRecognizedText', () {
    test('parses bank transfer amount with thousand separator correctly', () {
      const text = '''
BIDV
Giao dịch thành công
93,000 VND
19/03/2026 16:56:18
Đến: TRUONG HOANG Y
Tài khoản: VQRQABEDQ0366
Tại: NHTMCP Quân Đội
Nội dung
NGUYEN CHI NHAN Chuyen tien
Số tham chiếu
020097048803191656172026skoc705359
''';

      final result = OcrHelper.parseRecognizedText(text);

      expect(result['amount'], '93000');
      expect(result['type'], 'debit');
      expect(result['title'], contains('Chuyển tiền'));
      expect(result['date'], '19/03/2026');
    });

    test('parses phone topup amount correctly', () {
      const text = '''
Nạp điện thoại
Giao dịch thành công
Thời gian: 13:00 18/03/2026
Nạp ĐT Viettel 0364295967
50.000 d
''';

      final result = OcrHelper.parseRecognizedText(text);

      expect(result['amount'], '50000');
      expect(result['type'], 'debit');
      expect(result['title'], 'Nạp điện thoại');
      expect(result['date'], '18/03/2026');
    });

    test('prefers amount line over long reference numbers', () {
      const text = '''
Giao dịch thành công
99,000 VND
Số tham chiếu
020097048803191654252026i9jy698194
''';

      final result = OcrHelper.parseRecognizedText(text);

      expect(result['amount'], '99000');
    });
  });
}
