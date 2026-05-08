// developed and designed by Outly • © 2026
// profile_settings_widgets.dart
//
// visual widgets that compose the settings popup panel:
//   _SettingsSection      : labeled container grouping related settings items
//   _BadgeToggleRow       : switch row to enable / disable the category badge
//   _AccountActionButton  : tappable row button for account-level actions
//   _AccountActions       : pre-styled logout button row

part of 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// settings section
// ─────────────────────────────────────────────────────────────────────────────

/// labeled glass-bordered container that groups related settings items.
class _SettingsSection extends StatelessWidget {
  final String label;
  final String iconPath;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.iconPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(50, 0, 0, 0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // section header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  ImageIcon(
                    AssetImage(iconPath),
                    color: Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // section content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// badge toggle row
// ─────────────────────────────────────────────────────────────────────────────

/// toggle switch row that enables or disables the category badge on the avatar.
class _BadgeToggleRow extends StatelessWidget {
  final double s;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BadgeToggleRow({
    required this.s,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // badge preview icon
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 6, 0, 92),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(128, 0, 10, 218),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: const ImageIcon(
            AssetImage('assets/icons/categories/hang_out.png'),
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(width: 12 * s),

        // label
        Expanded(
          child: Text(
            StringRes.at('category_badge'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // toggle switch
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.white,
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.white24,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// account action button
// ─────────────────────────────────────────────────────────────────────────────

/// generic tappable row button used for account-level actions (change password,
/// delete account, etc.). accepts custom colors for flexible styling.
class _AccountActionButton extends StatelessWidget {
  final double s;
  final String label;
  final String iconPath;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _AccountActionButton({
    required this.s,
    required this.label,
    required this.iconPath,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            ImageIcon(AssetImage(iconPath), color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: .7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// account actions (logout)
// ─────────────────────────────────────────────────────────────────────────────

/// pre-styled logout button row with red accent.
class _AccountActions extends StatelessWidget {
  final double s;
  final VoidCallback onLogout;

  const _AccountActions({required this.s, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(40, 255, 49, 49),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromARGB(100, 255, 49, 49),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const ImageIcon(
              AssetImage('assets/icons/profile_page/logout.png'),
              color: Color(0xFFFF3131),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              StringRes.at('logout'),
              style: const TextStyle(
                color: Color(0xFFFF3131),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
