part of '../create_event_screen.dart';

// event editor card and its small action/detail widgets.
// this file stays visual-only; saving, validation, and navigation remain in the screen state.

class _EventCard extends StatelessWidget {
  final double width, height, rOuter, rInner, s;
  final String bgImage, categoryIcon, typeIcon;
  final TextEditingController titleController;
  final FocusNode titleFocus;

  final String? formattedDate,
      formattedTime,
      locationName,
      description,
      maxGuests,
      price;
  final bool isValid;

  final VoidCallback onPickBackground;
  final VoidCallback onCategoryTap, onTypeTap;
  final VoidCallback onDateTap, onTimeTap, onLocationTap;
  final VoidCallback onDescriptionTap, onMaxGuestsTap, onPriceTap;
  final VoidCallback onSaveTap, onDeleteTap;

  const _EventCard({
    required this.width,
    required this.height,
    required this.rOuter,
    required this.rInner,
    required this.s,
    required this.bgImage,
    required this.categoryIcon,
    required this.typeIcon,
    required this.titleController,
    required this.titleFocus,
    required this.formattedDate,
    required this.formattedTime,
    required this.locationName,
    required this.description,
    required this.maxGuests,
    required this.price,
    required this.isValid,
    required this.onPickBackground,
    required this.onCategoryTap,
    required this.onTypeTap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onLocationTap,
    required this.onDescriptionTap,
    required this.onMaxGuestsTap,
    required this.onPriceTap,
    required this.onSaveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(128, 0, 0, 0),
        borderRadius: BorderRadius.circular(rOuter),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(100, 255, 255, 255), blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(rOuter),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: bgImage.startsWith('http')
                        ? Image.network(bgImage, fit: BoxFit.cover)
                        : bgImage.startsWith('assets')
                        ? Image.asset(bgImage, fit: BoxFit.cover)
                        : Image.file(File(bgImage), fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(80, 0, 0, 0),
                        borderRadius: BorderRadius.circular(rOuter),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14 * s),
            child: Column(
              children: [
                // top row: category + type  |  preview badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _GlassCircleButton(
                          icon: categoryIcon,
                          onTap: onCategoryTap,
                          isBlue: true,
                          s: s,
                        ),
                        SizedBox(width: 12 * s),
                        _GlassCircleButton(
                          icon: typeIcon,
                          onTap: onTypeTap,
                          s: s,
                        ),
                      ],
                    ),
                    _PreviewBadge(label: StringRes.at('preview')),
                  ],
                ),

                const Spacer(),

                _EditBgButton(onTap: onPickBackground, s: s),
                SizedBox(height: 14 * s),

                _InfoGrid(
                  rInner: rInner,
                  s: s,
                  titleController: titleController,
                  titleFocus: titleFocus,
                  formattedDate: formattedDate,
                  formattedTime: formattedTime,
                  locationName: locationName,
                  description: description,
                  maxGuests: maxGuests,
                  price: price,
                  onDateTap: onDateTap,
                  onTimeTap: onTimeTap,
                  onLocationTap: onLocationTap,
                  onDescriptionTap: onDescriptionTap,
                  onMaxGuestsTap: onMaxGuestsTap,
                  onPriceTap: onPriceTap,
                ),

                SizedBox(height: 14 * s),

                _ActionButtons(
                  s: s,
                  isValid: isValid,
                  onSaveTap: onSaveTap,
                  onDeleteTap: onDeleteTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final bool isBlue;
  final double s;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    this.isBlue = false,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = isBlue
        ? const Color.fromARGB(51, 0, 11, 223)
        : const Color.fromARGB(51, 0, 0, 0);
    final Color border = isBlue
        ? const Color.fromARGB(128, 0, 11, 223)
        : const Color.fromARGB(128, 255, 255, 255);

    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: 2),
            ),
            child: ImageIcon(AssetImage(icon), color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;
  const _PreviewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(128, 255, 195, 0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromARGB(204, 255, 195, 0),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditBgButton extends StatelessWidget {
  final VoidCallback onTap;
  final double s;
  const _EditBgButton({required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromARGB(128, 255, 255, 255),
                width: 2,
              ),
            ),
            child: Text(
              StringRes.at('edit_bg'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteEventButton extends StatelessWidget {
  const _DeleteEventButton({required this.onTap, required this.s});

  final VoidCallback onTap;
  final double s;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              color: const Color.fromARGB(70, 255, 49, 49),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color.fromARGB(180, 255, 49, 49),
                width: 2,
              ),
            ),
            child: Text(
              StringRes.at('delete_event'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final double rInner, s;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String? formattedDate,
      formattedTime,
      locationName,
      description,
      maxGuests,
      price;
  final VoidCallback onDateTap, onTimeTap, onLocationTap;
  final VoidCallback onDescriptionTap, onMaxGuestsTap, onPriceTap;

  const _InfoGrid({
    required this.rInner,
    required this.s,
    required this.titleController,
    required this.titleFocus,
    required this.formattedDate,
    required this.formattedTime,
    required this.locationName,
    required this.description,
    required this.maxGuests,
    required this.price,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onLocationTap,
    required this.onDescriptionTap,
    required this.onMaxGuestsTap,
    required this.onPriceTap,
  });

  static const Widget _vDiv = VerticalDivider(
    color: Color.fromARGB(128, 255, 255, 255),
    width: 2,
    thickness: 2,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rInner),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(51, 0, 0, 0),
            borderRadius: BorderRadius.circular(rInner),
            border: Border.all(
              color: const Color.fromARGB(128, 255, 255, 255),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              _TitleField(controller: titleController, focus: titleFocus),
              const Divider(
                color: Color.fromARGB(128, 255, 255, 255),
                height: 2,
                thickness: 2,
              ),

              // row 1: date / time / location / description
              IntrinsicHeight(
                child: Row(
                  children: [
                    _GridCell(
                      label: StringRes.at('date'),
                      icon: 'assets/icons/event/calendar.png',
                      value: formattedDate,
                      onTap: onDateTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('time'),
                      icon: 'assets/icons/event/time.png',
                      value: formattedTime,
                      onTap: onTimeTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('location'),
                      icon: 'assets/icons/event/location.png',
                      value: locationName,
                      onTap: onLocationTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('details'),
                      icon: 'assets/icons/event/description.png',
                      value: description,
                      onTap: onDescriptionTap,
                    ),
                  ],
                ),
              ),

              const Divider(
                color: Color.fromARGB(128, 255, 255, 255),
                height: 2,
                thickness: 2,
              ),

              // row 2: max guests / price
              IntrinsicHeight(
                child: Row(
                  children: [
                    _GridCell(
                      label: StringRes.at('max_guests'),
                      icon: 'assets/icons/event/guests.png',
                      value: maxGuests,
                      onTap: onMaxGuestsTap,
                    ),
                    _vDiv,
                    _GridCell(
                      label: StringRes.at('price'),
                      icon: 'assets/icons/event/price.png',
                      value: price,
                      onTap: onPriceTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  const _TitleField({required this.controller, required this.focus});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: controller,
          focusNode: focus,
          maxLength: 15,
          onChanged: (_) {},
          textAlign: focus.hasFocus ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: StringRes.at('event_title'),
            hintStyle: const TextStyle(color: Colors.white),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.only(
              left: focus.hasFocus ? 18 : 0,
              right: focus.hasFocus ? 72 : 0,
            ),
          ),
        ),
        if (focus.hasFocus)
          Positioned(
            right: 18,
            child: Text(
              '${controller.text.length}/15',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label, icon;
  final String? value;
  final VoidCallback onTap;

  const _GridCell({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageIcon(AssetImage(icon), color: Colors.white, size: 20),
              Text(
                (value != null && value!.isNotEmpty) ? value! : label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final double s;
  final bool isValid;
  final VoidCallback onSaveTap, onDeleteTap;

  const _ActionButtons({
    required this.s,
    required this.isValid,
    required this.onSaveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CardActionCircle(
          icon: 'assets/icons/profile_page/save.png',
          active: isValid,
          activeColor: const Color.fromARGB(128, 8, 157, 13),
          activeBorder: const Color.fromARGB(204, 8, 157, 13),
          onTap: isValid ? onSaveTap : null,
        ),
        SizedBox(width: 28 * s),
        _CardActionCircle(
          icon: 'assets/icons/profile_page/delete.png',
          active: isValid,
          activeColor: const Color.fromARGB(128, 255, 49, 49),
          activeBorder: const Color.fromARGB(204, 255, 49, 49),
          onTap: isValid ? onDeleteTap : null,
        ),
      ],
    );
  }
}

class _CardActionCircle extends StatelessWidget {
  final String icon;
  final bool active;
  final Color activeColor, activeBorder;
  final VoidCallback? onTap;

  const _CardActionCircle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticService.tap();
              onTap!();
            }
          : null,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : const Color.fromARGB(128, 0, 0, 0),
              border: Border.all(
                color: active ? activeBorder : Colors.grey,
                width: 2,
              ),
            ),
            child: ImageIcon(AssetImage(icon), color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
