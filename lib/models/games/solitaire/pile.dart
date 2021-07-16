// Represents a solitaire pile
// The lowest index represents the bottom of the pile
// (the card which has the all the other cards lying on top of it)
class Pile<Card> {
  const Pile(List<Card> cards) : _cards = cards;
  final List<Card> _cards;

  Iterable<Card> get cards => _cards;

  int get size => _cards.length;

  /// The card that is layered on top of all other cards, at the bottom of the column.
  Card? get topCard => size > 0 ? _cards.last : null;

  /// The card that is layered below all other cards, at the top of the column.
  Card? get bottomCard => size > 0 ? _cards.first : null;

  Card cardAt(int n) {
    return _cards.elementAt(n);
  }

  int rowOf(Card card) {
    return _cards.indexOf(card);
  }

  bool get isEmpty => _cards.isEmpty;
  bool get isNotEmpty => _cards.isNotEmpty;

  Pile<Card> removePileFrom(int index) {
    List<Card> removedCards = _cards.skip(index).toList();
    _cards.removeRange(index, _cards.length);
    return Pile<Card>(removedCards);
  }

  Pile<Card> removeTopCard() {
    return removePileFrom(size - 1);
  }

  Pile<Card> peekTopCard() {
    return peekPileFrom(size - 1);
  }

  Pile<Card> peekPileFrom(int index) {
    List<Card> cards = _cards.skip(index).toList();
    return Pile<Card>(cards);
  }

  void appendPile(Pile<Card> pile) {
    _cards.addAll(pile._cards);
  }

  @override
  String toString() {
    return cards.toString();
  }
}
