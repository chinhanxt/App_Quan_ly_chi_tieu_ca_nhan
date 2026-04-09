import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechPermissionState { granted, denied, permanentlyDenied, unavailable }

class SpeechTranscriptUpdate {
  const SpeechTranscriptUpdate({
    required this.transcript,
    required this.isFinal,
    required this.confidence,
  });

  final String transcript;
  final bool isFinal;
  final double confidence;
}

typedef SpeechTranscriptCallback = void Function(SpeechTranscriptUpdate update);
typedef SpeechErrorCallback = void Function(String message);
typedef SpeechStatusCallback = void Function(bool isListening);

class SpeechCaptureService {
  SpeechCaptureService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  bool get isListening => _speechToText.isListening;

  Future<SpeechPermissionState> ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return SpeechPermissionState.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return SpeechPermissionState.permanentlyDenied;
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted) {
      return SpeechPermissionState.granted;
    }
    if (requested.isPermanentlyDenied || requested.isRestricted) {
      return SpeechPermissionState.permanentlyDenied;
    }
    return SpeechPermissionState.denied;
  }

  Future<bool> startListening({
    String localeId = 'vi_VN',
    required SpeechTranscriptCallback onTranscript,
    required SpeechErrorCallback onError,
    SpeechStatusCallback? onStatusChanged,
  }) async {
    final permissionState = await ensureMicrophonePermission();
    if (permissionState != SpeechPermissionState.granted) {
      onError(_permissionMessage(permissionState));
      return false;
    }

    final available = await _speechToText.initialize(
      onError: (error) => onError(error.errorMsg),
      onStatus: (status) {
        final listening = status.toLowerCase() == 'listening';
        onStatusChanged?.call(listening);
      },
    );
    if (!available) {
      onError('Thiết bị chưa sẵn sàng cho nhận giọng nói lúc này.');
      return false;
    }

    await _speechToText.listen(
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      partialResults: true,
      onResult: (SpeechRecognitionResult result) {
        onTranscript(
          SpeechTranscriptUpdate(
            transcript: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        );
      },
    );
    onStatusChanged?.call(true);
    return true;
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }

  String _permissionMessage(SpeechPermissionState state) {
    switch (state) {
      case SpeechPermissionState.denied:
        return 'Bạn cần cấp quyền micro để nhập giao dịch bằng giọng nói.';
      case SpeechPermissionState.permanentlyDenied:
        return 'Quyền micro đang bị chặn. Bạn mở cài đặt ứng dụng để cấp lại giúp mình nhé.';
      case SpeechPermissionState.unavailable:
        return 'Thiết bị chưa hỗ trợ micro hoặc nhận giọng nói.';
      case SpeechPermissionState.granted:
        return '';
    }
  }
}
