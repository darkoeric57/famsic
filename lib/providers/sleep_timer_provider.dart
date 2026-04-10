import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_providers.dart';

class SleepTimerState {
  final Duration? remainingTime;
  final bool isRunning;

  SleepTimerState({this.remainingTime, this.isRunning = false});

  SleepTimerState copyWith({Duration? remainingTime, bool? isRunning}) {
    return SleepTimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return SleepTimerState();
  }

  void setTimer(Duration duration) {
    _timer?.cancel();
    state = SleepTimerState(remainingTime: duration, isRunning: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime == null || state.remainingTime!.inSeconds <= 0) {
        _onTimerEnd();
      } else {
        state = state.copyWith(
          remainingTime: state.remainingTime! - const Duration(seconds: 1),
        );
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    state = SleepTimerState(remainingTime: null, isRunning: false);
  }

  void _onTimerEnd() {
    _timer?.cancel();
    state = SleepTimerState(remainingTime: Duration.zero, isRunning: false);
    
    // Stop playback
    final handler = ref.read(audioHandlerProvider);
    handler.stop();

    // Close app
    SystemNavigator.pop();
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, SleepTimerState>(SleepTimerNotifier.new);
