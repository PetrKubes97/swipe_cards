import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';

enum SlideDirection { left, right, up }

enum SlideRegion { inNopeRegion, inLikeRegion, inSuperLikeRegion }

class DraggableCard extends StatefulWidget {
  final Widget card;
  final Widget? likeTag;
  final Widget? nopeTag;
  final Widget? superLikeTag;
  final bool isDraggable;
  final SlideDirection? slideTo;
  final Function(double distance)? onSlideUpdate;
  final Function(SlideRegion? slideRegion)? onSlideRegionUpdate;
  final Function(SlideDirection? direction)? onSlideOutComplete;
  final bool upSwipeAllowed;
  final bool leftSwipeAllowed;
  final bool rightSwipeAllowed;
  final EdgeInsets padding;
  final bool isBackCard;
  final Decision decision;

  final double swipeThreshold;
  final double tagMinThreshold;

  final Function()? onUnsuccessfulSwipeAttempt;

  DraggableCard(
      {super.key,
      required this.card,
      this.likeTag,
      this.nopeTag,
      this.superLikeTag,
      this.isDraggable = true,
      this.onSlideUpdate,
      this.onSlideOutComplete,
      this.slideTo,
      this.onSlideRegionUpdate,
      this.upSwipeAllowed = false,
      this.leftSwipeAllowed = true,
      this.rightSwipeAllowed = true,
      this.isBackCard = false,
      this.padding = EdgeInsets.zero,
      this.swipeThreshold = 0.15,
      this.tagMinThreshold = 0.5,
      this.onUnsuccessfulSwipeAttempt,
      required this.decision});

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with TickerProviderStateMixin {
  GlobalKey profileCardKey = GlobalKey(debugLabel: 'profile_card_key');
  Offset? cardOffset = const Offset(0.0, 0.0);
  Offset? dragStart;
  Offset? dragPosition;
  Offset? slideBackStart;
  SlideDirection? slideOutDirection;
  SlideRegion? slideRegion;
  late AnimationController slideBackAnimation;
  Tween<Offset>? slideOutTween;
  late AnimationController slideOutAnimation;

  RenderBox? box;
  var topLeft, bottomRight;
  Rect? anchorBounds;

  bool isAnchorInitialized = false;

  @override
  void initState() {
    super.initState();
    slideBackAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )
      ..addListener(() => setState(() {
            cardOffset = Offset.lerp(
              slideBackStart,
              const Offset(0.0, 0.0),
              ElasticOutCurve(0.8).transform(slideBackAnimation.value),
            );

            if (null != widget.onSlideUpdate) {
              widget.onSlideUpdate!(cardOffset!.distance);
            }

            if (null != widget.onSlideRegionUpdate) {
              widget.onSlideRegionUpdate!(slideRegion);
            }
          }))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            slideBackStart = null;
            dragPosition = null;
          });
          widget.onUnsuccessfulSwipeAttempt?.call();
        }
      });

    slideOutAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          cardOffset = slideOutTween!.evaluate(slideOutAnimation);

          if (null != widget.onSlideUpdate) {
            widget.onSlideUpdate!(cardOffset!.distance);
          }

          if (null != widget.onSlideRegionUpdate) {
            widget.onSlideRegionUpdate!(slideRegion);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideOutTween = null;

            if (widget.onSlideOutComplete != null) {
              widget.onSlideOutComplete!(slideOutDirection);
            }
          });
        }
      });
  }

  @override
  void didUpdateWidget(DraggableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.card!.key != oldWidget.card!.key) {
      cardOffset = const Offset(0.0, 0.0);
    }

    if (oldWidget.slideTo == null && widget.slideTo != null) {
      switch (widget.slideTo!) {
        case SlideDirection.left:
          _slideLeft();
          break;
        case SlideDirection.right:
          _slideRight();
          break;
        case SlideDirection.up:
          _slideUp();
          break;
      }
    }
  }

  @override
  void dispose() {
    slideOutAnimation.dispose();
    slideBackAnimation.dispose();
    super.dispose();
  }

  Offset _chooseRandomDragStart() {
    final cardContext = profileCardKey.currentContext!;
    final cardTopLeft = (cardContext.findRenderObject() as RenderBox)
        .localToGlobal(const Offset(0.0, 0.0));
    final dragStartY =
        cardContext.size!.height * (Random().nextDouble() < 0.5 ? 0.25 : 0.75) +
            cardTopLeft.dy;
    return Offset(cardContext.size!.width / 2 + cardTopLeft.dx, dragStartY);
  }

  void _slideLeft() async {
    await Future.delayed(Duration(milliseconds: 250)).then((_) {
      final screenWidth = context.size!.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = Tween(
          begin: const Offset(0.0, 0.0), end: Offset(-2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideRight() async {
    await Future.delayed(Duration(milliseconds: 250)).then((_) {
      final screenWidth = context.size!.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = Tween(
          begin: const Offset(0.0, 0.0), end: Offset(2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideUp() async {
    await Future.delayed(Duration(milliseconds: 250)).then((_) {
      final screenHeight = context.size!.height;
      dragStart = _chooseRandomDragStart();
      slideOutTween = Tween(
          begin: const Offset(0.0, 0.0), end: Offset(0.0, -2 * screenHeight));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _onPanStart(DragStartDetails details) {
    dragStart = details.globalPosition;

    if (slideBackAnimation.isAnimating) {
      slideBackAnimation.stop(canceled: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final isInLeftRegion =
        (cardOffset!.dx / context.size!.width) < -widget.swipeThreshold;
    final isInRightRegion =
        (cardOffset!.dx / context.size!.width) > widget.swipeThreshold;
    final isInTopRegion =
        (cardOffset!.dy / context.size!.height) < -widget.swipeThreshold;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideRegion = isInLeftRegion
            ? SlideRegion.inNopeRegion
            : SlideRegion.inLikeRegion;
      } else if (isInTopRegion) {
        slideRegion = SlideRegion.inSuperLikeRegion;
      } else {
        slideRegion = null;
      }

      dragPosition = details.globalPosition;
      if (dragPosition == null || dragStart == null) return;

      cardOffset = dragPosition! - dragStart!;

      if (null != widget.onSlideUpdate) {
        widget.onSlideUpdate!(cardOffset!.distance);
      }

      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate!(slideRegion);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dragVector = cardOffset! / cardOffset!.distance;

    final isInLeftRegion =
        (cardOffset!.dx / context.size!.width) < -widget.swipeThreshold;
    final isInRightRegion =
        (cardOffset!.dx / context.size!.width) > widget.swipeThreshold;
    final isInTopRegion =
        (cardOffset!.dy / context.size!.height) < -widget.swipeThreshold;

    setState(() {
      if (isInLeftRegion) {
        if (widget.leftSwipeAllowed) {
          slideOutTween = Tween(
              begin: cardOffset, end: dragVector * (2 * context.size!.width));
          slideOutAnimation.forward(from: 0.0);

          slideOutDirection = SlideDirection.left;
        } else {
          slideBackStart = cardOffset;
          slideBackAnimation.forward(from: 0.0);
        }
      } else if (isInRightRegion) {
        if (widget.rightSwipeAllowed) {
          slideOutTween = Tween(
              begin: cardOffset, end: dragVector * (2 * context.size!.width));
          slideOutAnimation.forward(from: 0.0);

          slideOutDirection = SlideDirection.right;
        } else {
          slideBackStart = cardOffset;
          slideBackAnimation.forward(from: 0.0);
        }
      } else if (isInTopRegion) {
        if (widget.upSwipeAllowed) {
          slideOutTween = Tween(
              begin: cardOffset, end: dragVector * (2 * context.size!.height));
          slideOutAnimation.forward(from: 0.0);

          slideOutDirection = SlideDirection.up;
        } else {
          slideBackStart = cardOffset;
          slideBackAnimation.forward(from: 0.0);
        }
      } else {
        slideBackStart = cardOffset;
        slideBackAnimation.forward(from: 0.0);
      }

      slideRegion = null;
      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate!(slideRegion);
      }
    });
  }

  double _rotation(Rect? dragBounds) {
    if (dragStart != null) {
      final rotationCornerMultiplier =
          dragStart!.dy >= dragBounds!.top + (dragBounds.height / 2) ? -1 : 1;
      return (pi / 8) *
          (cardOffset!.dx / dragBounds.width) *
          rotationCornerMultiplier;
    } else {
      return 0.0;
    }
  }

  Offset _rotationOrigin(Rect? dragBounds) {
    if (dragStart != null) {
      return dragStart! - dragBounds!.topLeft;
    } else {
      return const Offset(0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAnchorInitialized) {
      _initAnchor();
    }

    //Disables dragging card while slide out animation is in progress. Solves
    // issue that fast swipes cause the back card not loading
    if (widget.isBackCard &&
        anchorBounds != null &&
        cardOffset!.dx < anchorBounds!.height) {
      cardOffset = Offset.zero;
    }

    double getTagVisibility(double percentage, Decision decision) {
      if (widget.decision == decision) return 1.0;

      final result = percentage < widget.tagMinThreshold
          ? 0.0
          : ((1 / (1 - widget.tagMinThreshold)) *
              (percentage - widget.tagMinThreshold));
      // Just to avoid some nasty double overflows
      return max(0, min(1.0, result));
    }

    final xProgress = cardOffset!.dx /
        (anchorBounds?.width ?? double.infinity) /
        widget.swipeThreshold;
    final yProgress = cardOffset!.dy /
        (anchorBounds?.height ?? double.infinity) /
        widget.swipeThreshold;

    final rightSideSwipePercentage =
        getTagVisibility(max(min(xProgress, 1.0), 0.0), Decision.like);
    final leftSideSwipePercentage =
        getTagVisibility(max(min(xProgress, 0.0), -1.0).abs(), Decision.nope);
    final upSwipePercentage = getTagVisibility(
        max(min(yProgress, 0.0), -1.0).abs(), Decision.superLike);

    if (anchorBounds == null) return SizedBox();

    // Shows tags on like/dislike/superlike click
    return Transform(
      transform: Matrix4.translationValues(cardOffset!.dx, cardOffset!.dy, 0.0)
        ..rotateZ(_rotation(anchorBounds)),
      origin: _rotationOrigin(anchorBounds),
      child: Container(
        key: profileCardKey,
        width: anchorBounds?.width,
        height: anchorBounds?.height,
        padding: widget.padding,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
              widget.card,
              if (widget.rightSwipeAllowed &&
                  widget.likeTag != null &&
                  (rightSideSwipePercentage > 0.0 ||
                      (slideOutDirection == SlideDirection.right &&
                          widget.decision != Decision.undecided)))
                FilledAndOpacity(
                    opacity: rightSideSwipePercentage,
                    child: widget.likeTag!),
              if (widget.leftSwipeAllowed &&
                  widget.nopeTag != null &&
                  (leftSideSwipePercentage > 0.0 ||
                      (slideOutDirection == SlideDirection.left &&
                          widget.decision != Decision.undecided)))
                FilledAndOpacity(
                    opacity: leftSideSwipePercentage,
                    child: widget.nopeTag!),
              if (widget.upSwipeAllowed &&
                  widget.superLikeTag != null &&
                  ((upSwipePercentage > 0.0 &&
                      slideRegion == SlideRegion.inSuperLikeRegion) ||
                      (slideOutDirection == SlideDirection.up &&
                          widget.decision == Decision.superLike)))
                FilledAndOpacity(
                    opacity: upSwipePercentage.abs(),
                    child: widget.superLikeTag!)
            ],
          ),
        ),
      ),
    );
  }

  _initAnchor() async {
    await Future.delayed(Duration(milliseconds: 3));
    box = context.findRenderObject() as RenderBox?;
    topLeft = box!.size.topLeft(box!.localToGlobal(const Offset(0.0, 0.0)));
    bottomRight =
        box!.size.bottomRight(box!.localToGlobal(const Offset(0.0, 0.0)));
    anchorBounds = new Rect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
    );

    setState(() {
      isAnchorInitialized = true;
    });
  }
}

class FilledAndOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;

  const FilledAndOpacity(
      {super.key, required this.child, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Opacity(
      child: child,
      opacity: opacity,
    ));
  }
}
