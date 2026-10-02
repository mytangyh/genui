# Flutter 3.27.4 验证记录

以下结果来自 2026-10-02 的本机执行，Flutter 3.27.4、Dart 3.6.2。外部修改依赖已切换到固定 Git SHA；三个底层仓库另做过独立源码快照和全新 Pub 缓存验证。固定来源后的检查单独保存，不从这些结果推断所有平台或真实 provider 均已通过。

用户最新范围为仅 Android；Windows 原生运行不再是验收门槛。用户提供模型连接后，在 Redmi 7A 上通过 OpenAI 兼容接口实际调用 gpt-5.6-luna，三种模式均通过，记录不包含密钥。

## 已执行检查

| 范围 | 结果 | 证据 |
| --- | --- | --- |
| 支持 workspace 依赖解析 | 成功，156 个实际解析包；12 个修改依赖固定 Git SHA，无临时路径 | dependency-inventory.json、evidence/pub-get-simple-chat.txt |
| 支持源码格式 | 223 文件检查通过；包含生成输出、官方示例和兼容工具 | evidence/format-supported.txt |
| 底层依赖独立解析 | AI SDK、Google Cloud、SSE 自身无临时 override 或路径来源；本机 enforce-lockfile 成功，尚未做远程干净克隆 | evidence/ai-clients-clean-pub-get.txt、evidence/google-cloud-tests-compat.txt、evidence/sse-tests-compat.txt |
| 底层依赖独立源码快照 | 从 Git 基线导出并覆盖当前补丁，在临时目录和新 Pub 缓存中执行严格锁定、格式、分析及上游离线测试：AI SDK 2529 通过/11 原有跳过、Google Cloud 202、SSE 13；快照无 override | evidence/clean-source-validation.json、evidence/*-clean-source-tests.txt |
| Pub 地址可移植性 | 五个根 lockfile 仅将 hosted URL 从本机镜像改为 pub.dev，版本及归档 SHA 保持原值；五仓库在 pub.dev 严格锁定解析均通过 | evidence/pub-host-normalization.json、evidence/canonical-pub-validation.json、evidence/*-canonical-pub-get.txt |
| 来源守卫及脚本 | 新增 hosted URL 校验通过格式和严格分析；隔离副本中的非标准 registry 被正确拒绝；两个 PowerShell 验证入口语法检查通过 | evidence/source-guard-registry-probe.json、tool/compatibility/check_sources.dart、tool/compatibility/verify*.ps1 |
| 固定 Git 来源后的检查 | 来源守卫通过、223 文件格式通过、严格分析无问题；核心 1832 项与示例 unit 3 项通过；离线集成单独验证七项 | evidence/genui-fixed-git-core-validation.txt、evidence/genui-fixed-git-integration-validation.txt、evidence/dartantic-fixed-git-validation.txt |
| Git 库源码与真机验收版本一致性 | 十二个修改包的所有 lib 文件与实际获取的固定 Git 源码逐文件相同，按 LF 归一化后比较 | evidence/fixed-git-source-identity.json |
| 新增 CI 静态检查 | actionlint 1.7.12 检查新增 workflow 通过；下载工具归档与发布方 SHA256 匹配；未执行远程 job | evidence/workflow-actionlint.json、evidence/workflow-actionlint.txt |
| GenUI 支持源码严格分析 | 包含官方示例和兼容工具，无问题 | evidence/analyze-supported.txt |
| a2ui_core | 上游测试 69 通过 | evidence/a2ui-tests.txt |
| genai_primitives | 上游测试 67 通过 | evidence/genai-tests.txt |
| json_schema_builder | 1321 通过，包含固定官方必验 Schema 测试集 | evidence/json-schema-tests-compat.txt |
| genui | 375 通过，包含新求值及滑轨布局回归 | evidence/genui-tests-compat.txt |
| 核心后续格式与注释调整 | 相关 PromptBuilder、basic_functions、catalog aliases 共 32 通过 | evidence/core-final-focused-tests.txt |
| 核心最终类型与字符串调整 | DataModel 和 PromptBuilder 共 58 通过 | evidence/core-final-data-prompt-tests.txt |
| Schema 代码生成 | build_runner 成功；Windows CRLF 子模块生成内容一致 | evidence/schema-generation.txt |
| 四个 AI SDK | 全部上游 unit 测试 2529 通过，11 个上游原有条件跳过；未运行真实 API integration | evidence/ai-clients-tests-compat.txt |
| Google Cloud | 离线回放和 Windows 路径回归，共 202 通过；type 包无上游 test 目录 | evidence/google-cloud-tests-compat.txt |
| SSE | 上游 13 通过，包含本机 HTTP/SSE 重连与 Last-Event-ID | evidence/sse-tests-compat.txt |
| Dartantic | 明确选择七个无密钥文件，共 146 通过；包含公开 accessor 类型及 null 异常行为回归 | evidence/dartantic-offline-tests-compat.txt |
| simple_chat unit | 上游 3 通过，含流式请求串行及应用初始化 | evidence/simple-chat-unit-tests-compat.txt |
| simple_chat 离线渲染和交互 | flutter-tester 平台：官方 4 样例 + 三种模式 3 回归，共 7 通过；验证多轮历史、按钮及攀岩卡片动作和后续回复 | evidence/simple-chat-offline-tester.txt |
| simple_chat Android 离线 | Redmi 7A 实际运行，同一官方四样例和三模式回归共七项通过；样例用 Flutter assets 提供，不读本机路径 | evidence/simple-chat-offline-android.txt |
| simple_chat Android 真实模型 | gpt-5.6-luna，OpenAI 兼容 Dartantic 路径：Text only 多轮记忆、Basic 按钮回传、Custom 攀岩工具调用和 Learn more 回传共三项通过，六次应用请求全部实际流式回复并渲染 | evidence/android-model-validation.json、evidence/simple-chat-live-android.txt |
| 新 provider 配置检查 | simple_chat 严格分析无问题，原 unit 三项再次通过；默认 Google 路径保留 | evidence/analyze-simple-chat-android-live.txt、evidence/simple-chat-unit-provider-compat.txt |
| 凭据隔离 | 忽略的私有配置版 APK 作为正对照；交付 debug kernel 不含提供的密钥，文档和证据无该密钥，交付 APK 与记录 SHA 一致 | evidence/android-credential-isolation.json |
| Android 主入口 APK | lib/main.dart debug APK 构建成功，未注入模型密钥 | evidence/android-main-build-compat.txt |
| Android 新 provider 主入口 | 新代码不含密钥的主入口 APK 构建成功；另建私有配置版安装启动，发送原始默认问题，实际模型流式完成并渲染攀岩卡片、图片和 Learn more | evidence/android-main-apk.json、evidence/android-main-build-openai-compat.txt、evidence/android-main-runtime.json、evidence/android-main-live.png |
| 外部依赖格式 | AI SDK 701 文件、Google Cloud 45 文件、SSE 8 文件、Dartantic 199 文件格式检查通过 | evidence/format-ai-clients.txt、evidence/format-google-cloud.txt、evidence/format-sse.txt、evidence/format-dartantic.txt |
| 外部依赖分析 | 无 error/warning；AI SDK 52 项 info、Google Cloud test_utils 4 项参数名称 info、Dartantic 5 项 info 均保留报告；SSE 无问题 | evidence/analyze-ai-clients.txt、evidence/analyze-google-cloud.txt、evidence/analyze-sse.txt、evidence/analyze-dartantic.txt |
| Android 原生媒体 | Redmi 7A `62f1ca2e0906`，Android 11/API 30，音频和视频 2 项实际运行通过；已固定 NDK 27 | evidence/media-android-integration.txt、evidence/media-fixtures.json |

音频验证资产加载、时长、播放位置推进、暂停、定位、音量和停止状态。视频验证实际解码、64×64 尺寸、VideoPlayer 渲染、位置推进、暂停、定位以及无播放器错误。资产为本地生成的 WAV 与 H.264 MP4，不依赖网络。自动检查提供播放状态证据，未记录人工听感。

此前独立源码快照使用当时的未提交补丁；这些补丁现已进入对应 fork 的兼容提交。新缓存测试发生在 hosted URL 归一化之前，随后五仓库另在 pub.dev 使用原版本及原归档 SHA 完成严格解析；这两项证据分别证明缓存独立性和地址可移植性，不表示最终远程 fork 克隆已验证。临时源码目录和缓存已清理。

固定 Git 检查的首次脚本调用在核心与 unit 全部通过后，发现 PowerShell 将短参数 `-d` 绑定为公共 `-Debug` 参数，导致离线集成调用混入多余测试路径。原失败记录保留在 core 日志；验证入口改用 `--device-id=flutter-tester`，并用同一函数包装单独重跑离线集成七项。此修复只改变验证参数，应用源码不变。

## 交付来源验证

| 验收项 | 当前证据和阻塞 | 下一步 |
| --- | --- | --- |
| 固定依赖解析 | 四个 fork 已固定完整 SHA，临时 override 已移除 | 结果见 fixed-git 验证日志和 fork-references.json |
| 新增远程 CI | workflow 已包含固定来源和完整离线检查 | 状态以兼容分支 GitHub Actions 实際运行结果为准 |

真实模型验收应记录日期、平台、provider、模型、三种模式的具体交互结果和工具调用证据；避免保存请求认证头或密钥。每项通过需要相应运行证据，不以窗口启动代替交互闭环。

## 平台和保留内容

| 内容 | 当前支持状态 |
| --- | --- |
| Windows | 桌面构建、运行、媒体未验证；按用户最新要求不作为验收条件 |
| Android | 主入口 APK 构建成功；官方离线七项、真实 gpt-5.6-luna 三模式、音视频两项均真机通过；不同入口证据分别记录 |
| iOS、macOS、Linux、Web | 本轮未构建或运行 |
| 其他 examples、archive 包和开发工具 | 原样保留；移出本次 Pub workspace，未作为兼容发行内容验证 |

证据中的初始失败日志用于解释修复原因，最终结果以带 `-compat` 的文件及本表对应记录为准。没有关闭 Schema 校验、删除必验组件或用 FakeAiClient 代替真实模型路径。
