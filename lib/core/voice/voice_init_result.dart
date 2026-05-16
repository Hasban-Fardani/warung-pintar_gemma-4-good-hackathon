/// Result of STT engine initialization (PRD §16.4.1).
///
/// Used by [VoiceServiceImpl] to report readiness.
/// Pure Dart — zero Flutter imports.
sealed class VoiceInitResult {
  const VoiceInitResult();
}

/// STT engine available and id-ID locale present.
final class VoiceInitSuccess extends VoiceInitResult {
  const VoiceInitSuccess();
}

/// STT engine not available on this device.
final class VoiceInitFailed extends VoiceInitResult {
  final String reason;
  const VoiceInitFailed(this.reason);
}

/// STT engine available but id-ID language pack not installed.
final class VoiceInitMissingPack extends VoiceInitResult {
  const VoiceInitMissingPack();
}
