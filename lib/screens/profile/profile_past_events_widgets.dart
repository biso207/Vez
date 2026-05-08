// developed and designed by Outly • © 2026
// profile_past_events_widgets.dart
//
// widgets that render the archived past-events section:
//   _PastEventsButton       : tappable card tile that opens the events popup
//   _PastEventsPopupHeader  : title + count header inside the events popup
//   _PastEventRow           : single event row with thumbnail, title, date
//   _PastEventFallbackImage : placeholder shown when an event has no photo

part of 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// past events button
// ─────────────────────────────────────────────────────────────────────────────

/// tappable card that shows a label, icon, and event count; opens the popup.
class _PastEventsButton extends StatelessWidget {
  final double s;
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _PastEventsButton({
    required this.s,
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82 * s,
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
        decoration: BoxDecoration(
          color: const Color.fromARGB(50, 0, 0, 0),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white60, width: 2 * s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // label + icon row
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24 * s),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // count badge aligned to bottom-right
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// past events popup header
// ─────────────────────────────────────────────────────────────────────────────

/// header row with a history icon, title, and archived-events count subtitle.
class _PastEventsPopupHeader extends StatelessWidget {
  final String title;
  final int count;

  const _PastEventsPopupHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // history icon circle
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),

        // title + count column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count eventi archiviati',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// past event row
// ─────────────────────────────────────────────────────────────────────────────

/// single archived event row: thumbnail, title, date/place, type badge.
class _PastEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final String date;

  const _PastEventRow({required this.event, required this.date});

  @override
  Widget build(BuildContext context) {
    // extract display fields with safe fallbacks
    final title     = (event['title']    ?? '').toString().trim();
    final type      = (event['type']     ?? '').toString().trim();
    final photo     = (event['bg_photo'] ?? '').toString().trim();
    final place     = event['place'] is Map
        ? Map<String, dynamic>.from(event['place'] as Map)
        : <String, dynamic>{};
    final placeName = (place['name'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white38, width: 1.4),
      ),
      child: Row(
        children: [
          // event thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 76,
              height: 76,
              child: photo.isNotEmpty
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PastEventFallbackImage(type: type),
                    )
                  : Image.asset(
                      'assets/images/bg/default_create_event_bg.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // event info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                Text(
                  title.isEmpty ? 'Evento' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),

                // date + place
                Text(
                  [date, placeName].where((v) => v.isNotEmpty).join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // event type badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      type.isEmpty ? 'Expired' : type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// past event fallback image
// ─────────────────────────────────────────────────────────────────────────────

/// placeholder shown when a network event photo fails to load.
class _PastEventFallbackImage extends StatelessWidget {
  final String type;

  const _PastEventFallbackImage({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          type.toLowerCase() == 'public'
              ? Icons.public_rounded
              : Icons.lock_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
