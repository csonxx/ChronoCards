# ChronoCards - 九州江湖

> AI生成世界游戏 · 武侠古风 · 即时ARPG

## 项目仓库

- 前端代码：`frontend/` 目录
- 仓库：git@github.com:csonxx/ChronoCards.git

## 开发文档

- **World Bible v1.5**：https://ocnghmk3m2ae.feishu.cn/docx/R4xSdmohtoMgJxxXHSrcD7wWnpd
- **UI视觉提案 v1.0**：https://feishu.cn/docx/DtdvdLNnSoFANTxNe53ce5bpn3e
- **S5 ARPG战斗界面**：https://feishu.cn/docx/Zg9ad8IiAobDdHxvic5cOQeynrf

## 技术栈

- **框架**：React 18 + TypeScript
- **构建工具**：Vite
- **UI风格**：古卷风（Ancient Scroll Style）

## 开发进度

### ✅ 已完成

| 界面 | 状态 | 说明 |
|------|------|------|
| S2 开放世界 | ✅ 完成 | 主场景、移动、交互 |
| S3 抽牌界面 | ✅ 完成 | 卷轴动画、选项交互 |
| S5 战斗界面 | ✅ 完成 | 即时ARPG、资源系统 |

### 📋 待开发

| 界面 | 优先级 | 说明 |
|------|--------|------|
| S1 主菜单 | P2 | 游戏启动封面 |
| S4 卡组浏览 | P2 | 多卷古卷书架 |
| S6 对话界面 | P2 | NPC交互 |
| S7 角色状态 | P3 | 属性/武学/背包 |
| S8 世界地图 | P3 | 九州舆图 |
| S9 设置界面 | P3 | 音量/画质等 |

## 快速开始

```bash
cd frontend
npm install
npm run dev
```

## 项目结构

```
frontend/
├── src/
│   ├── components/
│   │   ├── ui/          # 古卷风UI组件库
│   │   ├── world/       # S2 开放世界
│   │   ├── card/         # S3 抽牌界面
│   │   └── battle/       # S5 战斗界面
│   ├── styles/           # 全局样式、设计令牌
│   ├── types/            # TypeScript类型定义
│   ├── App.tsx           # 主应用
│   └── main.tsx          # 入口
└── index.html
```

## UI设计系统

### 色彩系统

| 名称 | 色值 | 用途 |
|------|------|------|
| 赭石 | #8B6914 | 界面底板、按钮 |
| 靛青 | #2C4A6B | 卡片背景 |
| 赤金 | #C9A227 | 重要标题 |
| 朱砂 | #9B2335 | 危险/战斗 |
| 宣纸白 | #F5EBD7 | 背景 |
| 墨黑 | #2A2A2A | 正文 |

### 动效规范

| 动效 | 时长 | 缓动 |
|------|------|------|
| 卷轴展开 | 800ms | ease-out |
| 卷轴卷起 | 600ms | ease-in |
| 书签插入 | 200ms | ease-out |
| 印章盖下 | 150ms | ease-in |

## 战斗系统

- **三段连击**：轻击→展开→爆发
- **资源系统**：体力/内力/剑意
- **元素反应**：火/水/雷/冰/风/毒
- **完美格挡**：0.15秒时间窗口

---

最后更新：2026-04-10
