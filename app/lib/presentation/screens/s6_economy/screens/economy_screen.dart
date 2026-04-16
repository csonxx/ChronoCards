import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/battle_colors.dart';
import '../../../../domain/entities/economy_models.dart';
import '../../../providers/economy_provider.dart';
import '../widgets/economy_widgets.dart';

/// 经济系统主界面 - 拍卖行/黑市/钱包
class EconomyScreen extends StatelessWidget {
  const EconomyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EconomyProvider(),
      child: const EconomyView(),
    );
  }
}

class EconomyView extends StatefulWidget {
  const EconomyView({super.key});

  @override
  State<EconomyView> createState() => _EconomyViewState();
}

class _EconomyViewState extends State<EconomyView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final provider = context.read<EconomyProvider>();
        switch (_tabController.index) {
          case 0:
            provider.switchPhase(EconomyPhase.auctionHouse);
            break;
          case 1:
            provider.switchPhase(EconomyPhase.blackMarket);
            break;
          case 2:
            provider.switchPhase(EconomyPhase.wallet);
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BattleColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAuctionHouseTab(),
                  _buildBlackMarketTab(),
                  _buildWalletTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<EconomyProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: BattleColors.secondaryBg,
            border: Border(
              bottom: BorderSide(color: BattleColors.border.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '经济系统',
                style: TextStyle(
                  color: BattleColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 钱包快捷显示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BattleColors.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.wallet.coins}',
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BattleColors.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond, color: AppTheme.accentMystic, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.wallet.crystals}',
                      style: const TextStyle(
                        color: AppTheme.accentMystic,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: BattleColors.secondaryBg,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accentGold,
        labelColor: AppTheme.accentGold,
        unselectedLabelColor: BattleColors.textPrimary.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(
            icon: Icon(Icons.gavel, size: 20),
            text: '拍卖行',
          ),
          Tab(
            icon: Icon(Icons.local_offer, size: 20),
            text: '黑市',
          ),
          Tab(
            icon: Icon(Icons.account_balance_wallet, size: 20),
            text: '钱包',
          ),
        ],
      ),
    );
  }

  /// 拍卖行标签页
  Widget _buildAuctionHouseTab() {
    return Consumer<EconomyProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 工具栏
            _buildAuctionToolbar(provider),
            // 拍卖行内容
            Expanded(
              child: provider.selectedAuctionItem != null
                  ? _buildAuctionDetail(provider)
                  : _buildAuctionList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuctionToolbar(EconomyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 分类筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip(
                  label: '全部',
                  isSelected: provider.auctionFilter == AuctionFilter.all,
                  onTap: () => provider.setAuctionFilter(AuctionFilter.all),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '武器',
                  isSelected: provider.auctionFilter == AuctionFilter.weapon,
                  onTap: () => provider.setAuctionFilter(AuctionFilter.weapon),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '防具',
                  isSelected: provider.auctionFilter == AuctionFilter.armor,
                  onTap: () => provider.setAuctionFilter(AuctionFilter.armor),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '消耗品',
                  isSelected: provider.auctionFilter == AuctionFilter.consumable,
                  onTap: () => provider.setAuctionFilter(AuctionFilter.consumable),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '材料',
                  isSelected: provider.auctionFilter == AuctionFilter.material,
                  onTap: () => provider.setAuctionFilter(AuctionFilter.material),
                ),
                const SizedBox(width: 16),
                // 排序
                PopupMenuButton<AuctionSortBy>(
                  initialValue: provider.auctionSort,
                  onSelected: (sort) => provider.setAuctionSort(sort),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: AuctionSortBy.endingSoon,
                      child: Text('即将结束'),
                    ),
                    const PopupMenuItem(
                      value: AuctionSortBy.priceLow,
                      child: Text('价格从低到高'),
                    ),
                    const PopupMenuItem(
                      value: AuctionSortBy.priceHigh,
                      child: Text('价格从高到低'),
                    ),
                    const PopupMenuItem(
                      value: AuctionSortBy.newest,
                      child: Text('最新上架'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: BattleColors.secondaryBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BattleColors.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sort, color: BattleColors.textPrimary, size: 16),
                        SizedBox(width: 4),
                        Text('排序', style: TextStyle(color: BattleColors.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 我的竞拍切换
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMyBidsSheet(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.manaBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.manaBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility, color: AppTheme.manaBlue, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '我的竞拍 (${provider.myBids.length})',
                          style: const TextStyle(
                            color: AppTheme.manaBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: provider.enterListingMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: AppTheme.accentGold, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '上架物品',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionList(EconomyProvider provider) {
    final items = provider.filteredAuctionItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, color: BattleColors.textPrimary.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              '暂无拍卖物品',
              style: TextStyle(
                color: BattleColors.textPrimary.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AuctionItemCard(
          name: item.name,
          description: item.description,
          rarity: item.rarity,
          currentPrice: item.currentPrice,
          buyoutPrice: item.buyoutPrice,
          timeRemaining: provider.formatDuration(item.timeRemaining),
          bidCount: item.bidCount,
          isHighestBidder: item.highestBidderId == 'player_1',
          onTap: () => provider.selectAuctionItem(item),
        );
      },
    );
  }

  Widget _buildAuctionDetail(EconomyProvider provider) {
    final item = provider.selectedAuctionItem!;
    final isHighestBidder = item.highestBidderId == 'player_1';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回按钮
          Row(
            children: [
              GestureDetector(
                onTap: provider.clearAuctionSelection,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BattleColors.secondaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: BattleColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: BattleColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 物品详情卡
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BattleColors.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RarityColors.getColor(item.rarity).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: RarityColors.getColor(item.rarity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getRarityText(item.rarity),
                      style: TextStyle(
                        color: RarityColors.getColor(item.rarity),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.category,
                      style: TextStyle(
                        color: BattleColors.textPrimary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: BattleColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person, color: BattleColors.textPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '卖家: ${item.sellerName ?? "未知"}',
                      style: TextStyle(
                        color: BattleColors.textPrimary.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 当前竞价信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BattleColors.secondaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPriceColumn('当前价格', item.currentPrice, AppTheme.accentGold),
                    _buildPriceColumn('一口价', item.buyoutPrice, AppTheme.energyYellow),
                    _buildPriceColumn('竞价次数', item.bidCount.toDouble(), AppTheme.manaBlue),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.timer, color: BattleColors.textPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '剩余时间: ${provider.formatDuration(item.timeRemaining)}',
                      style: const TextStyle(
                        color: BattleColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isHighestBidder)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.manaBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '当前领先',
                          style: TextStyle(
                            color: AppTheme.manaBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.highestBidderName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '最高出价者: ${item.highestBidderName}',
                    style: TextStyle(
                      color: BattleColors.textPrimary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 竞价输入
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BattleColors.secondaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '出价',
                  style: TextStyle(
                    color: BattleColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bidController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: BattleColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '输入价格',
                          hintStyle: TextStyle(color: BattleColors.textPrimary.withOpacity(0.4)),
                          filled: true,
                          fillColor: BattleColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.monetization_on, color: AppTheme.accentGold),
                        ),
                        onChanged: (value) {
                          // 实时验证
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final amount = int.tryParse(_bidController.text);
                        if (amount != null && amount > item.currentPrice) {
                          provider.prepareBid(item, amount);
                          _showBidConfirmDialog(context, provider, amount);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '出价',
                          style: TextStyle(
                            color: BattleColors.primaryBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 一口价购买
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _showBuyoutConfirmDialog(context, provider, item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.energyYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.energyYellow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on, color: AppTheme.energyYellow),
                    const SizedBox(width: 8),
                    Text(
                      '一口价购买 (${_formatPrice(item.buyoutPrice)})',
                      style: const TextStyle(
                        color: AppTheme.energyYellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(String label, num value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: BattleColors.textPrimary.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value is int ? _formatPrice(value) : value.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showBidConfirmDialog(BuildContext context, EconomyProvider provider, int amount) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '确认出价',
        message: '您将出价 ${_formatPrice(amount)} 金币购买 "${provider.selectedAuctionItem!.name}"',
        confirmText: '确认出价',
        onConfirm: () {
          provider.confirmBid(amount);
          _bidController.clear();
          Navigator.pop(context);
        },
        onCancel: () {
          provider.cancelBid();
          _bidController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBuyoutConfirmDialog(BuildContext context, EconomyProvider provider, AuctionItem item) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '一口价购买',
        message: '您将花费 ${_formatPrice(item.buyoutPrice)} 金币立即购买 "${item.name}"',
        confirmText: '立即购买',
        confirmColor: AppTheme.energyYellow,
        onConfirm: () {
          provider.buyout(item);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMyBidsSheet(BuildContext context, EconomyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BattleColors.secondaryBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BattleColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '我的竞拍',
              style: TextStyle(
                color: BattleColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.myBids.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无竞拍记录',
                  style: TextStyle(
                    color: BattleColors.textPrimary.withOpacity(0.6),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: provider.myBids.length,
                  itemBuilder: (context, index) {
                    final bid = provider.myBids[index];
                    return MyBidItem(
                      itemName: bid.itemName,
                      myBid: bid.myBid,
                      currentHighest: bid.currentHighest,
                      timeRemaining: provider.formatDuration(bid.endTime.difference(DateTime.now())),
                      isHighestBidder: bid.isHighestBidder,
                      status: bid.status,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 黑市标签页
  Widget _buildBlackMarketTab() {
    return Consumer<EconomyProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 黑市刷新倒计时
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BattleColors.secondaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.healthRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh, color: AppTheme.healthRed, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '黑市刷新',
                    style: TextStyle(
                      color: BattleColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    provider.blackMarketCountdown == Duration.zero
                        ? '即将刷新...'
                        : provider.formatDuration(provider.blackMarketCountdown),
                    style: const TextStyle(
                      color: AppTheme.healthRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: provider.isLoading ? null : provider.refreshBlackMarket,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.healthRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.healthRed,
                              ),
                            )
                          : const Text(
                              '刷新',
                              style: TextStyle(
                                color: AppTheme.healthRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // 黑市物品列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: provider.availableBlackMarketItems.length,
                itemBuilder: (context, index) {
                  final item = provider.availableBlackMarketItems[index];
                  return BlackMarketItemCard(
                    name: item.name,
                    description: item.description,
                    rarity: item.rarity,
                    price: item.price,
                    onBuy: () {
                      provider.prepareBlackMarketPurchase(item);
                      _showPurchaseConfirmDialog(context, provider, item);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseConfirmDialog(BuildContext context, EconomyProvider provider, BlackMarketItem item) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '确认购买',
        message: '您将花费 ${_formatPrice(item.price)} 金币购买 "${item.name}"',
        confirmText: '购买',
        confirmColor: AppTheme.healthRed,
        onConfirm: () {
          provider.confirmBlackMarketPurchase();
          Navigator.pop(context);
        },
        onCancel: () {
          provider.cancelPurchase();
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 钱包标签页
  Widget _buildWalletTab() {
    return Consumer<EconomyProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 余额卡片
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGold.withOpacity(0.2),
                    AppTheme.accentMystic.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.wallet.coins}',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '金币',
                        style: TextStyle(
                          color: BattleColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: BattleColors.border,
                  ),
                  Column(
                    children: [
                      const Icon(Icons.diamond, color: AppTheme.accentMystic, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.wallet.crystals}',
                        style: const TextStyle(
                          color: AppTheme.accentMystic,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '钻石',
                        style: TextStyle(
                          color: BattleColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 交易历史标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.history, color: BattleColors.textPrimary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '交易历史',
                    style: TextStyle(
                      color: BattleColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 交易列表
            Expanded(
              child: provider.wallet.history.isEmpty
                  ? Center(
                      child: Text(
                        '暂无交易记录',
                        style: TextStyle(
                          color: BattleColors.textPrimary.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.wallet.history.length,
                      itemBuilder: (context, index) {
                        final tx = provider.wallet.history[index];
                        return TransactionItem(
                          type: _getTransactionTypeName(tx.type),
                          amount: tx.amount,
                          itemName: tx.itemName,
                          time: _formatTime(tx.timestamp),
                          status: tx.status,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(1)}万';
    }
    return price.toString();
  }

  String _getRarityText(int rarity) {
    switch (rarity) {
      case 1:
        return '普通';
      case 2:
        return '优秀';
      case 3:
        return '稀有';
      case 4:
        return '史诗';
      case 5:
        return '传说';
      default:
        return '普通';
    }
  }

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'deposit':
        return '充值';
      case 'purchase':
        return '购买';
      case 'bid':
        return '竞拍';
      case 'buyout':
        return '一口价';
      case 'sale':
        return '售出';
      default:
        return type;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

/// 确认弹窗组件
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BattleColors.secondaryBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.accentGold, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.accentGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: BattleColors.textPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BattleColors.border),
                      ),
                      child: Center(
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            color: BattleColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: confirmColor ?? AppTheme.accentGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            color: confirmColor == AppTheme.accentGold
                                ? BattleColors.primaryBg
                                : BattleColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
