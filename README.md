# MarkEdit

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/ios-marketing-1024.png" width="120" alt="MarkEdit App Icon">
</p>

<p align="center">
  <strong>一款简洁的 iOS Markdown 预览与编辑器</strong>
</p>

<p align="center">
  <a href="#功能">功能</a> •
  <a href="#截图">截图</a> •
  <a href="#环境要求">环境要求</a> •
  <a href="#如何运行">如何运行</a> •
  <a href="#项目结构">项目结构</a> •
  <a href="#已知限制">已知限制</a>
</p>

---

## 简介

MarkEdit 是一个基于 **SwiftUI + WKWebView** 的 iOS Markdown 编辑器，最低支持 **iOS 15**。

它让你在 iPhone 或 iPad 上方便地浏览、编辑和预览 Markdown 文件，支持代码高亮、主题切换、HTML/PDF 导出，并能从系统「文件」App 中直接打开 `.md` 文件。

> 本项目为开源 MVP，适合有 Mac 和 Xcode 的开发者自行编译安装。由于 iOS 生态限制，未上架 App Store，暂无法直接通过 App Store 分发。

---

## 功能

- 📁 在 App 内浏览沙盒 Documents 目录中的 Markdown 文件
- 📝 新建、删除 Markdown 文件
- ✏️ 使用原生 `TextEditor` 编辑 Markdown
- 👁️ 实时预览渲染结果（Down → HTML → WKWebView）
- 🎨 代码高亮（highlight.js）
- 🌗 浅色 / 深色 / 跟随系统主题
- 🖌️ 代码主题切换：GitHub / GitHub Dark / Atom One Dark
- 📤 导出为 HTML 或 PDF，通过系统分享面板发送
- 📂 从系统「文件」App 中打开 `.md` 文件
- 🔗 通过 Document Picker 选择外部文件夹并记住访问权限

---

## 截图

| 文件浏览器 | 编辑器 & 预览 |
|---|---|
| ![文件浏览器](screenshots/01-file-browser.png) | *更多截图待补充：点击 Welcome.md 进入编辑/预览界面* |

> 提示：如果你想补充更多截图，可以在模拟器或真机上运行后，自行替换 `screenshots/` 目录下的图片。

---

## 环境要求

- macOS 12.5 或更高版本
- Xcode 14.0 或更高版本
- iOS 15.0 或更高版本的目标设备/模拟器
- 一个有效的 Apple ID（用于 Xcode 本地签名）

---

## 如何运行

### 1. 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/MarkEdit.git
cd MarkEdit
```

### 2. 用 Xcode 打开项目

双击 `MarkEdit.xcodeproj`，Xcode 会自动解析 Swift Package Manager 依赖（`Vendor/Down`）。

### 3. 配置签名

1. 在 Xcode 左侧项目导航栏中选中 `MarkEdit` 项目
2. 选择 `MarkEdit` Target → **Signing & Capabilities**
3. 在 **Team** 下拉框中选择你的个人 Apple ID（免费账号即可）
4. 如果 Bundle Identifier 显示黄色警告，点击 **Fix Issue** 让 Xcode 自动处理

### 4. 运行

1. 在 Xcode 顶部工具栏选择 **iPhone 15 / iPhone 16 模拟器**，或连接你的 iPhone
2. 按 `Cmd + R` 运行
3. 首次在真机上运行时，需要在 iPhone **设置 → 通用 → VPN 与设备管理** 中信任你的开发者证书

### 5. 重新生成工程（可选）

本项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理工程文件。如果你修改了 `project.yml`，可以重新生成：

```bash
xcodegen generate --project . --spec project.yml
```

---

## 项目结构

```
MarkEdit/
├── App/
│   ├── AppState.swift              # 全局应用状态
│   └── MarkEditApp.swift           # App 入口
├── Models/
│   ├── ExportFormat.swift          # 导出格式枚举
│   ├── FileItem.swift              # 文件模型
│   └── PreviewSettings.swift       # 预览主题设置
├── Services/
│   ├── FileAccessHelper.swift      # 文件访问与权限
│   ├── HTMLExporter.swift          # HTML 导出
│   ├── HTMLRenderer.swift          # HTML 渲染模板
│   ├── MarkdownRenderer.swift      # Markdown → HTML
│   ├── PDFExporter.swift           # PDF 导出
│   └── ThemeManager.swift          # 主题管理
├── ViewModels/
│   ├── EditorViewModel.swift       # 编辑器逻辑
│   └── FileBrowserViewModel.swift  # 文件浏览器逻辑
├── Views/
│   ├── DocumentPicker.swift        # 文件夹选择器
│   ├── EditorView.swift            # 编辑界面
│   ├── FileBrowserView.swift       # 文件浏览器
│   ├── FileRowView.swift           # 文件列表行
│   ├── MainView.swift              # 主界面
│   ├── PreviewView.swift           # 预览界面
│   ├── PreviewWebView.swift        # WKWebView 包装
│   ├── SettingsToolbarView.swift   # 设置工具栏
│   └── ShareSheet.swift            # 分享面板
├── Resources/
│   ├── LaunchScreen.storyboard     # 启动屏
│   ├── atom-one-dark.min.css       # 代码主题
│   ├── github-dark.min.css
│   ├── github.min.css
│   ├── highlight.min.js            # 代码高亮
│   ├── markdown.css                # Markdown 渲染样式
│   └── print.css                   # PDF 打印样式
└── Info.plist                      # 应用配置
```

---

## 依赖

- [Down](https://github.com/johnxnguyen/Down) — Markdown 解析库（已本地 vendored 在 `Vendor/Down`）
- [highlight.js](https://highlightjs.org/) 11.9.0 — 代码高亮

---

## 示例文档

`SampleDocuments/` 目录下包含了一些测试和示例 Markdown 文件，你可以通过 Document Picker 打开该文件夹来体验不同 Markdown 元素的渲染效果。

---

## 已知限制

- 编辑器目前没有 Markdown 语法高亮，使用原生 `TextEditor`
- 从「文件」App 打开的外部文件，其相对路径图片可能受沙盒限制无法加载
- PDF 分页依赖 CSS `@media print`，复杂表格或大图可能需要手动调整样式
- 未上架 App Store，分发需要自己编译或通过 AltStore/SideStore 等侧载方式

---

## 为什么不上架 App Store？

Apple Developer Program 需要 $99/年的年费。对于个人 MVP 或开源小工具，这笔费用可能不划算。本项目采用开源方式分享，任何人都可以免费获取源码并在自己的设备上运行。

如果你希望更简单的分发，也可以：
- 将本项目 clone 后用 Xcode 直接安装到自己的 iPhone
- 使用 [AltStore](https://altstore.io/) 或 [SideStore](https://sidestore.io/) 进行侧载
- 基于本项目做一个 Web 版 Markdown 编辑器

---

## 贡献

欢迎 Issue 和 PR！如果你发现了 bug 或有新功能想法，欢迎提交 Issue 讨论。

---

## License

MIT License — 详见 [LICENSE](LICENSE) 文件。

---

<p align="center">
  Made with ❤️ using SwiftUI
</p>
