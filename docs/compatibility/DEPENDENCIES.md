# 外部依赖兼容补丁和交付引用

需要维护四个外部仓库的 `compat/flutter-3.27.4` 分支。同一 monorepo 的包共用一个 fork，不逐包建立仓库。GenUI 复用已有 mytangyh fork；用户 2026-10-02 明确授权本地提交并推送后，核实可复用 fork 并创建四个依赖 fork。结果见 [fork-creation.json](evidence/fork-creation.json)。Dartantic 上游现名 csells/dartantic，旧 csells/dartantic_ai URL 仍重定向；fork 保留 dartantic_ai 名称。

## 仓库和补丁

| 仓库及上游基线 | 包 | 本地兼容补丁 | 验证 |
| --- | --- | --- | --- |
| csells/dartantic `557f1584f26a302bbb00ac6d98df1f5e3e1de812` | dartantic_ai 3.2.0、dartantic_interface 3.0.0 | SDK、collection/meta、测试和 Melos 版本；workspace 保留两个库；公开 setter 的最小兼容修改 | 146 离线测试通过，包含 accessor 回归；无分析 error/warning |
| davidmigloz/ai_clients_dart `a46c9cb73a8cd9625af9b570e8cae619b29d045a` | anthropic_sdk_dart 1.2.1、mistralai_dart 1.2.1、ollama_dart 1.3.0、openai_dart 1.3.0 | Dart 3.6 集合写法；匹配的 SDK、测试和 Melos；无效 HTTP 日期异常归一化；旧 formatter | 2529 unit 通过，11 项原有条件跳过；真实 API 未验证 |
| googleapis/google-cloud-dart `2c44ec5b4e2d865fc4130fd42b8b5a43b5a831ed` | protobuf、rpc、type、longrunning、ai_generativelanguage_v1beta 均 0.5.0 | SDK 和开发依赖；workspace 保留五个生成库和 test_utils；Windows 回放 URI 转文件路径 | 202 离线测试通过 |
| jamiewest/sse_channel `90ec12606e33e067dba1e4f18bd6869d419dbf7c` | sse_channel 0.2.2 | SDK、async、sse、stream_channel；补齐同版本发布源码，修复内部 import；旧 formatter | 13 测试通过 |

SSE Git 基线缺少导出的 `lib/src/sse_channel.dart` 和 `lib/src/util.dart`。补齐源为 [Pub 0.2.2 归档](https://pub.dev/api/archives/sse_channel-0.2.2.tar.gz)，SHA256 为 `ad85fda353fae12533fd762dbd3ff275e710f216644e39459bf11a138124acad`。同时保留发布的 transformer 测试。归档内错误的 `../../src/util.dart` 改为 `util.dart`，没有重写 SSE 行为。

AI SDK 最初较旧的 1.1/1.2 基线缺少 Dartantic 所需的 OpenAI Responses 类型，因此选择上述 openai_dart 1.3.0 对应提交，再等价回移新语法。没有通过删 provider 或删导出规避依赖。

## 公开 accessor 冲突

`OpenAIResponsesEventMapper` 经 dartantic_ai 公共 barrel 导出。它的 `containerId` getter 返回 `String?`，setter 接受 `String`。Dart 3.6 要求 getter 类型是 setter 类型的子类型，因此整条 simple_chat 导入链无法编译。`evidence/simple-chat-unit-tests.txt` 保存了实际编译错误。

已应用的最小适配是保留 getter，将 setter 参数改为 `String?`，以 `as String` 在赋值前拒绝 null。有效字符串赋值、初始 null 读取和动态 null 赋值抛 TypeError 的行为保持；静态签名允许传入 nullable 值，是公开 API 差异。修改前已向用户说明阻塞证据及替代方案，按原任务的源码适配授权实施，没有缩减 provider 或功能范围。

```dart
String? get containerId => _state.containerId;
set containerId(String? containerId) {
  _state.containerId = containerId as String;
}
```

回归已验证初值 null、有效字符串往返、静态和动态 null 赋值均抛 TypeError 且不覆盖既有状态；事件 mapper 等七个无密钥测试文件合计 146 通过。保持原 setter 签名会继续阻塞旧 SDK；将 getter 改为非 nullable 会改变初始读取语义；重构或降级整个 Dartantic 则影响更大的 API 范围。

初次离线测试列表误包含了混合本地辅助测试和两个真实 Anthropic 媒体请求的文件，两个请求因缺凭据失败。该文件原样保留；CI 明确选择无密钥测试文件，真实 provider 测试单独列为未验证，没有改写失败测试或用假凭据调用真实服务。

## 已兼容的原版依赖

保留 audioplayers 6.6.0、video_player_win 3.3.0、preact_signals 1.9.4，以及当前解析图中兼容的官方平台实现。功能匹配的旧版本包括 flutter_markdown_plus 1.0.3、video_player 2.10.0、intl 0.19.0、cross_file 0.3.4+2 和 build_runner 2.4.15。具体 SDK 约束、源码仓库、Pub 归档校验值和传递关系见 dependency-inventory.json；插件是否运行成功仍按 VALIDATION.md 分平台判断。

## 固定来源与提交顺序

用户已授权本地提交并推送到 mytangyh fork。先提交 GenUI 核心检查点和三个底层依赖，再将 Dartantic 的永久 Git 来源清单固定到这些完整 SHA，最后固定 GenUI 的四个外部 fork 引用。

实际仓库、包路径、上游基线与交付提交见 [fork-references.json](fork-references.json)。GenUI 和 Dartantic 根 lockfile 保留完整 resolved-ref；没有 pubspec_overrides.yaml 或本机 path。Dartantic 独立使用 GenUI 核心检查点，GenUI 应用使用自身 workspace 核心包，避免跨仓库引用循环。

运行和同步说明见 README.md；本轮设备验收只覆盖 Android。新的固定来源检查与干净克隆均已通过；[远程兼容 CI](https://github.com/mytangyh/genui/actions/runs/36978425938) 的七个任务全部成功，完整提交与结果见 DELIVERY.md。
