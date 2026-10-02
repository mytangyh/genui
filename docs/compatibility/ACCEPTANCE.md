# 原始要求逐项验收

核对日期：2026-10-02。用户最新要求仅验证 Android，并指定实际网关和 gpt-5.6-luna；此范围覆盖原先 Windows 默认运行要求。状态依据当前源码和执行证据；外部 Git 引用已固定；远程 CI 结果单独核对。源码、构建、原生运行及真实模型分别判断。

| 原始要求 | 当前结论 | 可检查证据或缺口 |
| --- | --- | --- |
| 检查仓库指令、分支和已有修改 | 已执行；父工作区原有修改保留 | 五个独立 checkout 均在 compat/flutter-3.27.4；不修改原 D 盘 checkout |
| 固定最新适用官方 GenUI/simple_chat 基线 | 已固定基线，补丁按依赖顺序提交 | README.md 完整上游 SHA；fork-references.json 的固定交付 SHA |
| FVM 固定 Flutter 3.27.4 / Dart 3.6.2 | 本地通过 | 各仓库 .fvmrc；[toolchain.json](evidence/toolchain.json)；验证脚本检查两个版本 |
| 保留结构、包名、许可证及完整 Catalog | 本地源码和核心测试通过 | 未删除上游跟踪文件；标准 Catalog 仍含音视频；simple_chat 精简 Catalog 保留上游选择；未迁移 a2ui_flutter |
| 覆盖协议、Schema、绑定、事件和相关依赖 | 支持范围内本地通过；平台运行另列 | [VALIDATION.md](VALIDATION.md) 的四个核心包及传递依赖测试；全部解析包见 inventory |
| 完整依赖清单：版本、仓库、SDK、适配及验证 | 已更新固定来源解析图 | dependency-inventory.json：156 包，十二个固定 Git 包来源 |
| 优先兼容原版、必要时回移源码 | 已实施并记录依据 | [DEPENDENCIES.md](DEPENDENCIES.md)；保留未修改 hosted 包的版本和归档 SHA |
| archive 包来源核实 | 本地通过 | [a2ui-source-comparison.json](evidence/a2ui-source-comparison.json)：逐个 lib Dart 文件比较发布 0.1.0，换行归一化后相同 |
| 每个改源码依赖维护对应 fork 分支；monorepo 共用 fork | 四个 mytangyh 依赖 fork 已创建并维护同名分支 | fork-creation.json；fork-references.json |
| fork 基线、补丁、测试与实施顺序 | 各依赖的基线、补丁及测试记录随源码提交 | 各仓库 COMPATIBILITY.md；DEPENDENCIES.md |
| 最终固定 commit/兼容版本，无临时 override、缓存修改或本机路径 | 已固定完整 SHA，无临时 override 或本机路径 | pubspec.yaml、pubspec.lock、fork-references.json；check_sources.dart |
| 干净环境解析、保存 lockfile、核对实际来源 | 底层新缓存检查通过；固定 Git 来源另行严格验证 | clean-source-validation.json；fixed-git 验证日志；最终远程克隆证据单独记录 |
| 根据实际解析处理 SDK/依赖冲突 | 本地通过 | 目标 SDK 编译、分析与上游测试；没有仅降低 SDK 声明；[VALIDATION.md](VALIDATION.md) |
| 新语法转换保持求值、null、异步及异常语义 | 本地测试通过 | PromptBuilder 求值/异常回归、HTTP 日期异常契约、SSE 重连、Dartantic accessor 测试；[VALIDATION.md](VALIDATION.md) |
| Flutter API、生成工具、构建脚本、固定资源 | 本地通过已验证部分 | 滑轨几何回归；Schema 生成并格式化后稳定；两个固定且干净的 gitlink；Android 主入口构建 |
| 可用 Pub workspace；其他示例/工具支持状态明确 | 已实施 | 根 pubspec 保留五成员；其他目录保留且未验证，不作为首版门槛；[README.md](README.md) |
| 不删组件、不占位、不吞异常、不关闭校验、不跳过失败测试制造通过 | 当前修改符合；真实 provider 测试仍未通过验收 | 必验 Schema 集保留；11 个 AI SDK 跳过为上游条件；混合 Anthropic 文件原样保留，真实请求缺凭据，不能列为通过 |
| 必须改变公开 API 时先说明证据和替代方案 | 已说明并实施最小变更 | Dartantic containerId setter 参数 String?；null 仍抛 TypeError；[DEPENDENCIES.md](DEPENDENCIES.md) |
| 支持源码格式、分析及相关上游/回归测试 | 本地通过当前规定检查 | [VALIDATION.md](VALIDATION.md)：核心严格分析干净，外部无 error/warning，保留上游 info；真实服务测试未验证 |
| 官方 FakeAiClient 和离线集成，实际渲染和事件 | Android 真机和 flutter-tester 均七项通过 | [simple-chat-offline-android.txt](evidence/simple-chat-offline-android.txt)：官方四样例及三模式回归；样例原内容保留，用 assets 提供 |
| 保留三模式、流式历史、攀岩卡片/工具和 UI 后续响应 | Android 真实模型三种模式均通过 | [android-model-validation.json](evidence/android-model-validation.json)；实际 Dartantic delegate，无 FakeAiClient |
| 模型可配置；未跟踪本地配置传密钥 | 已实现并实际使用 | Google 默认保留；新增 OpenAI 兼容 provider；配置忽略、dart-define-from-file 注入；证据日志不含密钥 |
| Windows 默认运行 simple_chat | 被用户最新 Android-only 范围覆盖 | Windows 原生未验证，不作为当前验收门槛 |
| Android example 构建、记录平台/设备 | 主入口 debug APK 构建通过，另建配置版安装启动 | [android-main-apk.json](evidence/android-main-apk.json) 记录无密钥交付件；Redmi 7A 62f1ca2e0906 |
| 音视频平台组件分别验收 | Android 真机通过；Windows 未验证 | [media-android-integration.txt](evidence/media-android-integration.txt)：Redmi 7A 62f1ca2e0906，音频及视频两项；独立媒体入口 |
| 真实模型三模式交互闭环 | Android 真机通过 | [simple-chat-live-android.txt](evidence/simple-chat-live-android.txt)：gpt-5.6-luna，六次应用请求；攀岩工具实际调用一次，两个 UI action 后续回复均渲染 |
| 不可用平台明确未验证 | 已记录 | [VALIDATION.md](VALIDATION.md)：iOS/macOS/Linux/Web 未构建或运行；Windows 原生未验证，以上平台均不作当前门槛 |
| fork 可用、固定 SDK、无密钥关键 CI | 固定 SDK、无密钥关键 CI 已提交，远程结果单独核对 | flutter_3274.yaml 无 owner gate；兼容分支 GitHub Actions |
| 交付代码、固定提交、运行/验证/限制/同步说明 | 代码、固定提交和说明随五仓库提交 | README.md、DEPENDENCIES.md、VALIDATION.md；最终提交与远程状态单独核对 |
| 提交、fork、推送、发布遵循明确授权 | 用户 2026-10-02 明确授权本地提交并推送 | 推送目标为 mytangyh fork 的 compat/flutter-3.27.4；没有合并 PR 或发布 release |

Android 离线、真实模型三种模式和媒体验收已通过。Git 来源已固定，临时 override 已移除；最终干净克隆和远程 CI 以相应执行证据判断。
