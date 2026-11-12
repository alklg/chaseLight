# 追光 · UI 开发规范

> 这份文档存在的唯一目的：不让界面越做越散。
> 新增页面、改现有页面，先对照这里；要打破某条规则，先改这份文档，再改代码。

---

## 一、颜色

**唯一来源：`lib/theme/app_theme.dart` 的 `AppColors`。**

```dart
AppColors.bg              // 页面底色
AppColors.surface         // 卡片
AppColors.surfaceHigh     // 输入框、chip、次级容器
AppColors.textPrimary     // 主文字
AppColors.textSecondary   // 次要文字
AppColors.textTertiary    // 辅助说明、占位
AppColors.divider         // 分割线
AppColors.primary         // 主色（可换）
AppColors.success / danger
```

**禁止**：任何地方写 `Color(0xFF...)` 硬编码。唯一例外是壁纸绘制器和开关的渐变（那里本来就是在画具体颜色）。

---

## 二、卡片

**用 `AppCard`**（`lib/widgets/app_card.dart`），不要再手写 `Container + BoxDecoration`。

```dart
AppCard(
  padding: const EdgeInsets.all(16),
  onTap: () {},
  child: ...,
)
```

**卡片是不透明的**，原因写在 `kCardGradient` 的注释里：半透明 + 壁纸 = 花纹透上来，字发灰。

**禁止**：
- 自己拼 `BoxDecoration` 画卡片
- 给卡片加 `BackdropFilter`（除了底部弹层）
- 卡片上用 `Colors.white` 之外的半透明填充

---

## 三、间距

只用这几个值，都是 4 的倍数：

| 场景 | 值 |
|---|---|
| 页面左右边距 | **20** |
| 卡片内边距 | **16**（紧凑处 12） |
| 卡片之间 | **10** |
| 区块之间 | **24** |
| 小元素之间 | **6 / 8** |
| 列表底部留白 | **40** |

**禁止**：13、17、19 这种随手写的数。

---

## 四、圆角

| 元素 | 值 |
|---|---|
| 卡片 | **14** |
| 按钮 | **12** |
| 胶囊 | **20**（高度的一半） |
| 小标签 / chip | **5** |
| 底部弹层顶部 | **20** |

---

## 五、字号阶梯

只用这些：`10.5 / 11 / 11.5 / 12 / 12.5 / 13 / 14 / 14.5 / 15 / 17 / 21 / 24 / 26`

| 用途 | 字号 | 字重 |
|---|---|---|
| 页面标题（AppBar） | 17 | w600 |
| 首页大标题 | 24 | w800 |
| 区块标题 | 17 | w700 |
| 卡片主文字 | 14.5 | w500–600 |
| 正文 | 13 | w400 |
| 辅助说明 | 11.5–12 | w400 |
| 极小标注 | 10.5 | w400 |

行高：正文 1.6–1.7，标题 1.3，书正文 1.95。

---

## 六、图标

- 尺寸只用 **15 / 17 / 19 / 20 / 21 / 24**
- 颜色：`AppColors.textTertiary`（默认）、`AppColors.primary`（可点）、`AppColors.textSecondary`（次级）
- 优先用 `Icons.*_rounded`，圆润度更接近整体风格

---

## 七、页面骨架

**标准结构**：

```dart
AppBackground(
  child: Scaffold(
    appBar: AppBar(title: Text('页面名')),   // 只在 AppBar 里放标题和操作
    body: ...                                 // 内容全部在 body
  ),
)
```

- AppBar **不透明**，不叠加 `flexibleSpace` 玻璃
- 首页的标题也在 AppBar 里，天气 / 搜索 / 切换 / 列表全部属于 body

**列表页**：`AppCard` 之间 10px，页面左右 20px，底部留 40px。

---

## 八、几条踩过的坑（必须避开）

1. **不要用 `const` 包裹读 `AppColors` 的组件**
   ```dart
   const GlassBackdrop()   // ✗ 主题切换时不会重建，颜色停在旧值
   GlassBackdrop()         // ✓
   ```
   同理：`const _Row(...)`、`const [_CacheRow()]`、`const WeatherBar()`。
   判断方法：这个组件内部有没有读 `AppColors`？有就不能 const。

2. **`AnimatedContainer` 不能在 `color` 和 `gradient` 之间插值**
   两端必须同类型，否则切换是硬跳。

3. **`ListView` / `GridView` 嵌套在 `ListView` 里时必须 `padding: EdgeInsets.zero`**
   否则会继承 `MediaQuery` 的安全区，顶部空出一大块。

4. **`extendBodyBehindAppBar` 之后，body 要自己让出 `topPadding`**
   否则内容被顶栏压住。

5. **页面级背景用 `AppBackground`，不要自己画 Stack**
   壁纸、光晕、压暗都在它内部处理。

---

## 九、新增页面的检查清单

- [ ] 根节点是 `AppBackground`
- [ ] 标题在 `AppBar`，不在 body
- [ ] 列表项用 `AppCard`
- [ ] 颜色全部来自 `AppColors`，没有 `Color(0x...)`
- [ ] 间距是 4 的倍数，左右 20
- [ ] 没有 `const` 包裹的动态颜色组件
- [ ] 深色 / 浅色都看过一遍
- [ ] 设了壁纸的情况下，文字依然看得清

---

## 十、当前已知的遗留

（记录待收敛的地方，做一次划掉一条）

- [ ] 详情页、阅读器面板里还有几处手写的 `BoxDecoration`，未换成 `AppCard`
- [ ] `GlassPanel` 目前无人使用，确认后可删
- [ ] 部分页面间距仍不统一（13 / 17 这类值），逐步归到 4 的倍数
