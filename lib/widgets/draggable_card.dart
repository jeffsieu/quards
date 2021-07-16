import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quards/main.dart';

typedef ElevationWidgetBuilder = Widget Function(BuildContext context,
    Widget? child, double elevation, bool isDragged, double scale);

// A card that is draggable and returns to its original spot

class DraggableCard<T extends Object> extends StatefulWidget {
  const DraggableCard(
      {Key? key,
      this.child,
      this.builder = defaultBuilder,
      this.elevation = 0,
      this.hoverElevation = 16.0,
      this.onHover,
      this.onDragStart,
      this.onDragCancel,
      this.onDragAccept,
      this.onDragReturn,
      this.onDoubleTap,
      this.data,
      this.forceHovering,
      this.releasedNotifier,
      this.shouldUpdateOnRelease,
      this.canDrag = true,
      this.canHover = true})
      : super(key: key);

  final Widget? child;
  final double hoverElevation;
  final double elevation;
  final ElevationWidgetBuilder builder;
  final ValueChanged<bool>? onHover;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragCancel;
  final ValueChanged<Offset>? onDragAccept;
  final VoidCallback? onDragReturn;
  final VoidCallback? onDoubleTap;
  final T? data;
  final bool? forceHovering;
  final bool canDrag;
  final bool canHover;
  final ValueNotifier<HoverReleaseDetails?>? releasedNotifier;
  final bool Function(HoverReleaseDetails?)? shouldUpdateOnRelease;

