import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/economy_models.dart';
import '../../../domain/entities/player.dart';

/// Economy phase enum
enum EconomyPhase {
  auctionHouse,
  blackMarket,
  wallet,
}

/// EconomyProvider - ChangeNotifier based state management for economy system
/// 拍卖行/黑市/钱包
class EconomyProvider extends ChangeNotifier {
  // 阶段
  EconomyPhase _phase = EconomyPhase.auctionHouse;
  EconomyPhase get phase => _phase;

  // 玩家钱包
  Wallet _wallet = const Wallet(
    coins: 10000,
    crystals: 500,
    history: [],
  );
  Wallet get wallet => _wallet;

  // 玩家引用（用于更新余额）
  Player? _player;

  // 拍卖行数据
  List<AuctionItem> _auctionItems = [];
  List<AuctionItem> get auctionItems => _auctionItems;

  AuctionFilter _auctionFilter = AuctionFilter.all;
  AuctionFilter get auctionFilter => _auctionFilter;

  AuctionSortBy _auctionSort = AuctionSortBy.endingSoon;
  AuctionSortBy get auctionSort => _auctionSort;

  // 当前选中的拍卖物品
  AuctionItem? _selectedAuctionItem;
  AuctionItem? get selectedAuctionItem => _selectedAuctionItem;

  // 我的竞拍
  List<MyBid> _myBids = [];
  List<MyBid> get myBids => _myBids;

  // 上架表单
  bool _isListingMode = false;
  bool get isListingMode => _isListingMode;

  // 黑市数据
  List<BlackMarketItem> _blackMarketItems = [];
  List<BlackMarketItem> get blackMarketItems => _blackMarketItems;

  DateTime _nextRefreshTime = DateTime.now().add(const Duration(minutes: 30));
  DateTime get nextRefreshTime => _nextRefreshTime;

  // 购买确认弹窗
  BlackMarketItem? _pendingPurchase;
  BlackMarketItem? get pendingPurchase => _pendingPurchase;

  // 竞拍确认
  AuctionItem? _pendingBid;
  AuctionItem? get pendingBid => _pendingBid;

  // 刷新倒计时
  Timer? _refreshTimer;
  Duration _blackMarketCountdown = Duration.zero;
  Duration get blackMarketCountdown => _blackMarketCountdown;

  // 拍卖倒计时更新
  Timer? _auctionTimer;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  // 当前玩家ID（模拟）
  final String _playerId = 'player_1';
  final String _playerName = '江湖游侠';

  EconomyProvider() {
    _initializeMockData();
    _startRefreshTimer();
    _startAuctionTimer();
  }

