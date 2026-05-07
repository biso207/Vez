// Developed and Designed by Outly • © 2026
// Reusable in-app tutorial overlay.
//
// This file intentionally keeps the tutorial UI separate from HomePage logic:
// screens only decide *when* to show it, while this widget owns how steps look
// and how the highlighted areas are drawn.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';

class VezCoachStep {
  const VezCoachStep({
    required this.title,
    required this.body,
    required this.targetBuilder,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;

  // The overlay is shown above the whole screen, including navbars. Using a
  // builder keeps each target responsive instead of hard-coding one phone size.
  final Rect Function(Size size, EdgeInsets padding) targetBuilder;
}

class VezCoachMarks {
  const VezCoachMarks._();

  static Future<void> showHomeTutorial(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _VezCoachMarksDialog(steps: _homeSteps),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static const List<VezCoachStep> _homeSteps = [
    VezCoachStep(
      title: 'Il tuo profilo',
      body: 'Da qui apri profilo, impostazioni e storico eventi.',
      icon: Icons.person_rounded,
      targetBuilder: _profileTarget,
    ),
    VezCoachStep(
      title: 'Cerca',
      body: 'Usa la barra per filtrare velocemente eventi e contenuti.',
      icon: Icons.search_rounded,
      targetBuilder: _searchTarget,
    ),
    VezCoachStep(
      title: 'Filtri evento',
      body: 'Cambia vista tra inviti, eventi tuoi e eventi vicini.',
      icon: Icons.tune_rounded,
      targetBuilder: _filterTarget,
    ),
    VezCoachStep(
      title: 'Eventi',
      body: 'La card centrale contiene data, luogo, inviti e azioni rapide.',
      icon: Icons.event_rounded,
      targetBuilder: _eventCardTarget,
    ),
    VezCoachStep(
      title: 'Crea',
      body: 'Tocca il + per creare un nuovo evento quando vuoi.',
      icon: Icons.add_circle_rounded,
      targetBuilder: _createTarget,
    ),
  ];

  static Rect _profileTarget(Size size, EdgeInsets padding) {
    return Rect.fromLTWH(16, padding.top + 18, 56, 56);
  }

  static Rect _searchTarget(Size size, EdgeInsets padding) {
    return Rect.fromLTWH(72, padding.top + 22, size.width - 144, 48);
  }

  static Rect _filterTarget(Size size, EdgeInsets padding) {
    return Rect.fromLTWH(size.width - 72, padding.top + 18, 56, 56);
  }

  static Rect _eventCardTarget(Size size, EdgeInsets padding) {
    final width = size.width * 0.76;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      padding.top + 130,
      width,
      size.height * 0.46,
    );
  }

  static Rect _createTarget(Size size, EdgeInsets padding) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - padding.bottom - 56),
      width: 58,
      height: 58,
    );
  }
}

class _VezCoachMarksDialog extends StatefulWidget {
  const _VezCoachMarksDialog({required this.steps});

  final List<VezCoachStep> steps;

  @override
  State<_VezCoachMarksDialog> createState() => _VezCoachMarksDialogState();
}

class _VezCoachMarksDialogState extends State<_VezCoachMarksDialog> {
  int _index = 0;

  VezCoachStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    HapticService.tap();
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) return;
    HapticService.tap();
    setState(() => _index--);
  }

  void _skip() {
    HapticService.tap();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    final target = _step.targetBuilder(size, padding);
    final tooltipAbove = target.center.dy > size.height * 0.55;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CoachOverlayPainter(target: target)),
          ),
          Positioned.fromRect(
            rect: target.inflate(6),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.white54, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: tooltipAbove ? null : target.bottom + 22,
            bottom: tooltipAbove ? size.height - target.top + 22 : null,
            child: _CoachTooltip(
              step: _step,
              index: _index,
              total: widget.steps.length,
              isLast: _isLast,
              onBack: _back,
              onNext: _next,
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachOverlayPainter extends CustomPainter {
  const _CoachOverlayPainter({required this.target});

  final Rect target;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(target.inflate(6), const Radius.circular(28)),
      );

    // evenOdd makes the second path a transparent "hole" in the dark overlay.
    final path = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .78));
  }

  @override
  bool shouldRepaint(covariant _CoachOverlayPainter oldDelegate) {
    return oldDelegate.target != target;
  }
}

class _CoachTooltip extends StatelessWidget {
  const _CoachTooltip({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final VezCoachStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color.fromARGB(170, 0, 0, 0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white54, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (step.icon != null) ...[
                    Icon(step.icon, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}/$total',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: const Text(
                      'Salta',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const Spacer(),
                  if (index > 0)
                    TextButton(
                      onPressed: onBack,
                      child: const Text(
                        'Indietro',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(isLast ? 'Inizia' : 'Avanti'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
