import 'package:flutter/material.dart';

class AiVoiceSessionPanel extends StatelessWidget {
  const AiVoiceSessionPanel({
    super.key,
    required this.isListening,
    required this.transcript,
    this.statusMessage,
  });

  final bool isListening;
  final String transcript;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    if (!isListening &&
        transcript.trim().isEmpty &&
        (statusMessage?.trim().isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final accent = isListening ? const Color(0xFF8AD6C0) : const Color(0xFFD6B872);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isListening ? 'Đang nghe giọng nói' : 'Trạng thái giọng nói',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (statusMessage?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              statusMessage!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.35,
              ),
            ),
          ],
          if (transcript.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Lời đã nghe',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transcript.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.94),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
