import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A generic ListView that supports item snapping, dimming non-focused items, and dynamic item heights.
/// [T] is the type of the list item data.
class SnapList<T> extends StatefulWidget {
  /// Constructor
  const SnapList({
    required this.itemBuilder,
    required this.items,
    this.initialIndex = 0,
    this.itemScrollController,
    this.snapAnimationDuration = const Duration(milliseconds: 500),
    this.minScale = 0.95,
    this.maxScale = 1.0,
    this.minOpacity = 0.4,
    this.maxOpacity = 1.0,
    this.repaintThrottleDuration = const Duration(milliseconds: 50),
    this.initialAlignment = 0.5,
    this.padding = EdgeInsets.zero,
    this.physics = const SnappingScrollPhysics(), // Default physics
    this.topOverlayHeight = 0.0,
    this.bottomOverlayHeight = 0.0,
    this.onCurrentItemChanged,
    this.spacing = 24,
    super.key,
  });

  /// Callback to build the widget for each item in the list.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Optional external controller for scrolling the list programmatically.
  final ItemScrollController? itemScrollController;

  /// How long the snapping animation should take.
  final Duration snapAnimationDuration;

  /// Minimum scale for unfocused items (default 0.9).
  final double minScale;

  /// Maximum scale for focused (centered) item (default 1.0).
  final double maxScale;

  /// Minimum opacity for unfocused items (default 0.8).
  final double minOpacity;

  /// Maximum opacity for focused (centered) item (default 1.0).
  final double maxOpacity;

  /// How long to throttle UI rebuilds when the scroll position changes.
  final Duration repaintThrottleDuration;

  /// Initial alignment for the first item displayed (0.0 = top, 0.5 = center, 1.0 = bottom).
  final double initialAlignment;

  /// Optional padding around the entire list view.
  final EdgeInsets padding;

  /// The physics of the scroll view.
  final ScrollPhysics? physics;

  /// The height in pixels of the overlay at the top (e.g., app bar, status bar, safe area).
  final double topOverlayHeight;

  /// The height in pixels of the overlay at the bottom (e.g., bottom bar, safe area).
  final double bottomOverlayHeight;

  final ValueChanged<int>? onCurrentItemChanged;

  final List<T> items;

  final int initialIndex;

  final double spacing;

  @override
  State<SnapList<T>> createState() => _SnapListState<T>();
}

//----------------------------------------------------------------------------//
// State Class for the Widget
//----------------------------------------------------------------------------//

class _SnapListState<TValue> extends State<SnapList<TValue>> {
  // --- Controllers ---
  late ItemScrollController _itemScrollController;
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // --- State Variables ---
  int _centerIndex = 0; // Tracks the index intended to be centered
  // Track if during this drag we ever crossed to the next/prev item
  double _dragStartCenterPosition = 0;

  // Track GlobalKeys for each item for accurate height measurement
  final Map<int, GlobalKey> _itemKeys = {};

  DateTime? _lastRepaintTime;
  bool _snapScroll = false; // Span is active = no another snap will be triggered

  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    _itemScrollController = widget.itemScrollController ?? ItemScrollController();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _centerIndex = widget.initialIndex;

