import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event_card.dart';
import 'card_draw_event.dart';
import 'card_draw_state.dart';

class CardDrawBloc extends Bloc<CardDrawEvent, CardDrawState> {
  List<EventCard> _deck = [];
  List<EventCard> _discardPile = [];
  List<EventCard> _drawnHistory = [];
  int _currentTurn = 1;
  int _maxTurns = 10;
  int _totalDrawn = 0;

  CardDrawBloc() : super(const CardDrawInitial()) {
    on<InitializeCardDrawScene>(_onInitialize);
    on<DrawCard>(_onDrawCard);
    on<ConfirmCard>(_onConfirmCard);
    on<SkipCard>(_onSkipCard);
    on<TriggerExit>(_onTriggerExit);
    on<ResetCardDrawScene>(_onReset);
  }

  Future<void> _onInitialize(
    InitializeCardDrawScene event,
    Emitter<CardDrawState> emit,
  ) async {
    emit(const CardDrawLoading());

    _deck = _generateEventDeck();
    _deck.shuffle();
    _discardPile = [];
    _drawnHistory = [];
    _currentTurn = event.currentTurn;
    _maxTurns = event.maxTurns;
    _totalDrawn = 0;

    emit(CardStackState(
      remainingCards: _deck.length,
      totalCards: _deck.length + event.deckSize - 20,
      currentTurn: _currentTurn,
      maxTurns: _maxTurns,
      exitConditions: _buildExitConditions(),
      distributorStatus: const DeckDistributorStatus(
        busyCount: 1,
        totalCount: 3,
      ),
    ));
  }

  Future<void> _onDrawCard(
    DrawCard event,
    Emitter<CardDrawState> emit,
  ) async {
    if (_deck.isEmpty) {
      if (_discardPile.isNotEmpty) {
        _deck = List.from(_discardPile);
        _discardPile = [];
        _deck.shuffle();
      } else {
        emit(const CardDrawError('卡组已空'));
        return;
      }
    }

    final card = _deck.removeAt(0);

    // Emit drawing state (triggers flying animation)
    emit(CardDrawingState(
      card: card,
      remainingCards: _deck.length,
    ));

    // Wait for animation (600ms fly + 500ms flip = ~1100ms)
    await Future.delayed(const Duration(milliseconds: 1200));

    // Check for conflicts
    String? conflictMessage;
    bool hasConflict = false;
    if (card.isExclusive && _drawnHistory.isNotEmpty) {
      final lastCard = _drawnHistory.last;
      if (lastCard.type == EventCardType.fate &&
          card.type == EventCardType.emotion) {
        hasConflict = true;
        conflictMessage = '注意：此卡与当前生效的【${lastCard.name}】互斥，将替代前者';
      }
    }

    _drawnHistory.add(card);
    _totalDrawn++;

    emit(CardRevealedState(
      card: card,
      exitConditions: _buildExitConditions(),
      distributorStatus: DeckDistributorStatus(
        busyCount: 2,
        totalCount: 3,
        queueLength: _totalDrawn > 6 ? _totalDrawn - 6 : 0,
      ),
      hasConflict: hasConflict,
      conflictMessage: conflictMessage,
      drawnCount: _totalDrawn,
    ));
  }

  Future<void> _onConfirmCard(
    ConfirmCard event,
    Emitter<CardDrawState> emit,
  ) async {
    _currentTurn++;

    // Check exit conditions
    final conditions = _buildExitConditions();
    for (final cond in conditions) {
      if (cond.isTriggered) {
        emit(ExitTriggeredState(
          condition: cond,
          message: '⚠ 退出条件已触发：【${cond.type.label}】—— 本章事件卡循环即将结束',
        ));
        return;
      }
    }

    // Check if turn limit reached
    if (_currentTurn > _maxTurns) {
      emit(const CardDrawCompleted(
        allDrawnCards: [],
        totalDrawn: 0,
      ));
      return;
    }

    emit(CardStackState(
      remainingCards: _deck.length,
      totalCards: _deck.length + _discardPile.length,
      currentTurn: _currentTurn,
      maxTurns: _maxTurns,
      exitConditions: conditions,
      distributorStatus: const DeckDistributorStatus(
        busyCount: 1,
        totalCount: 3,
      ),
      drawnHistory: _drawnHistory,
    ));
  }

  Future<void> _onSkipCard(
    SkipCard event,
    Emitter<CardDrawState> emit,
  ) async {
    // Add a blank card to history
    final blankCard = EventCard(
      id: 'blank_${DateTime.now().millisecondsSinceEpoch}',
      name: '空白卡',
      description: event.customText ?? '此卡为自由行动卡，不占事件上限，请书写你的江湖故事',
      type: EventCardType.blank,
      isBlank: true,
    );
    _drawnHistory.add(blankCard);
    _totalDrawn++;
    _currentTurn++;

    emit(CardStackState(
      remainingCards: _deck.length,
      totalCards: _deck.length + _discardPile.length,
      currentTurn: _currentTurn,
      maxTurns: _maxTurns,
      exitConditions: _buildExitConditions(),
      distributorStatus: const DeckDistributorStatus(
        busyCount: 1,
        totalCount: 3,
      ),
      drawnHistory: _drawnHistory,
    ));
  }

