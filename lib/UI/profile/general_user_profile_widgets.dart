// reusable widgets specific to the general user profile screen.

import 'package:flutter/material.dart';

import '../../models/general_user_profile.dart';
import '../../services/translation_service.dart';

/// renders the follow or follow-back action.
class GeneralFollowButton extends StatelessWidget {
  const GeneralFollowButton({
    super.key,
    required this.relation,
    required this.isBusy,
    required this.onTap,
  });

  final GeneralUserRelation relation;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnfollow =
        relation == GeneralUserRelation.friends ||
        relation == GeneralUserRelation.following;
    final String label = switch (relation) {
      GeneralUserRelation.followsMe => StringRes.at('follow_back'),
      GeneralUserRelation.friends ||
      GeneralUserRelation.following => StringRes.at('unfollow'),
      GeneralUserRelation.notFollowing => StringRes.at('follow'),
    };
    final Color backgroundColor = isUnfollow
        ? const Color.fromARGB(102, 255, 49, 49)
        : const Color.fromARGB(102, 255, 217, 0);
    final Color borderColor = isUnfollow
        ? const Color.fromARGB(179, 255, 49, 49)
        : const Color.fromARGB(179, 255, 217, 0);

    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          isBusy ? '...' : label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
