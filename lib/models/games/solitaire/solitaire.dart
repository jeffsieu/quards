import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../deck.dart';
import 'card.dart';
import 'moves.dart';
import 'pile.dart';

class SolitaireGame {
  SolitaireGame() {
    final StandardDeck deck = StandardDeck.shuffled();
    tableauPiles = List.generate(
        _pileCount,
        (index) => SolitairePile(deck
            .takeN(index + 1)
            .map((card) =>
                SolitaireCard.fromStandardCard(card, isFaceDown: true))
            .toList()));
    for (SolitairePile pile in tableauPiles) {
      pile.topCard!.flip();
    }
    stock = SolitaireStock(deck);
    foundations = List.generate(
        _foundationCount, (index) => SolitairePile(List.empty(growable: true)));
    moves = [];
    undoneMoves = [];
    drawablePiles = [...tableauPiles, stock.wastePile];
    allPiles = [
      ...tableauPiles,
      ...foundations,
      stock.wastePile,
      stock.stockPile,
    ];
  }

  static const int _pileCount = 7;
  static const int _foundationCount = 4;

  late final SolitaireStock stock;
  late final List<SolitairePile> tableauPiles;
  late final List<SolitairePile> drawablePiles;
  late final List<SolitairePile> allPiles;
  late final List<SolitairePile> foundations;
  late final List<Move> moves;
  late final List<Move> undoneMoves;
  final ValueNotifier<bool> won = ValueNotifier(false);

  SolitairePile pileAt(int col) {
    return tableauPiles[col];
  }

  SolitaireCard cardAt(SolitaireCardLocation location) {
    return location.pile.cardAt(location.row);
  }

  StockPileMove drawFromStock() {
    undoneMoves.clear();
    StockPileMove move = StockPileMove(stock);
    move.execute();
    moves.add(move);
    return move;
  }

  /// Move the card at the given location to the top of the target pile.
  PileMove moveToPile(
      SolitaireCardLocation location, SolitairePile targetPile) {
    PileMove move = TableauPileMove(location, targetPile);
    moves.add(move..execute());
    undoneMoves.clear();
    if (foundations.every((foundation) => foundation.size == 13)) {
      _win();
    }
    return move;
  }

  void _win() {
    won.value = true;
  }

  void makeAllPossibleFoundationMoves() {
    bool moveMade = true;
    while (moveMade) {
      moveMade = _moveAutomaticallyToFoundation();
    }
  }

  bool canAutoMove() {
    return _getAutoMoveableCard() != null;
  }

  bool canMoveToPile(SolitaireCardLocation location, SolitairePile targetPile) {
    SolitairePile originPile = location.pile;
    SolitaireCard movedCard = originPile.cardAt(location.row);
    if (movedCard.isFaceDown) {
      return false;
    }

    bool isSamePile = location.pile == targetPile;
    if (isSamePile) return false;

    bool isFoundation = isFoundationPile(targetPile);
    if (isFoundation) {
      bool isTopCard = location.row == location.pile.size - 1;
      if (!isTopCard) {
        return false;
      }

      SolitaireCard card = cardAt(location);
      if (targetPile.isEmpty) {
        return card.value == ace;
      } else {
        final SolitaireCard topCard = targetPile.topCard!;
        // Ensure same suit and value is + 1 of previous
        return card.value == topCard.value + 1 && card.suit == topCard.suit;
      }
    }
    SolitaireCard? targetCard = targetPile.topCard;
    if (targetCard != null) {
      return movedCard.value == targetCard.value - 1 &&
          targetCard.isRed != movedCard.isRed;
    } else {
      return movedCard.value == king;
    }
    // return true;
  }

  bool isFoundationPile(SolitairePile pile) {
    return foundations.contains(pile);
  }

  bool isWastePile(SolitairePile pile) {
    return stock.wastePile == pile;
  }

  bool isStockPile(SolitairePile pile) {
    return stock.stockPile == pile;
  }

  bool canDrag(SolitaireCardLocation location) {
    bool isFaceDown = cardAt(location).isFaceDown;
    if (isFaceDown) return false;
    bool canOnlyRemoveTopCard =
        isFoundationPile(location.pile) || isWastePile(location.pile);
    if (canOnlyRemoveTopCard) {
      return location.pile.topCard == cardAt(location);
    } else {
      return true;
    }
  }

  Move? get previousMove => moves.isNotEmpty ? moves.last : null;
  Move? get previousUndoneMove =>
      undoneMoves.isNotEmpty ? undoneMoves.last : null;

  Move undo() {
    Move move = moves.removeLast();
    move.undo();
    undoneMoves.add(move);
    return move;
  }

  bool canUndo() {
    return moves.isNotEmpty;
  }

  Move redo() {
    Move move = undoneMoves.removeLast();
    move.execute();
    moves.add(move);
    return move;
  }

  bool canRedo() {
    return undoneMoves.isNotEmpty;
  }

  SolitaireCardLocation _getLocation(SolitaireCard card) {
    SolitairePile pile =
        drawablePiles.firstWhere((pile) => pile.cards.contains(card));
    int row = pile.rowOf(card);
    return SolitaireCardLocation(pile: pile, row: row);
  }

  SolitairePile _getFoundationFor(Suit suit) {
    return foundations.firstWhere(
        (foundation) =>
            foundation.isNotEmpty && foundation.topCard!.suit == suit,
        orElse: () =>
            foundations.firstWhere((foundation) => foundation.isEmpty));
  }

  bool _moveAutomaticallyToFoundation() {
    final SolitaireCard? moveableCard = _getAutoMoveableCard();
    if (moveableCard == null) return false;
    _moveToFoundation(moveableCard);
    return true;
  }

  void _moveToFoundation(SolitaireCard card) {
    SolitairePile foundation = _getFoundationFor(card.suit);
    moveToPile(_getLocation(card), foundation);
  }

  PileMove? tryMoveToFoundation(SolitaireCard card) {
    SolitairePile foundation = _getFoundationFor(card.suit);
    if (_canMoveToFoundation(card, foundation)) {
      return moveToPile(_getLocation(card), foundation);
    }
    return null;
  }

  bool _canMoveToFoundation(SolitaireCard card, SolitairePile foundation) {
    return card.value == (foundation.topCard?.value ?? 0) + 1;
  }

  SolitaireCard? _getAutoMoveableCard() {
    final SolitaireCard? moveableCard = drawablePiles
        .map((pile) => pile.topCard)
        .where((card) => card != null)
        .firstWhere(
            (card) => _canMoveToFoundation(card!, _getFoundationFor(card.suit)),
            orElse: () => null);
    return moveableCard;
  }
}

class SolitaireStock {
  SolitaireStock(StandardDeck deck)
      : stockPile = SolitairePile(deck.cards
            .map((card) =>
                SolitaireCard.fromStandardCard(card, isFaceDown: true))
            .toList());
  final SolitairePile stockPile;
  final SolitairePile wastePile = SolitairePile(List.empty(growable: true));
}

class SolitaireCardLocation extends Equatable {
  const SolitaireCardLocation({
    required this.row,
    required this.pile,
  });
  final int row;
  final SolitairePile pile;

  @override
  String toString() {
    return 'SolitaireCardLocation($row, $pile)';
  }

  @override
  List<Object?> get props => [row, pile];
}

typedef StandardPile = Pile<StandardCard>;
typedef SolitairePile = Pile<SolitaireCard>;
