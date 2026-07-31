import 'package:flutter/material.dart';
import 'package:monekin/core/presentation/app_colors.dart';
import 'package:monekin/core/presentation/styles/borders.dart';
import 'package:monekin/i18n/generated/translations.g.dart';

/// The radius of the `CardWithHeader` widget, a very useful widget through the app
const cardWithHeaderRadius = 20.0;

class CardWithHeader extends StatelessWidget {
  const CardWithHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.bodyPadding = const EdgeInsets.all(0),
    this.footer,
    this.titleBuilder,
    this.onHeaderActionTap,
    this.headerActionLabel,
  });

  final Widget body;
  final Widget? footer;

  final String title;
  final Widget Function(String title)? titleBuilder;
  final String? subtitle;
  final VoidCallback? onHeaderActionTap;
  final String? headerActionLabel;

  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: cardSurfaceDecoration(context, radius: cardWithHeaderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                        child: titleBuilder != null
                            ? titleBuilder!(title)
                            : Text(title),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: AppColors.of(context).textHint),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onHeaderActionTap != null)
                  TextButton.icon(
                    onPressed: onHeaderActionTap,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                    label: Text(headerActionLabel ?? t.ui_actions.see_more),
                  ),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Padding(padding: bodyPadding, child: body),
          ),
          if (footer != null) ...[footer!],
        ],
      ),
    );
  }
}

/// A card footer with a single button, used in the `CardWithHeader` widget.
/// By default, the button has a "see more" text and icon, but both can be customized.
class CardFooterWithSingleButton extends StatelessWidget {
  const CardFooterWithSingleButton({
    super.key,
    this.text,
    this.onButtonClick,
    this.icon,
  });

  final String? text;
  final Widget? icon;
  final VoidCallback? onButtonClick;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    const double indent = 16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, 1),
          child: Divider(
            thickness: 1,
            indent: indent,
            endIndent: indent,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.35),
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: indent,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(),
          ),
          onPressed: onButtonClick,
          icon:
              icon ??
              Transform.rotate(
                angle: -180 * 3.14 / 180,
                child: const Icon(Icons.menu_open),
              ),
          label: Text(text ?? t.ui_actions.see_more),
        ),
      ],
    );
  }
}
