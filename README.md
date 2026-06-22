# 奥术远征团（iOS 原型）

一款使用 SwiftUI 构建的原创俯视角生存战斗原型，玩法灵感来自自动攻击类 roguelite，但不包含《咒语旅团》的名称、素材、关卡或代码。

## 已实现

- 虚拟摇杆移动与自动瞄准施法
- 动态怪潮、命中、生命、经验与等级
- 升级三选一：攻速、伤害、移速、生命、多重施法
- 结算与快速重开
- App Intent / Siri 快捷指令“开始奥术远征”
- 游戏核心状态的单元测试

## 运行

使用 Xcode 16 或更新版本打开 `ArcaneCovenant.xcodeproj`，选择 iOS 17+ Simulator，运行 `ArcaneCovenant` scheme。

## 没有 Mac：使用云端构建

项目包含 GitHub Actions 云端 macOS 流水线：`.github/workflows/ios-cloud-build.yml`。

1. 把项目推送到 GitHub 仓库的 `main` 分支。
2. 打开仓库的 **Actions → iOS Cloud Build → Run workflow**。
3. 构建通过后，在运行记录的 **Artifacts** 下载 `ArcaneCovenant-Simulator`。

流水线会在云端 Mac 上自动选择可用的最新 iPhone Simulator、编译 App、运行单元测试并上传构建结果。Simulator 包只能用于 Simulator，不能直接安装到实体 iPhone；实体机或 App Store 包需要 Apple Developer 账号、证书和描述文件。

第一版刻意聚焦单机竖切。后续适合加入 SpriteKit/Metal 渲染、音效与触感、Boss、角色/法术数据驱动，以及 GameKit 或自建服务的多人同步。