    // jump immediately without animation
    SchedulerBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToItem(_centerIndex, false, true, true));
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    super.dispose();
  }

  // #region Scroll Listener Logic

  void _onItemPositionsChanged() {
    if (!mounted) return;
    final now = DateTime.now();
    // throttle UI rebuild to ~20fps
    if (_lastRepaintTime == null || now.difference(_lastRepaintTime!) > widget.repaintThrottleDuration) {
      _lastRepaintTime = now;
      setState(() {}); // triggers re-draw for opacity/scale
    }
  }

  // #endregion

  // #region Snapping Logic

  void _onScroll(ScrollNotification scrollNotification) {
    if (_snapScroll) {
      return;
    }

    // user began dragging → snapshot center
    if (scrollNotification is ScrollStartNotification) {
      _dragStartCenterPosition = scrollNotification.metrics.pixels;
    }

    // 3) on drag end, ignore primaryVelocity, use our last direction
    if (scrollNotification is ScrollEndNotification && scrollNotification.dragDetails != null) {
      final start = _centerIndex;
      final scrolledDiff = scrollNotification.metrics.pixels - _dragStartCenterPosition;
      _dragStartCenterPosition = 0;

      int target;
      bool? down;

      final cardHeight = _getCardHeight(start);
      if (cardHeight == null) {
        return;
      }

      final screenHeight = MediaQuery.of(context).size.height;
      final thresholdHeight = screenHeight - widget.topOverlayHeight - widget.bottomOverlayHeight - widget.spacing * 2;

      // Special behavior for long cards
      if (cardHeight > thresholdHeight) {
        if (scrolledDiff >= 0) {
          target = start + 1;
          down = true;
        } else {
          target = start - 1;
          down = false;
        }

        // Target card is not yet visible
        final scrollPosition = _positionForIndex(target);
        if (scrollPosition == null) {
          //print('Target card $target is not yet visible');
          return;
        }

        final visibleTargetHeight = down
            // Item is visible above nav bar + gap
            ? screenHeight - screenHeight * scrollPosition.itemLeadingEdge - widget.bottomOverlayHeight
            // Item is visible below app bar + gap
            : screenHeight * scrollPosition.itemTrailingEdge - widget.topOverlayHeight;

        // Scrolling down, let's check if next card is at least partially visible
        //print('Target card $target visibility is $visibleTargetHeight px');
        if (visibleTargetHeight < widget.spacing * 2) {
          return;
        }
      } else {
        if (scrolledDiff > 100) {
          target = start + 1;
          down = true;
        } else if (scrolledDiff < -100) {
          target = start - 1;
          down = false;
        } else {
          target = start;
        }
      }

      // Make sure that snap target has height
      if (down != null) {
        target = target.clamp(0, widget.items.length - 1);
        final step = down ? 1 : -1;
        for (var candidate = target; candidate >= 0 && candidate < widget.items.length; candidate += step) {
          if (_getCardHeight(candidate) != 0) {
            target = candidate;
            break;
          }
        }
      }

      target = target.clamp(0, widget.items.length - 1);

      _snapToItem(target, true, down ?? true, false);
      _snapScroll = true;
    }
  }

  double? _getCardHeight(int index) {
    final key = _itemKeys[index];
    if (key == null || key.currentContext == null) {
      debugPrint('Unable to resolve snap source for index $index: key is null or has no context');
      return null;
    }

    final box = key.currentContext!.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      debugPrint('Unable to resolve snap source for index $index: box is null or has no size');
      return null;
    }

    final itemHeight = box.size.height;
    if (itemHeight.isInfinite || itemHeight.isNaN) {
      debugPrint('Unable to resolve snap source for index $index: item height is invalid ($itemHeight)');
      return null;
    }

    return itemHeight;
  }

  void _snapToItem(int targetIndex, bool scroll, bool down, bool first) {
    if (targetIndex < 0 || targetIndex >= widget.items.length) {
      return;
    }

    if (_centerIndex != targetIndex || first) {
      _centerIndex = targetIndex;
      widget.onCurrentItemChanged?.call(targetIndex);
    }

    final itemHeight = _getCardHeight(targetIndex);
    if (itemHeight == null) {
      return;
    }

    // print('Snapping to $targetIndex [0..${_items.length - 1}] with height $itemHeight');

    final screenHeight = MediaQuery.of(context).size.height;
    final thresholdHeight = screenHeight - widget.topOverlayHeight - widget.bottomOverlayHeight - widget.spacing * 2;

    double alignment;
    if (targetIndex == 0) {
      alignment = ((widget.topOverlayHeight + widget.spacing * 2) / screenHeight).clamp(0, 1);
      //} else if (targetIndex == _items.length - 1) {
      //  alignment = (itemHeight + widget.bottomOverlayHeight + widget.spacing) / screenHeight;
    } else if (itemHeight < thresholdHeight) {
      alignment = (((screenHeight / 2) - (itemHeight / 2)) / screenHeight).clamp(0, 1);
    } else {
      // For items taller than threshold, align based on scroll direction
      if (down) {
        // Align to top if scrolling down
        alignment = (widget.topOverlayHeight + widget.spacing * 2) / screenHeight;
      } else {
        // Align to bottom if scrolling up
        final bottomGap = widget.bottomOverlayHeight + widget.spacing * 2;
        final cardTopToScreenBottom = itemHeight + bottomGap;
        final cardTopGap = screenHeight - cardTopToScreenBottom; // gap between card top and screen top
        alignment = cardTopGap / screenHeight;
      }
    }

    SchedulerBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (scroll) {
        await _itemScrollController.scrollTo(index: targetIndex, duration: widget.snapAnimationDuration, curve: Curves.ease, alignment: alignment);
        _snapScroll = false;
      } else {
        _itemScrollController.jumpTo(index: targetIndex, alignment: alignment);
      }
    });
  }

  // #endregion

  double _getCardInterpolationFactor(int index, double screenSize) {
    final pos = _positionForIndex(index);

    // compute interpolation factor (0 = far, 1 = centered)
    if (pos == null) {
      return 0.0;
    }

    final itemTop = pos.itemLeadingEdge;
    final itemBottom = pos.itemTrailingEdge;
    final itemHeightFraction = itemBottom - itemTop;
    final screenCardArea = screenSize - widget.topOverlayHeight - widget.bottomOverlayHeight - widget.spacing * 2;
    final screenCardAreaFraction = screenCardArea / screenSize;

    // Long card - interpolate when cars side moves away from its snap position
    if (itemHeightFraction >= screenCardAreaFraction) {
      final topSnapPositionFraction = (widget.topOverlayHeight + widget.spacing) / screenSize; // 0.1 pos = 1 factor
      final topMaxFactor = 0.6 - topSnapPositionFraction; // 0.6 pos = 0 factor
      final topSnapDiff = itemTop - topSnapPositionFraction;
      final topFactor = 1 - topSnapDiff / topMaxFactor;

      final bottomSnapPositionFraction = (widget.bottomOverlayHeight + widget.spacing) / screenSize;
      final bottomMaxFactor = 0.6 - bottomSnapPositionFraction; // 0.6 pos = 0 factor
      final bottomSnapDiff = 1 - itemBottom - bottomSnapPositionFraction;
      final bottomFactor = 1 - bottomSnapDiff / bottomMaxFactor;
      return min(topFactor, bottomFactor).clamp(0, 1);
    }

    // First regular card - only interpolate when the card moves up past its initial position
    if (index == 0) {
      // how tall is this card in pixels?
      final itemHeightPx = itemHeightFraction * screenSize;
      // compute the initial center pixel at (topOverlay + spacing + half card)
      final initialCenterPx = widget.topOverlayHeight + widget.spacing * 2 + itemHeightPx / 2;
      // turn into a viewport‐fraction
      final initialCenterFrac = initialCenterPx / screenSize;
      // current center fraction
      final currentCenterFrac = itemTop + itemHeightFraction * 0.5;
      final diff = initialCenterFrac - currentCenterFrac;
      final factor = 1 - diff / initialCenterFrac;
      return factor.clamp(0.0, 1.0);
    }

    // Regular card - interpolate based on distance from center
    final itemCenter = itemTop + (itemBottom - itemTop) * 0.5;
    final distance = (itemCenter - 0.5).abs();
    const threshold = 0.01;
    if (distance > threshold) {
      return (1.0 - (distance / 0.5)).clamp(0.0, 1.0);
    } else {
      return 1.0;
    }
  }

  ItemPosition? _positionForIndex(int index) {
    for (final position in _itemPositionsListener.itemPositions.value) {
      if (position.index == index) return position;
    }
    return null;
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Calculate item count including potential loading indicators
    final itemCount = widget.items.length;

    // Handle case where list becomes empty after initial load but there was no error
    if (itemCount == 0) {
      return const Center(child: Text('No items to display.'));
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        _onScroll(scrollNotification);
        return false;
      },
      child: ScrollablePositionedList.separated(
        key: const Key('snap_scroll'),
        itemCount: itemCount,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        initialScrollIndex: widget.initialIndex,
        physics: widget.physics,
        padding: widget.padding,
        separatorBuilder: (context, index) => SizedBox(height: widget.spacing),
        // initialScrollIndex and initialAlignment are handled by the jumpTo in _fetchInitialItems
        itemBuilder: (context, index) {
          // --- Actual List Item with dynamic scaling & opacity ---
          if (index >= 0 && index < widget.items.length) {
            // interpolate scale and opacity based on widget properties
            final t = _getCardInterpolationFactor(index, screenHeight);
            final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
            final opacity = widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
            final item = widget.items[index];

            return Container(
              key: _itemKeys.putIfAbsent(index, GlobalKey.new),
              //color: Colors.yellow,
              child: Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: widget.itemBuilder(context, item)),
              ),
            );
          }

          // Should only happen if itemCount/indexing logic has an issue,
          // return an empty box as a safeguard.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

//----------------------------------------------------------------------------//
// Custom SnappingScrollPhysics
//----------------------------------------------------------------------------//

/// A custom ScrollPhysics that kills any fling immediately
/// so that our snap-to can run without delay.
class SnappingScrollPhysics extends ClampingScrollPhysics {
  const SnappingScrollPhysics({super.parent});

  @override
  SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Reduce velocity to slow down fling
    //final slowedVelocity = velocity * 0.3; // adjust this multiplier to control fling speed
    //return super.createBallisticSimulation(position, slowedVelocity);
    return null;
  }
}
