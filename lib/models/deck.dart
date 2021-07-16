library cards;

import 'package:equatable/equatable.dart';

abstract class Deck<Card> {
  Deck(this.cards) : _size = cards.length;

  List<Card> cards;
  int get size => _size;
  set size(int value) {
    _size = value.clamp(0, double.infinity).toInt();
  }

  int _size;
  bool get isEmpty => cards.isEmpty;
  bool get isNotEmpty => cards.isNotEmpty;

  Card peek() {
    return cards.first;
  }

  Iterable<Card> peekN(int n) {
    return cards.take(n);
  }

  Card cardAt(int n) {
    return cards.elementAt(n);
  }

  Card take() {
    assert(cards.isNotEmpty, 'Deck is empty');
    cards = cards.skip(1).toList();
    size -= 1;
    return cards.first;
  }

  Iterable<Card> takeN(int n) {
    assert(size >= n, 'Deck does not have $n cards');
    final Iterable<Card> nCards = cards.take(n);
    cards = cards.skip(n).toList();
    return nCards;
  }

  void shuffle() {
    cards.shuffle();
  }
}

class StandardDeck extends Deck<StandardCard> {
  StandardDeck.shuffled()
      : super(Suit.values
            .expand((suit) =>
                List.generate(13, (index) => StandardCard(suit, index + 1)))
            .toList()
              ..shuffle());
}

enum Suit {
  clubs,
  diamonds,
  hearts,
  spades,
}

const ace = 1;
const jack = 11;
const queen = 12;
const king = 13;

class StandardCard extends Equatable {
  const StandardCard(this.suit, this.value)
      : assert(value >= ace),
        assert(value <= king);

  final Suit suit;
  final int value;

  bool get isRed => suit == Suit.diamonds || suit == Suit.hearts;

  String get valueString {
    if (value == ace) {
      return 'A';
    } else if (value == jack) {
      return 'J';
    } else if (value == queen) {
      return 'Q';
    } else if (value == king) {
      return 'K';
    } else {
      return value.toString();
    }
  }

  @override
  String toString() {
    return '$value${suit.toDisplayString()}';
  }

  @override
  List<Object?> get props => [suit, value];
}

extension SuitString on Suit {
  String toDisplayString() {
    if (this == Suit.clubs) {
      return '♣';
    } else if (this == Suit.diamonds) {
      return '♦';
    } else if (this == Suit.hearts) {
      return '♥';
    } else {
      return '♠';
    }
  }
}

extension CardHelper on int {
  StandardCard of(Suit suit) {
    return StandardCard(suit, this);
  }
}
