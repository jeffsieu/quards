import 'package:quards/models/deck.dart';

class SolitaireCard {
  SolitaireCard(Suit suit, int value) : _card = StandardCard(suit, value);
  SolitaireCard.fromStandardCard(this._card, {required bool isFaceDown}) {
    _faceDown = isFaceDown;
  }

  final StandardCard _card;

  StandardCard get standardCard => _card;

  Suit get suit => _card.suit;
  int get value => _card.value;
  bool get isRed => _card.isRed;

  bool _faceDown = false;

  bool get isFaceDown => _faceDown;

  String get valueString => _card.valueString;

  void flip() {
    _faceDown = !_faceDown;
  }

  bool canBePlacedBelow(SolitaireCard card) {
    return card._card.isRed != _card.isRed;
  }

  @override
  String toString() {
    return _card.toString();
  }
}
