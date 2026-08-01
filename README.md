# 无尽边境 · Infinite Frontier

一款完全本地运行的 2D 俯视角程序化无限世界生存探索 RPG。项目按照可回退、可测试、可独立运行的版本路线，从 V0.1.0 连续迭代至最终 V5.0.0。

> 当前稳定版本：**V0.4.0 - 无限区块流送**

## 核心原则

| 原则 | 说明 |
|---|---|
| 完全离线 | 游戏不连接 API，不依赖云服务或本地大模型 |
| 确定性世界 | 相同种子与坐标永远生成相同基础世界 |
| 无限探索 | 以区块为单位动态生成、加载、休眠与卸载 |
| 差异存档 | 仅保存玩家造成的永久变化 |
| 逐版验收 | 每一版本都具有测试、审查、构建和 Git Tag |

Stable tags are created by the repository release gate only when the matching test report is marked `PASS`; existing tags are never moved.

## V0.4.0 已包含

- Godot 4.7.1 工程与标准目录结构
- 中文像素风主菜单与可向任意方向探索的程序化世界
- 场景生命周期管理器与全局事件总线
- 可持久化设置、日志轮换和运行时调试面板
- 八方向行走、奔跑、翻滚、耐力消耗与生命接口
- 基于 `CharacterBody2D` 的物理碰撞与平滑边界镜头
- 生命、体力、状态和世界坐标 HUD
- 稳定的 64 位文字/数字世界种子和系统派生种子
- 32×32 区块坐标、负坐标、区块内坐标和稳定区块键
- FastNoiseLite 多尺度海拔场与深水、浅水、沙滩、陆地四级地形
- 活动半径 2、预载半径 3、缓存半径 4 的有界区块生命周期
- 距离/移动方向优先队列和最多 4 个并发 WorkerThreadPool 纯数据任务
- 主线程 `TileMapLayer` 激活/卸载、共享像素图集、内存峰值和流送 HUD
- 地形/噪声调试视图与可切换区块边界
- 自动化结构检查、生成顺序/接缝、后台线程及 30 分钟缓存策略模拟
- Windows/Linux 导出预设、架构文档和完整迭代路线

## 运行

1. 安装或解压 Godot 4.7.1 stable。
2. 在 Godot Project Manager 中导入根目录的 `project.godot`。
3. 点击运行，或使用命令：

```bash
godot4 --path .
```

## 测试

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
```

测试流程依次执行结构验证、资源导入、自动测试、主菜单冒烟测试和游戏场景冒烟测试；日志中出现脚本错误也会直接阻断发布。

生成并验证 Windows/Linux 发布包：

```bash
GODOT_BIN=/path/to/godot tools/build_release.sh
```

游戏中按 `N` 切换地形/海拔噪声视图，按 `B` 切换区块边界。

## 项目结构

```text
assets/       品牌、图形、音频和字体资源
data/         数据驱动的物品、配方、群系和内容
docs/         架构、生成、存档、测试与开发记录
scenes/       Godot 场景
scripts/      按核心、世界、生成和玩法领域组织的脚本
tests/        自动测试与验证场景
tools/        构建、验证和开发工具
releases/     每版测试、审查和问题记录
```

## 路线

V1.0.0 只是第一个完整可玩节点，项目不会在此停止。完整路线见 [`docs/release-roadmap.md`](docs/release-roadmap.md)，最终目标是包含完整世界、文明、生存、建造、海洋、季节、主线和终局的 V5.0.0。

## License

Code is released under the MIT License. Third-party assets, if introduced later, will be listed with their individual licenses.

The bundled Noto Sans CJK SC project subset is licensed under the SIL Open Font License 1.1. The subset is expanded as new in-game text is introduced. See [`assets/fonts/OFL-1.1.txt`](assets/fonts/OFL-1.1.txt).
