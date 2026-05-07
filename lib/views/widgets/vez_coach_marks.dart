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

  static Future<bool> showHomeTutorial(BuildContext context) {
    return _showTutorial(context, _homeSteps);
  }

  static Future<bool> showCreateEventTutorial(BuildContext context) {
    return _showTutorial(context, _createEventSteps);
  }

  static Future<bool> showProfileTutorial(BuildContext context) {
    return _showTutorial(context, _profileSteps);
  }

  static Future<bool> _showTutorial(
    BuildContext context,
    List<VezCoachStep> steps,
  ) async {
    final completed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _VezCoachMarksDialog(steps: steps),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    return completed ?? false;
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

  static const List<VezCoachStep> _createEventSteps = [
    VezCoachStep(
      title: 'Crea evento',
      body: 'Qui costruisci la card: immagine, categoria e privacy.',
      icon: Icons.add_circle_rounded,
      targetBuilder: _createCardTarget,
    ),
    VezCoachStep(
      title: 'Info principali',
      body: 'Aggiungi titolo, data, ora, luogo e dettagli in pochi tap.',
      icon: Icons.edit_calendar_rounded,
      targetBuilder: _createInfoTarget,
    ),
    VezCoachStep(
      title: 'Salva',
      body: 'Quando i campi necessari sono pronti, confermi da qui.',
      icon: Icons.check_circle_rounded,
      targetBuilder: _createActionsTarget,
    ),
  ];

  static const List<VezCoachStep> _profileSteps = [
    VezCoachStep(
      title: 'Impostazioni',
      body: 'Lingua, account e preferenze vivono in questo pannello.',
      icon: Icons.settings_rounded,
      targetBuilder: _profileTarget,
    ),
    VezCoachStep(
      title: 'Modifica profilo',
      body: 'Da qui aggiorni foto, username, bio e badge.',
      icon: Icons.edit_rounded,
      targetBuilder: _filterTarget,
    ),
    VezCoachStep(
      title: 'Il tuo spazio',
      body: 'Profilo, statistiche e storico eventi restano raccolti qui.',
      icon: Icons.person_rounded,
      targetBuilder: _profileCardTarget,
    ),
  ];

  static Rect _profileTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    return Rect.fromLTWH(20, padding.top + 24 * s, 45, 45);
  }

  static Rect _searchTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    final top = padding.top + 24 * s;
    final left = 20 + 45 + 12 * s;
    return Rect.fromLTWH(left, top, size.width - (left * 2), 45);
  }

  static Rect _filterTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    return Rect.fromLTWH(size.width - 65, padding.top + 24 * s, 45, 45);
  }

  static Rect _eventCardTarget(Size size, EdgeInsets padding) {
    final width = size.width * 0.85;
    final height = size.height * 0.52;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - size.height * 0.65) / 2,
      width,
      height,
    );
  }

  static Rect _createTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    final navCenterY = size.height - padding.bottom - 48 * s;
    return Rect.fromCenter(
      center: Offset(size.width / 2, navCenterY),
      width: 52 * s,
      height: 52 * s,
    );
  }

  static Rect _createCardTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    final card = _centerCard(size);
    return Rect.fromLTWH(
      card.left + 14 * s,
      card.top + 17 * s,
      102 * s,
      40 * s,
    );
  }

  static Rect _createInfoTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    final card = _centerCard(size);
    return Rect.fromCenter(
      center: Offset(card.center.dx, card.bottom - 154 * s),
      width: card.width - 28 * s,
      height: 160 * s,
    );
  }

  static Rect _createActionsTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    final card = _centerCard(size);
    return Rect.fromCenter(
      center: Offset(size.width / 2, card.bottom - 38 * s),
      width: 154 * s,
      height: 66 * s,
    );
  }

  static Rect _profileCardTarget(Size size, EdgeInsets padding) {
    final s = _scale(size);
    return Rect.fromLTWH(
      20 + 5 * s,
      130 * s,
      size.width - 40 - 10 * s,
      112 * s,
    );
  }

  static double _scale(Size size) {
    return (size.width / 390).clamp(0.8, 1.2).toDouble();
  }

  static Rect _centerCard(Size size) {
    final width = size.width * 0.85;
    final height = size.height * 0.65;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
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
      Navigator.of(context).pop(true);
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
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    final target = _step.targetBuilder(size, padding);
    const tooltipHeight = 178.0;
    const tooltipGap = 18.0;
    final placeBelow =
        target.bottom + tooltipGap + tooltipHeight <=
        size.height - padding.bottom - 12;
    final desiredTop = placeBelow
        ? target.bottom + tooltipGap
        : target.top - tooltipGap - tooltipHeight;
    final tooltipTop = desiredTop.clamp(
      padding.top + 12,
      size.height - padding.bottom - tooltipHeight - 12,
    );

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
            top: tooltipTop.toDouble(),
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
