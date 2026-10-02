# 固定提交交付记录

日期：2026-10-02。五个仓库均已本地提交并推送到 mytangyh fork 的 `compat/flutter-3.27.4` 分支。GenUI 分支后续的文档提交保留下列已验证代码；可固定代码 SHA 重现此交付，或检出分支读取最新证据。没有创建或合并 PR，也未发布 release。

| 仓库 | 固定代码提交 | 内容 |
| --- | --- | --- |
| [mytangyh/genui](https://github.com/mytangyh/genui/tree/compat/flutter-3.27.4) | `16c796e093bf8d8d68cce1c41037d8b559e020d4` | GenUI 核心和 simple_chat；后续仅补充文档与 CI 记录 |
| [mytangyh/dartantic_ai](https://github.com/mytangyh/dartantic_ai/tree/compat/flutter-3.27.4) | `d876bd640ba0afa05b2cd264e776d98b0aeaa21a` | 具体补丁与测试见本仓库 COMPATIBILITY.md |
| [mytangyh/ai_clients_dart](https://github.com/mytangyh/ai_clients_dart/tree/compat/flutter-3.27.4) | `076584840dfcf6978d79119a2a663d2ddfd1f043` | 具体补丁与测试见本仓库 COMPATIBILITY.md |
| [mytangyh/google-cloud-dart](https://github.com/mytangyh/google-cloud-dart/tree/compat/flutter-3.27.4) | `45fa588f37c6f2356444ba43adf7c06b28315025` | 具体补丁与测试见本仓库 COMPATIBILITY.md |
| [mytangyh/sse_channel](https://github.com/mytangyh/sse_channel/tree/compat/flutter-3.27.4) | `1776f9dfa82e9d3a1430f236c02a70a3ded38aee` | 具体补丁与测试见本仓库 COMPATIBILITY.md |

Dartantic 独立使用 GenUI 核心检查点 `4f83e1ce5ad1f1df71c15e0c8cd39c481c122c01`；GenUI 应用使用自身 workspace 核心包。四个外部 fork 的十二个包均固定完整 Git SHA，lockfile 与来源清单一致，无临时 override 或本机路径。

[无密钥兼容 CI](https://github.com/mytangyh/genui/actions/runs/36978425938) 七个任务全部通过：依赖矩阵、四个依赖 fork 检查、核心检查及 Android 构建。各任务在独立的干净 Ubuntu runner 执行，明确使用 Flutter 3.27.4 / Dart 3.6.2。完整状态和原始日志见 [github-compatibility-ci.json](evidence/github-compatibility-ci.json) 与 `evidence/github-ci-*.txt`。

Android 实际验收设备为 Redmi 7A `62f1ca2e0906`（Android 11/API 30）：官方离线七项、真实 gpt-5.6-luna 三模式交互、音视频两项通过。固定 Git 库源文件与真机验收使用的本地库逐文件相同，见 fixed-git-source-identity.json。最终固定来源的无密钥主入口 APK 再次构建通过，哈希见 android-main-apk.json。

上游 `.github/workflows/e2e.yaml` 保留原样，与 GenUI 固定上游基线的 Git blob 完全相同：`0a0e4b4fd4ab23aa06fe03c97fc5fa3bb98ac014`。其[独立 workflow 失败](https://github.com/mytangyh/genui/actions/runs/36978424879)在本轮核心检查点和此前 main 已出现；它不属于新增无密钥兼容 CI，未计为通过。本轮未运行其他真实 provider 的上游在线测试；Windows/iOS/macOS/Linux 桌面/Web 未验收。

运行、限制及上游同步方法见 README.md；原始要求的逐项结果见 ACCEPTANCE.md。实际模型密钥保留在忽略的本地配置中，代码、文档、证据和公开 APK 不含该密钥。
