import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:monekin/core/presentation/responsive/app_breakpoints.dart';

enum BreakpointID { xs, sm, md, lg, xl, xxl }

class BreakPoint extends Equatable {
  final BreakpointID id;

  /// Body maximum width
  final double width;

  const BreakPoint(this.id, {required this.width});

  /// Get the [BreakPoint] that corresponds to the given [width]. Useful to make
  /// decisions based on a locally available width (e.g. `LayoutBuilder`'s
  /// `constraints.maxWidth`) instead of the whole window.
  static BreakPoint fromWidth(double width, {Set<BreakPoint>? breakpoints}) {
    breakpoints ??= appBreakPoints;

    for (int i = breakpoints.length - 1; i >= 0; i--) {
      final breakpoint = breakpoints.elementAt(i);
      if (breakpoint.width <= width) return breakpoint;
    }

    return breakpoints.first;
  }

  /// Get the current BreakPoint based on the device width
  static BreakPoint of(BuildContext context, {Set<BreakPoint>? breakpoints}) {
    return fromWidth(
      MediaQuery.of(context).size.width,
      breakpoints: breakpoints,
    );
  }

  static BreakPoint getById(BreakpointID id) {
    return appBreakPoints.firstWhere((element) => element.id == id);
  }

  bool isSmallerThan(BreakpointID id) {
    return this < BreakPoint.getById(id);
  }

  bool isSmallerOrEqualTo(BreakpointID id) {
    return this <= BreakPoint.getById(id);
  }

  bool isLargerThan(BreakpointID id) {
    return this > BreakPoint.getById(id);
  }

  bool isLargerOrEqualTo(BreakpointID id) {
    return this >= BreakPoint.getById(id);
  }

  bool isBetween(BreakpointID id1, BreakpointID id2) {
    return this >= BreakPoint.getById(id1) && this <= BreakPoint.getById(id2);
  }

  @override
  List<Object?> get props => [id.index];

  bool operator >(BreakPoint other) {
    return id.index > other.id.index;
  }

  bool operator <(BreakPoint other) {
    return id.index < other.id.index;
  }

  bool operator >=(BreakPoint other) {
    return id.index >= other.id.index;
  }

  bool operator <=(BreakPoint other) {
    return id.index <= other.id.index;
  }
}
