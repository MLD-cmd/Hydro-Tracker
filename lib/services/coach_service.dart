import 'package:supabase_flutter/supabase_flutter.dart';

/// A coaching message plus whether it came from the live AI or a local
/// fallback, so the UI can be honest (and the demo never shows an error).
class CoachAdvice {
  const CoachAdvice(this.message, {this.isFallback = false});

  final String message;
  final bool isFallback;
}

/// Calls the `coach` Supabase Edge Function, which asks an LLM (Groq) for a
/// short, personalised hydration tip. The model's API key lives only in that
/// function
/// — never in this app. On any failure (offline, function down, key missing)
/// this returns a sensible local message so the card always has something to
/// show.
class CoachService {
  const CoachService();

  Future<CoachAdvice> fetch({
    required int intakeMl,
    required int goalMl,
    int? tempC,
    String? tempLabel,
    String? place,
    int? streak,
    Map<String, int>? mix,
  }) async {
    try {
      final res = await Supabase.instance.client.functions
          .invoke(
            'coach',
            body: {
              'intakeMl': intakeMl,
              'goalMl': goalMl,
              'hour': DateTime.now().hour,
              'tempC': ?tempC,
              'tempLabel': ?tempLabel,
              'place': ?place,
              'streak': ?streak,
              if (mix != null && mix.isNotEmpty) 'mix': mix,
            },
          )
          .timeout(const Duration(seconds: 12));
      final data = res.data;
      final message = data is Map ? data['message'] as String? : null;
      if (message != null && message.trim().isNotEmpty) {
        return CoachAdvice(message.trim());
      }
    } catch (_) {
      // Fall through to the local fallback below.
    }
    return CoachAdvice(_fallback(intakeMl, goalMl), isFallback: true);
  }

  /// A decent offline tip derived from progress, so the card stays useful even
  /// when the AI can't be reached.
  String _fallback(int intakeMl, int goalMl) {
    if (goalMl <= 0 || intakeMl >= goalMl) {
      return "Goal reached — beautifully hydrated today! 💧";
    }
    final pct = intakeMl / goalMl;
    final remaining = goalMl - intakeMl;
    if (pct == 0) return "A fresh glass now is the easiest way to start strong.";
    if (pct < 0.5) return "Good start — about ${remaining}ml to go. Keep sipping!";
    if (pct < 0.85) return "Over halfway there — a couple more glasses seals it.";
    return "So close — just ${remaining}ml left to hit your goal!";
  }
}
