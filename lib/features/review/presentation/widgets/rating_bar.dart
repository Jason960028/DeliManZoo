import 'package:flutter/material.dart';

class RatingBar extends StatefulWidget {
  final double initialRating;
  final double minRating;
  final double maxRating;
  final int itemCount;
  final double itemSize;
  final bool allowHalfRating;
  final bool ignoreGestures;
  final Color? unratedColor;
  final Color? ratedColor;
  final ValueChanged<double>? onRatingUpdate;

  const RatingBar({
    super.key,
    this.initialRating = 0.0,
    this.minRating = 0.0,
    this.maxRating = 5.0,
    this.itemCount = 5,
    this.itemSize = 24.0,
    this.allowHalfRating = false,
    this.ignoreGestures = false,
    this.unratedColor,
    this.ratedColor,
    this.onRatingUpdate,
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRating != oldWidget.initialRating) {
      _rating = widget.initialRating;
    }
  }

  void _updateRating(double rating) {
    if (widget.ignoreGestures) return;

    double newRating = rating.clamp(widget.minRating, widget.maxRating);
    
    if (!widget.allowHalfRating) {
      newRating = newRating.round().toDouble();
    }

    if (newRating != _rating) {
      setState(() {
        _rating = newRating;
      });
      widget.onRatingUpdate?.call(newRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratedColor = widget.ratedColor ?? Colors.amber.shade600;
    final unratedColor = widget.unratedColor ?? colorScheme.outline.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: widget.ignoreGestures ? null : (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final rating = (localPosition.dx / (widget.itemSize * widget.itemCount)) * widget.maxRating;
        _updateRating(rating);
      },
      onPanUpdate: widget.ignoreGestures ? null : (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final rating = (localPosition.dx / (widget.itemSize * widget.itemCount)) * widget.maxRating;
        _updateRating(rating);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.itemCount, (index) {
          final fillAmount = (_rating - index).clamp(0.0, 1.0);
          
          return SizedBox(
            width: widget.itemSize,
            height: widget.itemSize,
            child: Stack(
              children: [
                // Background star (unrated)
                Icon(
                  Icons.star_rounded,
                  size: widget.itemSize,
                  color: unratedColor,
                ),
                // Foreground star (rated)
                if (fillAmount > 0)
                  ClipRect(
                    clipper: _StarClipper(fillAmount),
                    child: Icon(
                      Icons.star_rounded,
                      size: widget.itemSize,
                      color: ratedColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fillAmount;

  _StarClipper(this.fillAmount);

  @override
  Rect getClip(Size size) {
    if (fillAmount >= 1.0) {
      return Rect.fromLTWH(0, 0, size.width, size.height);
    } else if (fillAmount <= 0.0) {
      return Rect.zero;
    } else {
      return Rect.fromLTWH(0, 0, size.width * fillAmount, size.height);
    }
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return oldClipper is _StarClipper && oldClipper.fillAmount != fillAmount;
  }
}

class ReadOnlyRatingBar extends StatelessWidget {
  final double rating;
  final int itemCount;
  final double itemSize;
  final Color? ratedColor;
  final Color? unratedColor;

  const ReadOnlyRatingBar({
    super.key,
    required this.rating,
    this.itemCount = 5,
    this.itemSize = 16.0,
    this.ratedColor,
    this.unratedColor,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar(
      initialRating: rating,
      itemCount: itemCount,
      itemSize: itemSize,
      ignoreGestures: true,
      ratedColor: ratedColor,
      unratedColor: unratedColor,
      allowHalfRating: true,
    );
  }
}