  Future<void> _onTriggerExit(
    TriggerExit event,
    Emitter<CardDrawState> emit,
  ) async {
    final condition = _buildExitConditions().firstWhere(
      (c) => c.type.name == event.conditionId,
      orElse: () => const ExitCondition(
        type: ExitConditionType.mainComplete,
        current: 0,
        target: 1,
        isTriggered: false,
      ),
    );

    emit(ExitTriggeredState(
      condition: condition,
      message: '⚠ 退出条件已触发：【${condition.type.label}】—— 本章事件卡循环即将结束',
    ));
  }

  void _onReset(
    ResetCardDrawScene event,
    Emitter<CardDrawState> emit,
  ) {
    add(const InitializeCardDrawScene());
  }

  List<ExitCondition> _buildExitConditions() {
    return [
      ExitCondition(
        type: ExitConditionType.mainComplete,
        current: 0,
        target: 1,
        isTriggered: false,
      ),
      ExitCondition(
        type: ExitConditionType.characterAlive,
        current: 1,
        target: 1,
        isTriggered: false,
      ),
      ExitCondition(
        type: ExitConditionType.turnLimit,
        current: _currentTurn,
        target: _maxTurns,
        isTriggered: _currentTurn >= _maxTurns,
      ),
      const ExitCondition(
        type: ExitConditionType.playerChoice,
        current: 0,
        target: 1,
        isTriggered: false,
      ),
    ];
  }

  List<EventCard> _generateEventDeck() {
    return [
      const EventCard(
        id: 'evt_1',
        name: '江湖风波起',
        description: '明教与正派之间的冲突一触即发。你收到密报，明教正在集结兵力，一场大战似乎不可避免。',
        type: EventCardType.mainline,
        triggerCondition: '触发条件：明教大区',
        options: [
          CardOption(id: 'a', text: '前往明教探查', result: '你孤身前往明教...', isPrimary: true),
          CardOption(id: 'b', text: '返回武当报信', result: '你连夜赶回武当...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_2',
        name: '红线相牵',
        description: '在茶馆偶遇一位神秘女子，她递给你一枚同心结信物，言说有要事相商。',
        type: EventCardType.emotion,
        triggerCondition: '触发条件：茶馆场景',
        options: [
          CardOption(id: 'a', text: '与她深谈', result: '你们彻夜长谈...', isPrimary: true),
          CardOption(id: 'b', text: '婉言谢绝', result: '你转身离去...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_3',
        name: '竹林迷踪',
        description: '追踪线索来到一片神秘竹林，却发现此处机关重重，似乎隐藏着不为人知的秘密。',
        type: EventCardType.branch,
        triggerCondition: '触发条件：野外区域',
        options: [
          CardOption(id: 'a', text: '谨慎探索', result: '你步步为营...', isPrimary: true),
          CardOption(id: 'b', text: '快速穿过', result: '你施展轻功...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_4',
        name: '命运的岔路',
        description: '天降异象，你的人生出现了重大转折。是遵循命运的安排，还是逆天改命？',
        type: EventCardType.fate,
        triggerCondition: '触发条件：随机触发',
        isExclusive: true,
        options: [
          CardOption(id: 'a', text: '顺从天命', result: '你决定顺应...', isPrimary: true),
          CardOption(id: 'b', text: '逆天改命', result: '你不甘平庸...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_5',
        name: '时代更迭',
        description: '江湖格局正在悄然变化。新旧势力交替，你站在了历史的十字路口。',
        type: EventCardType.era,
        triggerCondition: '触发条件：章节结局',
        options: [
          CardOption(id: 'a', text: '支持新政', result: '你拥护新势力...', isPrimary: true),
          CardOption(id: 'b', text: '坚守旧序', result: '你誓死追随...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_6',
        name: '空白',
        description: '今日无事，你可以自由行动。这个江湖等待你去书写。',
        type: EventCardType.blank,
        isBlank: true,
        options: [],
      ),
      const EventCard(
        id: 'evt_7',
        name: '切磋武艺',
        description: '路遇一位武林高手，对方提出与你切磋武艺，点到为止。',
        type: EventCardType.numeric,
        triggerCondition: '触发条件：随机遭遇',
        options: [
          CardOption(id: 'a', text: '欣然应战', result: '你来我往...', isPrimary: true),
          CardOption(id: 'b', text: '谦虚请教', result: '你躬身求教...', isPrimary: false),
        ],
      ),
      const EventCard(
        id: 'evt_8',
        name: '奇珍异宝',
        description: '在古董商处发现一件珍稀宝物，卖家开价不菲。',
        type: EventCardType.economic,
        triggerCondition: '触发条件：商贩场景',
        options: [
          CardOption(id: 'a', text: '倾囊购买', result: '你付出全部身家...', isPrimary: true),
          CardOption(id: 'b', text: '讨价还价', result: '你使出三寸不烂之舌...', isPrimary: false),
        ],
      ),
    ];
  }
}
