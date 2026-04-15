/// 拍卖行/黑市/钱包相关的数据模型
library;

/// 拍卖物品
class AuctionItem {
  final String id;
  final String name;
  final String description;
  final String category; // weapon, armor, consumable, material
  final int rarity; // 1=common, 2=uncommon, 3=rare, 4=epic, 5=legendary
  final int currentPrice;
  final int buyoutPrice;
  final String? sellerId;
  final String? sellerName;
  final DateTime endTime;
  final int bidCount;
  final String? highestBidderId;
  final String? highestBidderName;
  final int sellerInitPrice;

  const AuctionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.currentPrice,
    required this.buyoutPrice,
    this.sellerId,
    this.sellerName,
    required this.endTime,
    this.bidCount = 0,
    this.highestBidderId,
    this.highestBidderName,
    required this.sellerInitPrice,
  });

  AuctionItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? rarity,
    int? currentPrice,
    int? buyoutPrice,
    String? sellerId,
    String? sellerName,
    DateTime? endTime,
    int? bidCount,
    String? highestBidderId,
    String? highestBidderName,
    int? sellerInitPrice,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      currentPrice: currentPrice ?? this.currentPrice,
      buyoutPrice: buyoutPrice ?? this.buyoutPrice,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      endTime: endTime ?? this.endTime,
      bidCount: bidCount ?? this.bidCount,
      highestBidderId: highestBidderId ?? this.highestBidderId,
      highestBidderName: highestBidderName ?? this.highestBidderName,
      sellerInitPrice: sellerInitPrice ?? this.sellerInitPrice,
    );
  }

  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get isEnded => DateTime.now().isAfter(endTime);
}

/// 黑市物品
class BlackMarketItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final int rarity;
  final int price;
  final DateTime refreshTime;
  final bool isSold;

  const BlackMarketItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.price,
    required this.refreshTime,
    this.isSold = false,
  });

  Duration get timeUntilRefresh => refreshTime.difference(DateTime.now());
  bool get needsRefresh => DateTime.now().isAfter(refreshTime);
}

/// 交易记录
class Transaction {
  final String id;
  final String type; // bid, buyout, purchase, sale, deposit, withdraw
  final int amount;
  final String itemName;
  final DateTime timestamp;
  final String status; // pending, completed, failed, cancelled

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.itemName,
    required this.timestamp,
    required this.status,
  });
}

/// 钱包数据
class Wallet {
  final int coins;
  final int crystals;
  final List<Transaction> history;

  const Wallet({
    required this.coins,
    required this.crystals,
    this.history = const [],
  });

  Wallet copyWith({
    int? coins,
    int? crystals,
    List<Transaction>? history,
  }) {
    return Wallet(
      coins: coins ?? this.coins,
      crystals: crystals ?? this.crystals,
      history: history ?? this.history,
    );
  }
}

/// 用户正在竞拍的物品
class MyBid {
  final String auctionId;
  final String itemName;
  final int myBid;
  final int currentHighest;
  final DateTime endTime;
  final bool isHighestBidder;
  final String status; // winning, outbid, won, lost

  const MyBid({
    required this.auctionId,
    required this.itemName,
    required this.myBid,
    required this.currentHighest,
    required this.endTime,
    required this.isHighestBidder,
    required this.status,
  });
}

/// 竞拍过滤器
enum AuctionFilter {
  all,
  weapon,
  armor,
  consumable,
  material,
}

enum AuctionSortBy {
  endingSoon,
  priceLow,
  priceHigh,
  newest,
}