  /// 初始化模拟数据
  void _initializeMockData() {
    final now = DateTime.now();

    // 拍卖行物品
    _auctionItems = [
      AuctionItem(
        id: 'auction_1',
        name: '倚天剑',
        description: '武林至尊，宝刀屠龙',
        category: 'weapon',
        rarity: 5,
        currentPrice: 50000,
        buyoutPrice: 80000,
        sellerId: 'player_2',
        sellerName: '灭绝师太',
        endTime: now.add(const Duration(hours: 2)),
        bidCount: 12,
        highestBidderId: 'player_3',
        highestBidderName: '张无忌',
        sellerInitPrice: 30000,
      ),
      AuctionItem(
        id: 'auction_2',
        name: '玄铁重剑',
        description: '重剑无锋，大巧不工',
        category: 'weapon',
        rarity: 4,
        currentPrice: 25000,
        buyoutPrice: 40000,
        sellerId: 'player_4',
        sellerName: '独臂杨过',
        endTime: now.add(const Duration(hours: 5)),
        bidCount: 8,
        highestBidderId: _playerId,
        highestBidderName: _playerName,
        sellerInitPrice: 15000,
      ),
      AuctionItem(
        id: 'auction_3',
        name: '九阴真经',
        description: '天下武学总纲',
        category: 'consumable',
        rarity: 5,
        currentPrice: 100000,
        buyoutPrice: 150000,
        sellerId: 'player_5',
        sellerName: '周伯通',
        endTime: now.add(const Duration(hours: 12)),
        bidCount: 25,
        highestBidderId: 'player_6',
        highestBidderName: '郭靖',
        sellerInitPrice: 50000,
      ),
      AuctionItem(
        id: 'auction_4',
        name: '金丝软甲',
        description: '刀枪不入，水火不侵',
        category: 'armor',
        rarity: 4,
        currentPrice: 18000,
        buyoutPrice: 30000,
        sellerId: 'player_7',
        sellerName: '黄蓉',
        endTime: now.add(const Duration(hours: 1)),
        bidCount: 5,
        highestBidderId: null,
        highestBidderName: null,
        sellerInitPrice: 10000,
      ),
      AuctionItem(
        id: 'auction_5',
        name: '黑玉断续膏',
        description: '疗伤圣药，可接骨续筋',
        category: 'consumable',
        rarity: 3,
        currentPrice: 5000,
        buyoutPrice: 8000,
        sellerId: 'player_8',
        sellerName: '胡青牛',
        endTime: now.add(const Duration(minutes: 30)),
        bidCount: 3,
        highestBidderId: 'player_9',
        highestBidderName: '张无忌',
        sellerInitPrice: 3000,
      ),
      AuctionItem(
        id: 'auction_6',
        name: '千年寒玉',
        description: '打造神兵利器之上品材料',
        category: 'material',
        rarity: 4,
        currentPrice: 15000,
        buyoutPrice: 25000,
        sellerId: 'player_10',
        sellerName: '张三丰',
        endTime: now.add(const Duration(hours: 8)),
        bidCount: 6,
        highestBidderId: null,
        highestBidderName: null,
        sellerInitPrice: 8000,
      ),
    ];

    // 我的竞拍
    _myBids = [
      MyBid(
        auctionId: 'auction_2',
        itemName: '玄铁重剑',
        myBid: 25000,
        currentHighest: 25000,
        endTime: now.add(const Duration(hours: 5)),
        isHighestBidder: true,
        status: 'winning',
      ),
      MyBid(
        auctionId: 'auction_5',
        itemName: '黑玉断续膏',
        myBid: 5000,
        currentHighest: 5000,
        endTime: now.add(const Duration(minutes: 30)),
        isHighestBidder: true,
        status: 'winning',
      ),
    ];

    // 黑市物品
    _blackMarketItems = [
      BlackMarketItem(
        id: 'bm_1',
        name: '化骨绵掌秘笈',
        description: '阴毒武功，中者骨软筋酥',
        category: 'consumable',
        rarity: 4,
        price: 30000,
        refreshTime: now.add(const Duration(minutes: 30)),
      ),
      BlackMarketItem(
        id: 'bm_2',
        name: '生死符',
        description: '天山童姥的独门暗器',
        category: 'weapon',
        rarity: 5,
        price: 50000,
        refreshTime: now.add(const Duration(minutes: 30)),
      ),
      BlackMarketItem(
        id: 'bm_3',
        name: '冰蚕',
        description: '解毒培元，驱除寒毒',
        category: 'material',
        rarity: 3,
        price: 8000,
        refreshTime: now.add(const Duration(minutes: 30)),
      ),
      BlackMarketItem(
        id: 'bm_4',
        name: '悲酥清风',
        description: '无色无味，中者泪流不止',
        category: 'consumable',
        rarity: 4,
        price: 15000,
        refreshTime: now.add(const Duration(minutes: 30)),
      ),
    ];

    // 交易历史
    _wallet = Wallet(
      coins: 10000,
      crystals: 500,
      history: [
        Transaction(
          id: 'tx_1',
          type: 'deposit',
          amount: 5000,
          itemName: '充值',
          timestamp: now.subtract(const Duration(days: 1)),
          status: 'completed',
        ),
        Transaction(
          id: 'tx_2',
          type: 'purchase',
          amount: -2000,
          itemName: '普通丹药',
          timestamp: now.subtract(const Duration(hours: 5)),
          status: 'completed',
        ),
        Transaction(
          id: 'tx_3',
          type: 'bid',
          amount: -25000,
          itemName: '玄铁重剑',
          timestamp: now.subtract(const Duration(hours: 2)),
          status: 'completed',
        ),
        Transaction(
          id: 'tx_4',
          type: 'sale',
          amount: 15000,
          itemName: '打狗棒（已售出）',
          timestamp: now.subtract(const Duration(days: 2)),
          status: 'completed',
        ),
      ],
    );
  }

  /// 切换阶段
  void switchPhase(EconomyPhase newPhase) {
    _phase = newPhase;
    _selectedAuctionItem = null;
    _pendingPurchase = null;
    _pendingBid = null;
    _isListingMode = false;
    notifyListeners();
  }

  /// 拍卖行筛选
  void setAuctionFilter(AuctionFilter filter) {
    _auctionFilter = filter;
    notifyListeners();
  }

  /// 拍卖行排序
  void setAuctionSort(AuctionSortBy sort) {
    _auctionSort = sort;
    notifyListeners();
  }

