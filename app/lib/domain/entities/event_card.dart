import 'package:flutter/material.dart';

/// Event card types - 5 core types from Chapter 7 design
enum EventCardType {
  /// 主线剧情卡 - Deep vermillion #8B2020
  mainline,

  /// 情感联结卡 - Warm amber #D4A843
  emotion,

  /// 支线故事卡 - Turquoise green #4A7A6A
  branch,

  /// 命运转折卡 - Dark ink purple #4A2A5A
  fate,

  /// 时代印记卡 - Bronze green #5A7A5A
  era,

  /// 机制体验卡 - Indigo #3A5A8A
  mechanism,

  /// 数值提升卡 - Emerald #3A8A5A
  numeric,

  /// 经济系统卡 - Earth yellow #8A7A3A
  economic,

  /// 空白卡 - Charcoal #4A4A4A
  blank,
}

/// Extension for EventCardType styling
extension EventCardTypeExtension on EventCardType {
  String get label {
    switch (this) {
      case EventCardType.mainline:
        return '主线';
      case EventCardType.emotion:
        return '情感';
      case EventCardType.branch:
        return '支线';
      case EventCardType.fate:
        return '命运';
      case EventCardType.era:
        return '时代';
      case EventCardType.mechanism:
        return '机制';
      case EventCardType.numeric:
        return '数值';
      case EventCardType.economic:
        return '经济';
      case EventCardType.blank:
        return '空白';
    }
  }

  Color get primaryColor {
    switch (this) {
      case EventCardType.mainline:
        return const Color(0xFF8B2020);
      case EventCardType.emotion:
        return const Color(0xFFD4A843);
      case EventCardType.branch:
        return const Color(0xFF4A7A6A);
      case EventCardType.fate:
        return const Color(0xFF4A2A5A);
      case EventCardType.era:
        return const Color(0xFF5A7A5A);
      case EventCardType.mechanism:
        return const Color(0xFF3A5A8A);
      case EventCardType.numeric:
        return const Color(0xFF3A8A5A);
      case EventCardType.economic:
        return const Color(0xFF8A7A3A);
      case EventCardType.blank:
        return const Color(0xFF4A4A4A);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case EventCardType.mainline:
        return const Color(0xFF6B3A1A);
      case EventCardType.emotion:
        return const Color(0xFF6B4423);
      case EventCardType.branch:
        return const Color(0xFF2D4A3F);
      case EventCardType.fate:
        return const Color(0xFF1A2A4A);
      case EventCardType.era:
        return const Color(0xFF3A5A3A);
      case EventCardType.mechanism:
        return const Color(0xFF2A3A5A);
      case EventCardType.numeric:
        return const Color(0xFF2A6A3A);
      case EventCardType.economic:
        return const Color(0xFF6A5A2A);
      case EventCardType.blank:
        return const Color(0xFF2A2A2A);
    }
  }

  Color get glowColor {
    switch (this) {
      case EventCardType.mainline:
        return const Color(0xFFC94A4A);
      case EventCardType.emotion:
        return const Color(0xFFE8C060);
      case EventCardType.branch:
        return const Color(0xFF5A9A7A);
      case EventCardType.fate:
        return const Color(0xFF7A4A9A);
      case EventCardType.era:
        return const Color(0xFF6A8A5A);
      case EventCardType.mechanism:
        return const Color(0xFF5A7AAA);
      case EventCardType.numeric:
        return const Color(0xFF5AAA7A);
      case EventCardType.economic:
        return const Color(0xFFAAAA5A);
      case EventCardType.blank:
        return const Color(0xFF6A6A6A);
    }
  }

  IconData get icon {
    switch (this) {
      case EventCardType.mainline:
        return Icons.auto_awesome;
      case EventCardType.emotion:
        return Icons.favorite;
      case EventCardType.branch:
        return Icons.explore;
      case EventCardType.fate:
        return Icons.balance;
      case EventCardType.era:
        return Icons.history_edu;
      case EventCardType.mechanism:
        return Icons.settings;
      case EventCardType.numeric:
        return Icons.trending_up;
      case EventCardType.economic:
        return Icons.monetization_on;
      case EventCardType.blank:
        return Icons.edit_note;
    }
  }
}

/// Exit condition types
enum ExitConditionType {
  mainComplete,
  characterAlive,
  turnLimit,
  playerChoice,
}

