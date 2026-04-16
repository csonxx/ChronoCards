import 'package:equatable/equatable.dart';

abstract class CardDrawEvent extends Equatable {
  const CardDrawEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCardDraw extends CardDrawEvent {}

class DrawCards extends CardDrawEvent {
  final int count;

  const DrawCards(this.count);

  @override
  List<Object?> get props => [count];
}

class SelectCard extends CardDrawEvent {
  final String cardId;

  const SelectCard(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class ConfirmDraw extends CardDrawEvent {}

class ResetDraw extends CardDrawEvent {}