  /// 获取过滤和排序后的拍卖列表
  List<AuctionItem> get filteredAuctionItems {
    var items = List<AuctionItem>.from(_auctionItems);

    // 过滤
    if (_auctionFilter != AuctionFilter.all) {
      items = items.where((item) {
        switch (_auctionFilter) {
          case AuctionFilter.weapon:
            return item.category == 'weapon';
          case AuctionFilter.armor:
            return item.category == 'armor';
          case AuctionFilter.consumable:
            return item.category == 'consumable';
          case AuctionFilter.material:
            return item.category == 'material';
          default:
            return true;
        }
      }).toList();
    }

    // 排序
    switch (_auctionSort) {
      case AuctionSortBy.endingSoon:
        items.sort((a, b) => a.endTime.compareTo(b.endTime));
        break;
      case AuctionSortBy.priceLow:
        items.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case AuctionSortBy.priceHigh:
        items.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case AuctionSortBy.newest:
        items.sort((a, b) => b.sellerInitPrice.compareTo(a.sellerInitPrice));
        break;
    }

    return items;
  }

  /// 选择拍卖物品
  void selectAuctionItem(AuctionItem item) {
    _selectedAuctionItem = item;
    notifyListeners();
  }

  /// 清除选择
  void clearAuctionSelection() {
    _selectedAuctionItem = null;
    _pendingBid = null;
    notifyListeners();
  }

  /// 进入上架模式
  void enterListingMode() {
    _isListingMode = true;
    notifyListeners();
  }

  /// 退出上架模式
  void exitListingMode() {
    _isListingMode = false;
    notifyListeners();
  }

  /// 出价（待确认）
  void prepareBid(AuctionItem item, int amount) {
    if (amount > _wallet.coins) {
      _error = '金币不足';
      notifyListeners();
      return;
    }
    _pendingBid = item;
    notifyListeners();
  }

  /// 确认出价
  void confirmBid(int amount) {
    if (_pendingBid == null) return;

    final item = _pendingBid!;
    final bidAmount = amount;

    // 扣除金币
    _wallet = _wallet.copyWith(
      coins: _wallet.coins - bidAmount,
      history: [
        Transaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          type: 'bid',
          amount: -bidAmount,
          itemName: item.name,
          timestamp: DateTime.now(),
          status: 'completed',
        ),
        ..._wallet.history,
      ],
    );