/// Extension for ExitConditionType
extension ExitConditionTypeExtension on ExitConditionType {
  String get label {
    switch (this) {
      case ExitConditionType.mainComplete:
        return '主线完成';
      case ExitConditionType.characterAlive:
        return '角色存活';
      case ExitConditionType.turnLimit:
        return '剩余回合';
      case ExitConditionType.playerChoice:
        return '玩家主动选择';
    }
  }

  IconData get icon {
    switch (this) {
      case ExitConditionType.mainComplete:
        return Icons.flag;
      case ExitConditionType.characterAlive:
        return Icons.person;
      case ExitConditionType.turnLimit:
        return Icons.timer;
      case ExitConditionType.playerChoice:
        return Icons.touch_app;
    }
  }

  Color get activeColor {
    switch (this) {
      case ExitConditionType.mainComplete:
        return const Color(0xFFC94A4A);
      case ExitConditionType.characterAlive:
        return const Color(0xFF4A7A6A);
      case ExitConditionType.turnLimit:
        return const Color(0xFFD4A843);
      case ExitConditionType.playerChoice:
        return const Color(0xFF4A4A4A);
    }
  }
}

/// Represents an event card in the ChronoCards system
class EventCard {
  final String id;
  final String name;
  final String description;
  final EventCardType type;
  final String triggerCondition;
  final List<CardOption> options;
  final bool isExclusive;
  final String? conflictingCardId;
  final bool isBlank;

  const EventCard({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.triggerCondition = '',
    this.options = const [],
    this.isExclusive = false,
    this.conflictingCardId,
    this.isBlank = false,
  });

  EventCard copyWith({
    String? id,
    String? name,
    String? description,
    EventCardType? type,
    String? triggerCondition,
    List<CardOption>? options,
    bool? isExclusive,
    String? conflictingCardId,
    bool? isBlank,
  }) {
    return EventCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      options: options ?? this.options,
      isExclusive: isExclusive ?? this.isExclusive,
      conflictingCardId: conflictingCardId ?? this.conflictingCardId,
      isBlank: isBlank ?? this.isBlank,
    );
  }
}

/// Card option for player choices
class CardOption {
  final String id;
  final String text;
  final bool isPrimary;

  const CardOption({
    required this.id,
    required this.text,
    this.isPrimary = true,
  });
}

/// Exit condition state
class ExitCondition {
  final ExitConditionType type;
  final int current;
  final int target;
  final bool isTriggered;

  const ExitCondition({
    required this.type,
    required this.current,
    required this.target,
    this.isTriggered = false,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get isComplete => current >= target;
}

/// Deck distributor status
class DeckDistributorStatus {
  final int busyCount;
  final int totalCount;
  final int queueLength;

  const DeckDistributorStatus({
    required this.busyCount,
    required this.totalCount,
    this.queueLength = 0,
  });

  double get density => totalCount > 0 ? busyCount / totalCount : 0.0;

  DeckDensityLevel get densityLevel {
    if (density >= 1.0) return DeckDensityLevel.overloaded;
    if (density >= 0.8) return DeckDensityLevel.full;
    if (density >= 0.5) return DeckDensityLevel.busy;
    if (density > 0) return DeckDensityLevel.normal;
    return DeckDensityLevel.idle;
  }
}

enum DeckDensityLevel {
  idle,
  normal,
  busy,
  full,
  overloaded,
}

extension DeckDensityLevelExtension on DeckDensityLevel {
  String get label {
    switch (this) {
      case DeckDensityLevel.idle:
        return '发牌员空闲';
      case DeckDensityLevel.normal:
        return '正常运转';
      case DeckDensityLevel.busy:
        return '发牌员忙碌中';
      case DeckDensityLevel.full:
        return '密度偏高';
      case DeckDensityLevel.overloaded:
        return '超载，事件延迟';
    }
  }

  Color get color {
    switch (this) {
      case DeckDensityLevel.idle:
      case DeckDensityLevel.normal:
        return const Color(0xFF4A7A6A);
      case DeckDensityLevel.busy:
        return const Color(0xFFD4A843);
      case DeckDensityLevel.full:
        return const Color(0xFFC94A4A);
      case DeckDensityLevel.overloaded:
        return const Color(0xFF8B2020);
    }
  }
}
