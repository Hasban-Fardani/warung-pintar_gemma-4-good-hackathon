import 'dart:math';
import 'package:flutter/material.dart';
import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';

class WaveformWidget extends StatefulWidget {
  final double soundLevel;
  final bool isListening;
  final int barCount;

  const WaveformWidget({
    super.key,
    this.soundLevel = 0.0,
    this.isListening = false,
    this.barCount = 20,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with TickerProviderStateMixin {
  late List<double> _barHeights;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(widget.barCount, (_) => 0.1);
    _controllers = List.generate(
      widget.barCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 0.5).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isListening) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 30), () {
        if (mounted && widget.isListening) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.value = 0.1;
    }
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _startAnimations();
    } else if (!widget.isListening && oldWidget.isListening) {
      _stopAnimations();
    }

    if (widget.isListening && widget.soundLevel > 0) {
      _updateBarHeights();
    }
  }

  void _updateBarHeights() {
    setState(() {
      final normalizedLevel = (widget.soundLevel / 10.0).clamp(0.0, 1.0);
      for (var i = 0; i < _barHeights.length; i++) {
        final variance = _random.nextDouble() * 0.3;
        _barHeights[i] = (normalizedLevel * 0.8 + variance).clamp(0.1, 1.0);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final baseHeight = widget.isListening ? _barHeights[index] : 0.1;
              final animatedHeight = _animations[index].value * baseHeight;
              return Container(
                width: 4,
                height: 80 * animatedHeight.clamp(0.1, 1.0),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.isListening
                      ? AppColors.primary
                      : AppColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class FakeWaveformWidget extends StatefulWidget {
  final bool isListening;

  const FakeWaveformWidget({
    super.key,
    this.isListening = false,
  });

  @override
  State<FakeWaveformWidget> createState() => _FakeWaveformWidgetState();
}

class _FakeWaveformWidgetState extends State<FakeWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(20, (_) => _random.nextDouble() * 0.5 + 0.1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (index) {
              final baseHeight = widget.isListening ? _barHeights[index] : 0.1;
              final wave = sin((index / 20 * 2 * pi) + (_controller.value * 2 * pi));
              final height = widget.isListening
                  ? (baseHeight + wave * 0.2).clamp(0.1, 1.0)
                  : 0.1;
              return Container(
                width: 4,
                height: 80 * height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.isListening
                      ? AppColors.primary.withValues(alpha: 0.7 + wave * 0.3)
                      : AppColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
