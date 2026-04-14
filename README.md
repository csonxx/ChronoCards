# ChronoCards

ChronoCards 是一款武侠题材的开放世界 RPG 游戏，支持多端运行。

GitHub: git@github.com:csonxx/ChronoCards.git

## 项目结构

```
ChronoCards/
├── app/           ← Flutter 移动/桌面 App
├── server/        ← Go 游戏后端
├── web/           ← React/Vite Web 前端
├── docs/          ← 项目文档
├── memory/        ← AI 记忆文件
└── [OpenClaw 工作区配置文件]
```

## 快速导航

| 目录 | 技术栈 | 说明 |
|------|--------|------|
| **app/** | Flutter / Dart | 移动端（Android/iOS）+ 桌面端（Linux/macOS/Windows）+ Web |
| **server/** | Go 1.24+ | 游戏后端服务，含战斗系统、卡组管理、AI叙事、六元素反应引擎 |
| **web/** | React + Vite + TypeScript | 游戏 Web 前端 |
| **docs/** | - | API 契约（OpenAPI）、代码评审、AI 输出素材 |

## 启动方式

### 后端（Go）
```bash
cd server
go build -o chrono-cards ./cmd/server
./chrono-cards
# 默认监听 :8080
```

### 前端（Flutter App）
```bash
cd app
flutter run
```

### Web 前端
```bash
cd web
npm install
npm run dev
```

## 核心系统

- **事件卡组系统**：主线/支线/技能解锁/数值提升/情感联结/经济系统/空白
- **六元素反应**：风、火、水、雷、冰、毒，元素压制 + 元素反应
- **AI 叙事**：支持 DeepSeek / OpenAI API，本地模板降级
- **战斗系统**：闪避/格挡/伤害计算

## API 文档

完整 API 契约见 `server/api_schema.json`（OpenAPI 3.0 格式）
