import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monekin/core/models/date-utils/date_period.dart';
import 'package:monekin/core/models/date-utils/period_type.dart';
import 'package:monekin/core/models/date-utils/periodicity.dart';
import 'package:monekin/core/utils/app_utils.dart';
import 'package:monekin/i18n/generated/translations.g.dart';

/// A quick date-range preset that maps a short label to a [DatePeriod].
class DateRangePreset {
  const DateRangePreset({required this.label, required this.period});

  final String label;
  final DatePeriod period;

  /// Whether the given [datePeriod] corresponds to this preset.
  bool matches(DatePeriod datePeriod) {
    if (datePeriod.periodType != period.periodType) return false;

    return switch (period.periodType) {
      PeriodType.cycle => datePeriod.periodicity == period.periodicity,
      PeriodType.lastDays => datePeriod.lastDays == period.lastDays,
      PeriodType.allTime => true,
      PeriodType.dateRange => false,
    };
  }
}

List<DateRangePreset> _presets(BuildContext context) {
  final t = Translations.of(context);

  return [
    DateRangePreset(
      label: t.home.date_ranges.week,
      period: const DatePeriod.withPeriods(Periodicity.week),
    ),
    DateRangePreset(
      label: t.home.date_ranges.month,
      period: const DatePeriod.withPeriods(Periodicity.month),
    ),
    DateRangePreset(
      label: t.home.date_ranges.quarter,
      period: const DatePeriod.lastDays(90),
    ),
    DateRangePreset(
      label: t.home.date_ranges.half_year,
      period: const DatePeriod.lastDays(180),
    ),
    DateRangePreset(
      label: t.home.date_ranges.year,
      period: const DatePeriod.withPeriods(Periodicity.year),
    ),
    DateRangePreset(
      label: t.home.date_ranges.max,
      period: const DatePeriod.allTime(),
    ),
  ];
}

/// A horizontal, scrollable row of quick date-range chips plus a dashed
/// "custom" chip that opens the full date-period modal.
class DateRangeChips extends StatelessWidget {
  const DateRangeChips({
    super.key,
    required this.currentPeriod,
    required this.onPresetSelected,
    required this.onCustomTap,
    this.foregroundColor,
    this.wrap = false,
    this.shrink = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final DatePeriod currentPeriod;
  final void Function(DatePeriod period) onPresetSelected;
  final VoidCallback onCustomTap;

  /// Base color for labels/borders. Defaults to the theme's onSurface.
  final Color? foregroundColor;

  /// When true, chips flow in a [Wrap] instead of a horizontally scrollable
  /// list. Useful on wide layouts with enough available width.
  final bool wrap;

  /// When true, the chips are laid out in a content-sized [Row]
  /// (`mainAxisSize.min`) with no scrolling. Useful to place them flush at the
  /// end of a wide container. The caller must guarantee there is enough room.
  final bool shrink;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final presets = _presets(context);

    final baseColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    final anyPresetSelected = presets.any((p) => p.matches(currentPeriod));
    final isCustomSelected = !anyPresetSelected;

    final chips = <Widget>[
      for (final preset in presets)
        _Chip(
          label: preset.label,
          selected: preset.matches(currentPeriod),
          baseColor: baseColor,
          accent: accent,
          onTap: () {
            HapticFeedback.selectionClick();
            onPresetSelected(preset.period);
          },
        ),
      _Chip(
        label: t.home.date_ranges.custom,
        selected: isCustomSelected,
        baseColor: baseColor,
        accent: accent,
        icon: Icons.calendar_month_rounded,
        onTap: () {
          HapticFeedback.selectionClick();
          onCustomTap();
        },
      ),
    ];

    if (shrink) {
      return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: chips);
    }

    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        runAlignment: WrapAlignment.start,
        children: chips,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - padding.horizontal,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppUtils.isMobileLayout(context) ? 6 : 8,
              children: chips,
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.baseColor,
    required this.accent,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color baseColor;
  final Color accent;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = selected
        ? accent.withOpacity(0.14)
        : Colors.transparent;

    final Color fgColor = selected ? accent : baseColor.withOpacity(0.5);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 10 : 12,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fgColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
