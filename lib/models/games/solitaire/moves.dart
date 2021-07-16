import 'card.dart';
import 'solitaire.dart';

abstract class Move {
  void execute();
  void undo();
}

abstract class PileMove extends Move {
  PileMove(this.origin, this.targetPile)
      : oldtargetPileSize = targetPile.size,
        destination =
            SolitaireCardLocation(row: targetPile.size, pile: targetPile),
        card = origin.pile.cardAt(origin.row);
  final SolitaireCardLocation origin;
  final SolitaireCardLocation destination;
  final SolitairePile targetPile;
  final int oldtargetPileSize;
  final SolitaireCard card;

  @override
  void execute() {
    SolitairePile originPile = origin.pile;
    SolitairePile movedPile = originPile.removePileFrom(origin.row);
    targetPile.appendPile(movedPile);
  }

  @override
  void undo() {
    SolitairePile movedPile = targetPile.removePileFrom(oldtargetPileSize);
    SolitairePile originPile = origin.pile;
    originPile.appendPile(movedPile);
  }
}

/// Like a pile move, but from a tableau pile. Supports undoing of card flips.
class TableauPileMove extends PileMove {
  SolitaireCard? flippedCard;
  TableauPileMove(SolitaireCardLocation origin, SolitairePile targetPile)
      : super(origin, targetPile);

  @override
  void execute() {
    super.execute();
    SolitairePile originPile = origin.pile;
    if (originPile.topCard != null) {
      if (originPile.topCard!.isFaceDown) {
        originPile.topCard!.flip();
        flippedCard = originPile.topCard;
      }
    }
  }

  @override
  void undo() {
    super.undo();
    flippedCard?.flip();
  }
}

class StockPileMove extends PileMove {
  StockPileMove(this.stock)
      : super(
            SolitaireCardLocation(
                row: stock.stockPile.size - 1, pile: stock.stockPile),
            stock.wastePile);
  SolitaireStock stock;
  // final int dealtCardRow;

  @override
  void execute() {
    move(stock.stockPile, stock.wastePile);
  }

  @override
  void undo() {
    move(stock.wastePile, stock.stockPile);
  }

  void move(SolitairePile fromPile, SolitairePile toPile) {
    if (fromPile.isNotEmpty) {
      final SolitairePile topCardPile = fromPile.peekTopCard();
      topCardPile.topCard!.flip();
      if (fromPile == stock.stockPile) {
        super.execute();
      } else {
        super.undo();
      }
      // toPile.appendPile(topCardPile);
    } else {
      // Stock pile is empty, return all from waste pile to stock pile
      while (toPile.isNotEmpty) {
        final SolitairePile topCardPile = toPile.removeTopCard();
        topCardPile.topCard!.flip();
        fromPile.appendPile(topCardPile);
      }
    }
  }
}