  static Widget defaultBuilder(BuildContext context, Widget? child,
      double elevation, bool isDragged, double scale) {
    return child ?? Container();
  }

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState<T extends Object> extends State<DraggableCard<T>>
    with TickerProviderStateMixin {
  final double maxRotationDegrees = 15;
  final double maxVelocity = 2500;
  double get maxRotation => maxRotationDegrees / 180 * pi;
  // VelocityTracker tracker = VelocityTracker.withKind(PointerDeviceKind.unknown);
  // final StreamController<Velocity> _velocityStreamController =
  //     StreamController.broadcast();

  final GlobalKey _gestureDetectorKey = GlobalKey();

  // late OverlayEntry cardOverlay = OverlayEntry(
  //     builder: (context) =>
  //         widget.builder(context, widget.child, elevation, false));

  late final AnimationController hoverAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250));

  late final Animation hoverAnimation = CurvedAnimation(
      parent: hoverAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);

  late final AnimationController offsetAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300));

  late final Animation offsetAnimation = CurvedAnimation(
      parent: offsetAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);

  Offset draggableReleasedOffset = Offset.zero;

  double get hoverPercentage => hoverAnimation.value;
  double get elevation => lerpDouble(
      widget.elevation, widget.hoverElevation, hoverAnimation.value)!;

  double get scale => lerpDouble(1, hoveredScale, hoverPercentage)!;
  double hoveredScale = 1.1;

  bool isDragging = false;
  bool _isHovering = false;

  bool get isHovering => _isHovering;

  bool hasUpdated = false;

  set isHovering(bool isHovering) {
    _isHovering = isHovering;
    if (widget.onHover != null) widget.onHover!(isHovering);
    if (isHovering) {
      hoverAnimationController.forward();
    } else {
      hoverAnimationController.reverse();
    }
  }

  void releasedNotifierCallback() async {
    final HoverReleaseDetails? details = widget.releasedNotifier?.value;
    if (details != null) {
      final shouldUpdate = widget.shouldUpdateOnRelease != null
          ? widget.shouldUpdateOnRelease!(details)
          : true;

      if (shouldUpdate) {
        // setState(() {
        //   isDragging = true;
        // });
        await springBackFrom(details.offset);
        // setState(() {
        //   isDragging = false;
        // });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    hasUpdated = true;
    final HoverReleaseDetails? details = widget.releasedNotifier?.value;
    final shouldUpdate = widget.shouldUpdateOnRelease != null
        ? widget.shouldUpdateOnRelease!(details)
        : true;
    if (shouldUpdate) {
      releasedNotifierCallback();
      // TODO: Update the card by animating it
    }
    releasedNotifierCallback();
    WidgetsBinding.instance!.scheduleFrameCallback((timeStamp) {
      releasedNotifierCallback();
    });
    widget.releasedNotifier?.addListener(releasedNotifierCallback);
  }

  @override
  void dispose() {
    widget.releasedNotifier?.removeListener(releasedNotifierCallback);
    offsetAnimationController.dispose();
    hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forceHovering != null) {
      // If forced hovered state
      if (widget.forceHovering! != isHovering) {
        if (widget.forceHovering!) {
          hoverAnimationController.forward();
        } else {
          hoverAnimationController.reverse();
        }
      }
    } else {
      // Hovered state is not forced; animate to hover state
      // based on cursor hover
      if (isHovering) {
        hoverAnimationController.forward();
      } else {
        hoverAnimationController.reverse();
      }
    }
    return Opacity(
      opacity: hasUpdated ? 1 : 0,
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Listener(
          onPointerDown: (event) {
            isHovering = true;
            // isHovering = widget.canHover;
          },
          onPointerUp: (event) {
            if (event.kind != PointerDeviceKind.mouse) isHovering = false;
          },
          onPointerCancel: (event) {
            isHovering = false;
          },
          child: MouseRegion(
            onEnter: (event) {
              if (!event.down) {
                isHovering = widget.canHover;
              }
            },
            onExit: (PointerExitEvent event) {
              isHovering = false;
            },
            child: Draggable<T>(
              key: _gestureDetectorKey,
              maxSimultaneousDrags: widget.canDrag ? null : 0,
              data: widget.data,
              feedback:
                  // _buildVelocityTransform(
                  // child:
                  Transform.scale(
                      scale: hoveredScale,
                      child: widget.builder(
                          context, widget.child, elevation, true, scale)),
              // ),
              // onDragUpdate: (details) {
              // if (details.sourceTimeStamp != null) {
              //   final previousVelocity = tracker.getVelocity();
              //   tracker.addPosition(
              //       details.sourceTimeStamp!, details.globalPosition);
              //   final velocity = Velocity(
              //       pixelsPerSecond: previousVelocity.pixelsPerSecond * 0.9 +
              //           tracker.getVelocity().pixelsPerSecond);
              //   _velocityStreamController.add(velocity);
              // }
              // },
              onDragStarted: () {
                isHovering = true;
                if (widget.onDragStart != null) widget.onDragStart!();
              },
              onDragEnd: (DraggableDetails details) {
                if (details.wasAccepted) {
                  if (widget.onDragAccept != null) {
                    widget.onDragAccept!(details.offset);
                  }
                }
                // isHovering = false;
              },
              onDraggableCanceled: (velocity, offset) {
                if (widget.onDragCancel != null) widget.onDragCancel!();
                springBackFrom(offset);
                // setState(() {
                //   isDragging = false;
                // });
              },
              childWhenDragging: Opacity(
                opacity: 0,
                child: widget.builder(context, widget.child, 0, false, scale),
              ),
              child: AnimatedBuilder(
                animation: offsetAnimation,
                builder: (context, child) {
                  final offsetScale = offsetAnimation.value;
                  return Transform.translate(
                      offset: draggableReleasedOffset.scale(
                          offsetScale, offsetScale),
                      child: child);
                },
                child: AnimatedBuilder(
                  animation: hoverAnimation,
                  builder: (context, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: widget.builder(context, widget.child, elevation,
                      offsetAnimation.value != 0, scale),
                  // TODO: Fix redo animation when more than one card is moved
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // StreamBuilder<Velocity> _buildVelocityTransform({required Widget? child}) {
  //   return StreamBuilder<Velocity>(
  //     stream: _velocityStreamController.stream,
  //     builder: (context, snapshot) {
  //       final velocity = snapshot.data;

  //       final double dxPercentage =
  //           (-(velocity?.pixelsPerSecond.dx ?? 0) / maxVelocity).clamp(-1, 1);
  //       final double dyPercentage =
  //           ((velocity?.pixelsPerSecond.dy ?? 0) / maxVelocity).clamp(-1, 1);

  //       final xRotation = Curves.easeOut.transform(dxPercentage.abs()) *
  //           maxRotation *
  //           dxPercentage.sign;

  //       final yRotation = Curves.easeOut.transform(dyPercentage.abs()) *
  //           maxRotation *
  //           dyPercentage.sign;

  //       return Transform.scale(
  //         scale: scale,
  //         alignment: Alignment.center,
  //         child: Transform(
  //           transform: Matrix4.identity()
  //             ..setEntry(3, 2, 0.001)
  //             ..rotateX(yRotation)
  //             ..rotateY(xRotation),
  //           alignment: FractionalOffset.center,
  //           child: child,
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> springBackFrom(Offset offset) async {
    if (_gestureDetectorKey.currentContext?.findRenderObject() == null) {
      return;
    }
    RenderBox box =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    draggableReleasedOffset = box.globalToLocal(offset);
    final double longestScreenSide = MediaQuery.of(context).size.longestSide;

    final durationPercentage = Curves.easeOutCubic
        .transform(draggableReleasedOffset.distance / longestScreenSide)
        .clamp(0.5, 1);
    offsetAnimationController.duration =
        Duration(milliseconds: (durationPercentage * 400).toInt());
    offsetAnimationController.value = 1;
    offsetAnimationController
        .reverse()
        .whenComplete(widget.onDragReturn ?? () {});
    return hoverAnimationController.reverse();
  }
}
