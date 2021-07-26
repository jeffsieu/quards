import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quards/models/games/solitaire/card.dart';
import 'package:quards/models/deck.dart';

class PokerCard extends StatelessWidget {
  PokerCard(
      {Key? key,
      this.elevation = 0,
      this.card,
      required this.width,
      this.onTap})
      : isTransparent = false,
        isFaceDown = card?.isFaceDown ?? false,
        super(key: key);

  const PokerCard.transparent(
      {Key? key, this.elevation = 0, required this.width, this.onTap})
      : isTransparent = true,
        isFaceDown = false,
        card = null,
        super(key: key);

  const PokerCard.emptySlot(
      {Key? key, this.elevation = 0, required this.width, this.onTap})
      : card = null,
        isTransparent = false,
        isFaceDown = false,
        super(key: key);

  final double elevation;
  final SolitaireCard? card;
  // late final Color cardColor;
  final double width;
  final bool isFaceDown;
  final bool isTransparent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      // switchInCurve: Interval(0.5, 1),
      // switchOutCurve: Interval(0, 0.5),
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            bool isVisible = animation.value > 0.5;
            return Opacity(
              opacity: isVisible ? 1 : 0,
              child: Transform(
                alignment: FractionalOffset.center,
                transform: Matrix4.identity()
                  ..rotateY(math.pi *
                      (1 - animation.value) *
                      (animation.status == AnimationStatus.forward ? 1 : -1)),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      child: SizedBox(
        key: ValueKey(isFaceDown),
        width: width,
        child: FittedBox(
          child: Material(
            color: isTransparent
                ? Colors.white.withOpacity(0.25)
                : card != null
                    ? (card!.isFaceDown
                        ? Theme.of(context).cardColor.darken()
                        : Theme.of(context).cardColor)
                    : Theme.of(context).scaffoldBackgroundColor.darken(),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            elevation: elevation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 4.0),
              ),
              // padding: const EdgeInsets.all(16.0),
              width: 300,
              height: 500,
              child: Stack(
                children: [
                  if (card != null) ...{
                    if (!card!.isFaceDown) ...{
                      _buildCardFront(context),
                    } else ...{
                      _buildCardBack(context),
                    }
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerText(BuildContext context) {
    return Text(
      '${card!.valueString}\n${card!.suit.toDisplayString()}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline3?.copyWith(
          color: card!.isRed
              ? Colors.red.shade300
              : Theme.of(context).colorScheme.onSurface,
          fontFamilyFallback: ['Noto Sans JP'],
          height: 1),
    );
  }

  Widget _buildCardFront(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Positioned(
            child: _buildCornerText(context),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi,
              child: _buildCornerText(context),
            ),
          ),
          Center(
            child: AspectRatio(
              aspectRatio: 1 / 3,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: Theme.of(context).hoverColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).cardColor.darken(.15),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }
}
