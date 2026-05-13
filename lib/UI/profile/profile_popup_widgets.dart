// Developed and Designed by Outly • © 2026
// profile_popup_widgets.dart
//
// shared micro-widgets reused across the various profile popups:
//   _PopupDivider              : thin separator line inside popups
//   _PopupTitle                : bold centered heading for popup panels
//   _PopupInput                : pill-shaped text-input field
//   _PasswordVisibilityToggle  : eye icon to show / hide password text
//   _ConfirmCancelRow          : confirm + cancel circle-button pair
//   _SaveDiscardRow            : save + discard circle-button pair (edit profile)
//   _ActionCircle              : generic circular icon button used by both rows
//   _AvatarPicker              : circular photo preview during profile editing

part of 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// popup divider
// ─────────────────────────────────────────────────────────────────────────────

/// thin centered horizontal line used as visual separator inside popups.
class _PopupDivider extends StatelessWidget {
  final double width;

  const _PopupDivider({required this.width});

  @override
  Widget build(BuildContext context) {
    final double w = (width * 0.70).clamp(100.0, width - 32.0);
    return Center(
      child: Container(
        width: w,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// popup title
// ─────────────────────────────────────────────────────────────────────────────

/// bold centered heading displayed at the top of a popup panel.
class _PopupTitle extends StatelessWidget {
  final String text;

  const _PopupTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// popup input
// ─────────────────────────────────────────────────────────────────────────────

/// pill-shaped text input field used inside the profile popup forms.
class _PopupInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int? maxLength;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _PopupInput({
    required this.hint,
    required this.controller,
    this.maxLength,
    this.obscure = false,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        maxLines: 1,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'InstagramSans',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          counterText: '',
          suffixText: maxLength != null
              ? '${controller.text.length}/$maxLength'
              : null,
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// password visibility toggle
// ─────────────────────────────────────────────────────────────────────────────

/// eye icon suffix that toggles password masking on / off.
class _PasswordVisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _PasswordVisibilityToggle({
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white54,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// confirm cancel row
// ─────────────────────────────────────────────────────────────────────────────

/// confirm (green/red) + cancel (red) circle-button pair for destructive flows.
class _ConfirmCancelRow extends StatelessWidget {
  final double s;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool confirmEnabled;
  final Color confirmColor;
  final Color confirmBorder;

  const _ConfirmCancelRow({
    required this.s,
    required this.onConfirm,
    required this.onCancel,
    this.confirmEnabled = true,
    this.confirmColor  = const Color.fromARGB(128, 8, 157, 13),
    this.confirmBorder = const Color.fromARGB(204, 8, 157, 13),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // confirm circle
        _ActionCircle(
          active: confirmEnabled,
          icon: 'assets/icons/profile_page/confirm.png',
          activeColor: confirmColor,
          activeBorder: confirmBorder,
          onTap: confirmEnabled ? onConfirm : () {},
        ),
        SizedBox(width: 28 * s),

        // cancel circle
        _ActionCircle(
          active: true,
          icon: 'assets/icons/profile_page/delete.png',
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: onCancel,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// save discard row
// ─────────────────────────────────────────────────────────────────────────────

/// save (green) + discard (red) circle-button pair for the edit-profile popup.
class _SaveDiscardRow extends StatelessWidget {
  final double s;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final bool isValid;

  const _SaveDiscardRow({
    required this.s,
    required this.onSave,
    required this.onDiscard,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // save circle (active only when form is valid)
        _ActionCircle(
          active: isValid,
          icon: 'assets/icons/profile_page/save.png',
          activeColor: const Color.fromARGB(128, 8, 157, 13),
          activeBorder: const Color.fromARGB(204, 8, 157, 13),
          onTap: isValid ? onSave : () {},
        ),
        SizedBox(width: 28 * s),

        // discard circle
        _ActionCircle(
          active: isValid,
          icon: 'assets/icons/profile_page/delete.png',
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: isValid ? onDiscard : () {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// action circle
// ─────────────────────────────────────────────────────────────────────────────

/// circular icon button; dims itself when not active.
class _ActionCircle extends StatelessWidget {
  final String icon;
  final bool active;
  final Color activeColor;
  final Color activeBorder;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color.fromARGB(128, 0, 0, 0),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? activeBorder : Colors.grey,
            width: 2,
          ),
        ),
        child: ImageIcon(AssetImage(icon), color: Colors.white, size: 30),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// avatar picker
// ─────────────────────────────────────────────────────────────────────────────

/// circular photo preview that shows the new local file or the network photo.
class _AvatarPicker extends StatelessWidget {
  final File? newImage;
  final String networkPhoto;

  const _AvatarPicker({
    required this.newImage,
    required this.networkPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider img = newImage != null
        ? FileImage(newImage!)
        : (networkPhoto.isNotEmpty
                ? NetworkImage(networkPhoto)
                : const AssetImage(
                    'assets/icons/auth/icon_camera_90x90.png'))
            as ImageProvider;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 2),
        image: DecorationImage(image: img, fit: BoxFit.cover),
      ),
    );
  }
}