    // 更新拍卖物品
    final index = _auctionItems.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _auctionItems[index] = _auctionItems[index].copyWith(
        currentPrice: bidAmount,
        bidCount: _auctionItems[index].bidCount + 1,
        highestBidderId: _playerId,
        highestBidderName: _playerName,
      );
    }

    // 更新我的竞拍
    final existingBidIndex = _myBids.indexWhere((b) => b.auctionId == item.id);
    if (existingBidIndex >= 0) {
      _myBids[existingBidIndex] = MyBid(
        auctionId: item.id,
        itemName: item.name,
        myBid: bidAmount,
        currentHighest: bidAmount,
        endTime: item.endTime,
        isHighestBidder: true,
        status: 'winning',
      );
    } else {
      _myBids.add(MyBid(
        auctionId: item.id,
        itemName: item.name,
        myBid: bidAmount,
        currentHighest: bidAmount,
        endTime: item.endTime,
        isHighestBidder: true,
        status: 'winning',
      ));
    }

    _pendingBid = null;
    notifyListeners();
  }

  /// 取消出价
  void cancelBid() {
    _pendingBid = null;
    notifyListeners();
  }

  /// 一口价购买
  void buyout(AuctionItem item) {
    if (item.buyoutPrice > _wallet.coins) {
      _error = '金币不足';
      notifyListeners();
      return;
    }

    // 扣除金币
    _wallet = _wallet.copyWith(
      coins: _wallet.coins - item.buyoutPrice,
      history: [
        Transaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          type: 'buyout',
          amount: -item.buyoutPrice,
          itemName: item.name,
          timestamp: DateTime.now(),
          status: 'completed',
        ),
        ..._wallet.history,
      ],
    );

    // 从拍卖列表移除
    _auctionItems.removeWhere((i) => i.id == item.id);

    _selectedAuctionItem = null;
    notifyListeners();
  }

  /// 准备购买黑市物品
  void prepareBlackMarketPurchase(BlackMarketItem item) {
    _pendingPurchase = item;
    notifyListeners();
  }

  /// 取消购买
  void cancelPurchase() {
    _pendingPurchase = null;
    notifyListeners();
  }

  /// 确认购买黑市物品
  void confirmBlackMarketPurchase() {
    if (_pendingPurchase == null) return;

    final item = _pendingPurchase!;

    if (item.price > _wallet.coins) {
      _error = '金币不足';
      notifyListeners();
      return;
    }

    // 扣除金币
    _wallet = _wallet.copyWith(
      coins: _wallet.coins - item.price,
      history: [
        Transaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          type: 'purchase',
          amount: -item.price,
          itemName: item.name,
          timestamp: DateTime.now(),
          status: 'completed',
        ),
        ..._wallet.history,
      ],
    );

    // 标记黑市物品为已售
    final index = _blackMarketItems.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _blackMarketItems[index] = BlackMarketItem(
        id: item.id,
        name: item.name,
        description: item.description,
        category: item.category,
        rarity: item.rarity,
        price: item.price,
        refreshTime: item.refreshTime,
        isSold: true,
      );
    }

    _pendingPurchase = null;
    notifyListeners();
  }

  /// 刷新黑市
  void refreshBlackMarket() {
    _isLoading = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      final now = DateTime.now();

      // 重新生成黑市物品
      _blackMarketItems = [
        BlackMarketItem(
          id: 'bm_new_1',
          name: '吸星大法',
          description: '吸取他人内力为己用',
          category: 'consumable',
          rarity: 5,
          price: 80000,
          refreshTime: now.add(const Duration(minutes: 30)),
        ),
        BlackMarketItem(
          id: 'bm_new_2',
          name: '北冥神功',
          description: '逍遥派内功绝学',
          category: 'consumable',
          rarity: 5,
          price: 100000,
          refreshTime: now.add(const Duration(minutes: 30)),
        ),
        BlackMarketItem(
          id: 'bm_new_3',
          name: '软猬甲',
          description: '桃花岛镇岛之宝',
          category: 'armor',
          rarity: 4,
          price: 35000,
          refreshTime: now.add(const Duration(minutes: 30)),
        ),
        BlackMarketItem(
          id: 'bm_new_4',
          name: '通犀地龙丸',
          description: '解毒圣品，百毒不侵',
          category: 'consumable',
          rarity: 4,
          price: 20000,
          refreshTime: now.add(const Duration(minutes: 30)),
        ),
      ];

      _nextRefreshTime = now.add(const Duration(minutes: 30));
      _blackMarketCountdown = Duration.zero;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// 启动黑市刷新倒计时
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final remaining = _nextRefreshTime.difference(now);

      if (remaining.isNegative || remaining == Duration.zero) {
        _blackMarketCountdown = Duration.zero;
        // 自动刷新黑市
        _autoRefreshBlackMarket();
      } else {
        _blackMarketCountdown = remaining;
      }
      notifyListeners();
    });
  }

  void _autoRefreshBlackMarket() {
    refreshBlackMarket();
  }

  /// 启动拍卖倒计时更新
  void _startAuctionTimer() {
    _auctionTimer?.cancel();
    _auctionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 检查已结束的拍卖
      _checkEndedAuctions();
      notifyListeners();
    });
  }

  void _checkEndedAuctions() {
    final now = DateTime.now();
    for (final bid in _myBids) {
      if (now.isAfter(bid.endTime)) {
        // 更新竞拍状态
        final index = _myBids.indexWhere((b) => b.auctionId == bid.auctionId);
        if (index >= 0) {
          _myBids[index] = MyBid(
            auctionId: bid.auctionId,
            itemName: bid.itemName,
            myBid: bid.myBid,
            currentHighest: bid.currentHighest,
            endTime: bid.endTime,
            isHighestBidder: bid.isHighestBidder,
            status: bid.isHighestBidder ? 'won' : 'lost',
          );
        }
      }
    }
  }

  /// 获取过滤后的黑市物品（排除已售）
  List<BlackMarketItem> get availableBlackMarketItems {
    return _blackMarketItems.where((item) => !item.isSold).toList();
  }

  /// 获取我正在竞拍且领先的
  List<MyBid> get winningBids {
    return _myBids.where((b) => b.status == 'winning' && b.isHighestBidder).toList();
  }

  /// 获取我被超越的
  List<MyBid> get outbidItems {
    return _myBids.where((b) => !b.isHighestBidder && b.status == 'winning').toList();
  }

  /// 清理错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 设置玩家引用（用于同步余额）
  void setPlayer(Player player) {
    _player = player;
    notifyListeners();
  }

  /// 格式化时间剩余
  String formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '已结束';

    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}小时${minutes}分';
    } else if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  /// 获取稀有度颜色
  static String getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return 'gray';
      case 2:
        return 'green';
      case 3:
        return 'blue';
      case 4:
        return 'purple';
      case 5:
        return 'orange';
      default:
        return 'gray';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _auctionTimer?.cancel();
    super.dispose();
  }
}
