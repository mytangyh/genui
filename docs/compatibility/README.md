# Flutter 3.27.4 兼容分支说明

本分支保留固定上游提交中的 GenUI 和官方 `examples/simple_chat`，目标 SDK 为 Flutter 3.27.4 / Dart 3.6.2。按用户 2026-10-02 的最新要求，只验收 Android。Redmi 7A 上官方离线样例、三种模式真实 gpt-5.6-luna 交互和原生媒体均通过。五个仓库使用 mytangyh fork 的同名兼容分支，外部修改依赖已固定完整 Git SHA；交付不使用本机路径或临时 override 文件。

## 固定来源

GenUI 基线为 `40d4df6a90bcc74513d4278278f59c4903095c26`，来自 [flutter/genui](https://github.com/flutter/genui/tree/40d4df6a90bcc74513d4278278f59c4903095c26)。这是 2026-10-02 查询时包含现有 GenUI 和 simple_chat 的最新适用提交。实施期间保持这一提交，未迁移到 a2ui_flutter。

`packages/archive/a2ui_core` 的每个 lib Dart 文件均与 Pub 发布的 0.1.0 比较过，换行归一化后全部一致；发布元数据也指向 GenUI 仓库。目录位置本身不作为版本证据。比较记录见 [a2ui-source-comparison.json](evidence/a2ui-source-comparison.json)。

Schema 子模块固定为 `39a26c1af38951840d1542103b99b00dc3a95bf1`，JSON Schema 测试集固定为 `15e4505bf689de5d30c29d50782bb48fa465c93f`。使用 gitlink 指定的提交，不执行 `git submodule update --remote`。

在 `packages/genui` 重新生成后，使用目标 SDK 格式化输出：`fvm dart run build_runner build --delete-conflicting-outputs`，然后 `fvm dart format lib/src/primitives/embedded_schemas.g.dart`。CI 执行这两个步骤后比较已跟踪文件。

完整解析图见 [dependency-inventory.json](dependency-inventory.json)。外部修改涉及四个仓库、十二个包；实际 fork、包路径、基线和固定交付 SHA 见 [fork-references.json](fork-references.json)。Dartantic 单独验证所需的 GenUI primitives/schema 固定到核心检查点；GenUI 应用使用本仓库 workspace 核心包，避免交付引用循环。

## 兼容修改

- 回移 Dart 新语法，包括点简写、null-aware 集合元素和重复 wildcard 参数。集合转换保留单次求值、空值省略及异常行为，已有 PromptBuilder 回归测试。
- 保留完整标准 Catalog，包括 AudioPlayer 和 Video。3.27 不支持的 SliderTheme padding 通过 track shape 保留原来的滑轨布局，已有几何回归测试。`simple_chat` 自身仍沿用上游的精简聊天 Catalog，未扩大或缩减示例功能。
- 显式导入旧 Flutter foundation 未导出的 `internal` 注解，回移语义标志读取 API，使用 SDK 匹配的 Markdown、视频、intl、测试及生成工具版本。
- 修复 Windows 的 Schema 测试路径和远程 `$ref` URL 构造；恢复原本应排除的 optional 测试集合，未删除必验用例。Schema 生成器归一化 CRLF，保持固定子模块原样。
- Google Cloud 测试回放用 `Uri.toFilePath()` 构造 Windows 文件路径。四个 AI SDK 将 Dart 3.6 HttpDate 对无效输入泄漏的 RangeError 归一化为 HttpException，维持无效日期的 Exception 契约。
- SSE 上游 Git 提交缺少公开导出的源文件，从同版本已发布归档补齐并修正归档中的错误相对 import。来源和校验值见 [依赖补丁记录](DEPENDENCIES.md)。
- 每个本地兼容仓库均有自己的 `.fvmrc`，不依赖父工作区或 FVM 全局默认值。原上游许可证和包名保留。
- Dartantic 的 containerId setter 参数由 String 放宽为 String?，解决旧 SDK 的 accessor 类型规则；getter、有效赋值和 null 赋值抛 TypeError 的行为保留，回归已通过。公开签名差异见 DEPENDENCIES.md。
- simple_chat 通过 GENUI_PROVIDER 选择 Google 或 OpenAI 兼容 provider，Google 保持默认；实际调用仍由 Dartantic 流式处理和执行工具。离线 JSON 样例改为 Flutter assets，使同一官方样例可在 Android 设备运行。

## 支持和验证范围

当前 Pub workspace 包含 genui、genai_primitives、json_schema_builder、来源已核对的 a2ui_core，以及 simple_chat。其他 examples、archive 包和工具仍保留在仓库，但未完成本轮兼容验证，也不属于首版验收门槛。

结果按层次记录在 [VALIDATION.md](VALIDATION.md)，原始要求及最新范围逐项核对见 [ACCEPTANCE.md](ACCEPTANCE.md)。Android 11/API 30 的 Redmi 7A `62f1ca2e0906` 上离线七项、真实模型三项均通过；真实路径验证 streaming/history、生成 UI、攀岩工具和 UI 操作后的模型回复。媒体测试入口真机两项通过。Windows、iOS、macOS、Linux、Web 均未验证，不属于当前平台验收范围。

## 本地运行

从兼容仓库根目录执行，先初始化固定子模块，再检查 SDK：

```powershell
git submodule update --init --recursive
fvm install 3.27.4
fvm flutter --no-version-check --version
fvm dart --version
$env:PUB_HOSTED_URL='https://pub.dev'
fvm flutter --no-version-check pub get
```

根 pubspec 的永久 Git 来源清单引用四个兼容 fork 的完整提交 SHA，lockfile 锁定相同来源。GenUI 和 Dartantic 的临时 pubspec_overrides.yaml 已移除；无需相邻 checkout。使用 `fvm flutter --no-version-check pub get --enforce-lockfile` 和 `./tool/compatibility/verify.ps1 -Scope Core` 验证固定来源。

lockfile 的 hosted 地址统一为 `https://pub.dev`，不继承本机 Pub 镜像。验证脚本仅在当前进程中切换这一地址并在结束后恢复。镜像切换会使 Dart 3.6 的严格 lockfile 检查失败，即使版本与归档 SHA 相同；URL 归一化后的解析结果单独留有证据。

真实模型配置以 [model-config.example.json](model-config.example.json) 为模板，保存到根目录忽略的 `.compat-local/model.json`。`GENUI_PROVIDER=google` 使用原 Google 路径，可填原 `GEMINI_API_KEY`；`GENUI_PROVIDER=openai` 使用 OpenAI Chat Completions 兼容接口。通用密钥填 `GENUI_API_KEY`，模型填 `GENUI_MODEL`，`GENUI_BASE_URL` 填对应 provider 的 API 根地址。当前实际验证使用 `openai`、`gpt-5.6-luna` 和 `https://gemini.bukexue.de/v1`；真实密钥不写入本说明或证据日志。

```powershell
New-Item -ItemType Directory -Force -Path '.compat-local' | Out-Null
if (-not (Test-Path -LiteralPath '.compat-local/model.json')) {
  Copy-Item -LiteralPath 'docs/compatibility/model-config.example.json' -Destination '.compat-local/model.json'
}
Set-Location 'examples/simple_chat'
$androidDeviceId='62f1ca2e0906' # 本轮 Redmi 7A；按实际 adb devices 输出修改
fvm flutter --no-version-check run -d $androidDeviceId --dart-define-from-file=../../.compat-local/model.json
```

Android 使用 JDK 17 和 NDK 27.0.12077973；本机验证使用进程级 Gradle 配置选择 JDK 17，不修改全局 Flutter 配置。

```powershell
$env:GRADLE_OPTS='-Dorg.gradle.java.home=C:\Progra~1\Java\jdk-17'
fvm flutter --no-version-check build apk --debug # 不注入密钥的交付 APK
fvm flutter --no-version-check test integration_test/app_test.dart --no-pub -d $androidDeviceId
fvm flutter --no-version-check test integration_test/media_plugin_test.dart --no-pub -d $androidDeviceId
fvm flutter --no-version-check test integration_test/live_model_test.dart --no-pub -d $androidDeviceId --dart-define-from-file=../../.compat-local/model.json
```

JDK 路径需按实际环境调整。离线和媒体测试不读取真实模型配置；live_model_test 是手动凭据验收，不加入无密钥 CI。注入密钥的测试或演示 APK 仅留在忽略目录，不作为公开交付物。不含密钥的主入口 APK 保存在 `examples/simple_chat/build/compatibility/app-debug-no-credentials.apk`。

## CI 和上游同步

[flutter_3274.yaml](../../.github/workflows/flutter_3274.yaml) 固定 3.27.4，覆盖来源审计、格式、严格分析、Schema 再生成、核心和示例测试、四个依赖 fork 的上游离线测试、flutter-tester 离线样例与三种模式检查、Android 主入口构建。按最新 Android 范围移除了本轮新增的 Windows job。它没有仓库所有者条件，也不读取模型密钥。上游 workflow 保留。来源审计检查完整 SHA、实际解析来源、无本机路径及 pub.dev 地址。远程运行结果以该兼容分支的 GitHub Actions 为准；本地 actionlint 已通过。

同步上游时先另开评估分支，记录新基线 SHA，分别更新四个依赖仓库；保留兼容补丁，重新核对 archive 与发布版本以及固定 Schema 资源。按底层依赖、Dartantic、GenUI、simple_chat 的顺序检查。完成同 SDK 的测试和平台验收后，再更新固定引用和 lockfile；不要把 Git 分支名或最新 main 写入交付引用。
