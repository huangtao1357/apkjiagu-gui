# APK 加固工具 (apkjiagu)

> **低成本 APK 加固可视化方案**：基于开源的 [dpt-shell](https://github.com/luoyesiqiu/dpt-shell)（Dex 方法抽取 + 运行时还原），为开发者提供免费的桌面端加固 + 签名一体化工具。

## 为什么需要它

市场上 APK 加固服务几乎全面收费：**360 加固将于 7 月 1 日起取消免费版本**，腾讯乐固、爱加密等也已商业收费。对于个人开发者、独立项目和小团队，加固成本正变得不可承受。

`apkjiagu` 把开源的 dpt-shell 引擎封装成可视化桌面应用，**一键完成加固与签名**，无需命令行、无需上传到云端、无需付费。所有处理在本地完成，APK 不离开你的机器。

## 功能特性

- **拖拽 / 选择 APK**：自动解析 `AndroidManifest.xml`，提取包名、版本、minSdk 等元信息
- **可视化加固参数**：
  - 排除架构 (armeabi-v7a / arm64-v8a / x86 / x86_64)
  - 体积压缩、保留类、Debuggable、运行时签名校验、禁用组件工厂、详细日志
  - 排除规则文件
- **自动签名**：基于 Android Build Tools r34 的 `apksigner`，支持 V1/V2/V3/V4 签名方案，可保存多个 keystore 配置
- **zipalign 对齐**：签名前自动对齐
- **历史记录**：SQLite 持久化保存每次加固产物路径与参数
- **日志面板**：实时日志输出，支持自由选择、复制
- **科技工业风 UI**：深青绿 + 琥珀点缀，三栏式布局

## 默认参数

- 排除架构默认勾选：**x86, x86_64**
- 默认勾选 **体积压缩**
- 默认 **不签名**（需在签名配置中选择）
- 签名策略默认勾选：**V1 + V2 + V3**

## 内置工具

以下工具已内置在 `assets/tools/`，无需额外下载：

| 文件 | 说明 |
|------|------|
| `dpt.jar` | dpt-shell v2.12.0 加固主程序 |
| `apksigner.jar` | Android Build Tools r34 签名工具 |
| `zipalign.exe` | APK 对齐工具 |
| `shell-files/` | dpt-shell 运行时所需的 dex 与 native 库 |

## 运行环境要求

- **Windows 10/11** (x64)
- **Java 8+**（dpt.jar 与 apksigner.jar 依赖，需在 PATH 中）
- **Flutter 3.10+**（仅开发时需要）

## 开发

```bash
# 安装依赖
flutter pub get

# 运行
flutter run -d windows

# 打包 release
flutter build windows --release
```

> ⚠️ **路径提示**：项目路径包含中文时 Windows 构建可能失败，建议放在纯 ASCII 路径下构建。

## 项目结构

```
lib/
├── app.dart                  # 应用主题与主框架
├── main.dart                 # 入口
├── models/                   # 数据模型
│   ├── apk_info.dart
│   ├── history_record.dart
│   └── sign_config.dart
├── pages/                    # 页面
│   ├── harden_page.dart      # 加固主页（三栏布局）
│   ├── sign_configs_page.dart # 签名配置管理
│   └── history_page.dart     # 历史记录
├── providers/
│   └── app_state.dart        # 全局状态管理
├── services/
│   ├── apk_parser.dart       # APK 元信息解析
│   ├── axml_parser.dart      # AndroidManifest 二进制解析
│   ├── apk_signer.dart       # 签名流程
│   ├── dpt_runner.dart       # dpt-shell 调用
│   ├── history_store.dart    # SQLite 历史存储
│   ├── sign_config_store.dart # 签名配置 JSON 存储
│   └── tool_paths.dart        # 内置工具路径管理
└── utils/
    └── file_utils.dart
```

## 致谢

- [dpt-shell](https://github.com/luoyesiqiu/dpt-shell) by luoyesiqiu
- Android Build Tools & apksigner by Google

## License

MIT
