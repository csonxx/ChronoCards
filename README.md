# ChronoCards Backend

ChronoCards 游戏后端服务 (Go)

项目代号：ChronoCards
GitHub: git@github.com:csonxx/ChronoCards.git

## 技术栈

- **语言**: Go 1.24+
- **框架**: 标准库 net/http (无外部框架依赖)
- **数据库**: PostgreSQL + Redis (可选，当前为内存存储)
- **AI叙事**: DeepSeek / OpenAI API (可选，无API Key时使用本地模板)

## 项目结构

```
ChronoCards/
├── cmd/
│   └── server/
│       └── main.go           # 程序入口
├── internal/
│   ├── api/
│   │   └── handler.go        # HTTP 处理器（REST API）
│   ├── game/
│   │   ├── battle/           # 战斗系统（闪避/格挡/伤害计算）
│   │   ├── deck/             # 发牌员逻辑（事件卡组管理）
│   │   ├── element/          # 六元素反应计算引擎
│   │   └── narrative/        # AI叙事触发服务
│   ├── model/
│   │   ├── player.go         # 玩家数据模型
│   │   ├── deck.go           # 卡组/卡牌数据模型
│   │   ├── battle.go         # 战斗/技能/发牌员模型
│   │   └── api_models.go     # API 请求/响应模型
│   └── store/
│       └── store.go          # 内存数据存储
├── migrations/
│   └── 001_init.sql          # 数据库 Schema
├── api_schema.json           # API 契约文档（OpenAPI 3.0）
└── README.md
```

## 核心功能

### 1. 事件卡组系统
- 创建/管理玩家卡组
- 抽牌、发牌、洗牌
- 动态调整（自适应难度）
- 参考 World Bible v1.5 卡牌类型：主线/支线/技能解锁/数值提升/情感联结/经济系统/空白

### 2. 六元素反应计算
- 六元素：风、火、水、雷、冰、毒
- 元素压制：风>火>雷>水>冰>毒>风（伤害×1.15）
- 元素反应：蒸发、燃烧、超导、感电、碎冰、扩散、毒爆、凝结、蚀骨
- 元素精通公式：精通加成 = 精通 / (精通 + 目标等级×10 + 100)
- 状态效果：燃烧（5%/秒·层）、中毒（3%/秒·层）、蚀骨（-15%移速/层）

### 3. 玩家状态追踪
- HP / MP / 体力 / 剑意值
- 六元素精通
- 阵营声望（明教/正派/锦衣卫）
- 技能列表

### 4. AI叙事触发接口
- 卡组事件 → AI生成叙事内容
- 支持 DeepSeek / OpenAI API
- 无API Key时降级为本地模板

## 启动方式

```bash
# 编译
go build -o chrono-cards ./cmd/server

# 运行（默认监听 :8080）
./chrono-cards

# 或直接运行
go run ./cmd/server
```

## 环境变量（可选）

```bash
export OPENAI_API_KEY=sk-xxx        # OpenAI API Key
export DEEPSEEK_API_KEY=sk-xxx      # DeepSeek API Key (优先使用)
export AI_API_URL=https://api.deepseek.com/chat/completions
export AI_MODEL=deepseek-chat
```

## API 文档

完整 API 契约见 `api_schema.json`（OpenAPI 3.0 格式）

主要端点：
- `POST /api/v1/players` - 创建玩家
- `GET/PATCH /api/v1/players/{id}` - 获取/更新玩家
- `POST /api/v1/decks` - 创建卡组
- `POST /api/v1/decks/{id}/draw` - 抽牌
- `POST /api/v1/element/reactions` - 计算元素反应
- `POST /api/v1/battle/calculate` - 战斗伤害计算
- `POST /api/v1/battle/dodge` - 闪避判定
- `POST /api/v1/battle/block` - 格挡判定
- `POST /api/v1/narrative/trigger` - AI叙事触发
- `POST /api/v1/dealers/{id}/trigger` - 发牌员触发

## 数据库

```bash
# 初始化数据库
psql -U postgres -d chronocards -f migrations/001_init.sql
```

## 开发原则

1. **先契约后代码**：API 契约（api_schema.json）必须前后端双方确认后再锁定
2. **数值公式文档化**：所有数值公式已在代码和 schema.sql 中明确标注
3. **模块化设计**：游戏逻辑与 API 层分离，便于测试和维护
