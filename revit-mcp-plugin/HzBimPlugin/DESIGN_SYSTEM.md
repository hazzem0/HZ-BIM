# HZ-BIM Design System — "Carbon & Neon"

> **Single source of truth** for all colors, typography, spacing, and icon styles across the HZ-BIM Revit plugin.
> Last updated: 2026-11-14

---

## 🎨 Brand Color Palette

These colors are shared between **ribbon icons** (`Core/RibbonIcons.cs`) and **all WPF windows** (`UI/Themes/DarkTheme.cs`).

| Role        | Name          | Hex       | RGB              | C# Token            | Usage                              |
|-------------|---------------|-----------|------------------|----------------------|------------------------------------|
| **Primary** | Neon Orange       | `#F2380F` | `212, 175, 55`    | `BrandPrimary`       | Main accent, buttons, active state |
| **Dark**    | Deep Orange     | `#C8280C` | `184, 146, 42`    | `BrandDark`          | Pressed/hover, depth layers        |
| **Teal**    | Facet Blue    | `#5A78C8` | `91, 141, 239`    | `BrandTeal`          | Secondary accent, info badges      |
| **Amber**   | Glow Orange   | `#FF8A4C` | `242, 201, 76`   | `BrandAmber`         | Highlights, warnings, sparkles     |
| **Green**   | Emerald       | `#10B981` | `16, 185, 129`   | `BrandGreen`         | Success, running, ON state         |
| **Red**     | Red           | `#EF4444` | `239, 68, 68`    | `BrandRed`           | Error, stopped, OFF state          |

---

## 🧭 HZ-BIM Identity

| Role | Hex | C# Token | Usage |
|------|-----|----------|-------|
| Facet Navy | `#282F4D` | `BrandNavy` | Header bars, brand surfaces, ribbon icon bodies |
| Deep Navy | `#161A2B` | `BrandNavyDeep` | Gradient end, deepest surface |
| Text on Orange | `#121117` | `FgOnAccent` | Text on any orange (accent) button |

Rules: headers are a navy gradient with a neon-orange title and a 2px neon-orange underline. Orange buttons always use carbon text (`FgOnAccent`), never white.

---

## 🌑 Dark Mode Surfaces

| Role         | Hex       | RGB              | C# Token       | Usage                    |
|--------------|-----------|------------------|----------------|--------------------------|
| Canvas       | `#121117` | `11, 20, 38`     | `BgDark`       | Window background        |
| Card         | `#1C1E25` | `19, 33, 61`     | `BgCard`       | Panel / card fill        |
| Card Hover   | `#252833` | `26, 43, 77`     | `BgCardHover`  | Card hover state         |
| Input        | `#16171C` | `15, 26, 49`     | `BgInput`      | Input field background   |
| Header       | `#0B0B0E` | `7, 14, 28`     | `BgHeader`     | Title bars, footers      |
| Cancel Btn   | `#2C3142` | `36, 55, 92`     | `BgCancel`     | Secondary buttons        |
| Cancel Hover | `#3A4058` | `46, 68, 112`     | `BgCancelHover`| Secondary button hover   |

---

## ✏️ Text Colors

| Role        | Hex       | C# Token     | Usage                        |
|-------------|-----------|--------------|------------------------------|
| White       | `#FFFFFF` | `FgWhite`    | High-contrast text, headings |
| Light       | `#D6D8DE` | `FgLight`    | Primary body text            |
| Dim         | `#8C90A0` | `FgDim`      | Placeholder, secondary text  |
| Required    | `#EF4444` | `FgRequired` | Required field markers       |
| Success     | `#10B981` | `FgGreen`    | Success messages             |
| Highlight   | `#FF8A4C` | `FgGold`     | Highlighted / gold text      |
| Warning     | `#EF4444` | `FgWarning`  | Warning messages             |

---

## 📐 Borders & Dividers

| Role          | Hex       | C# Token       | Usage                   |
|---------------|-----------|-----------------|-------------------------|
| Subtle Border | `#2C3142` | `BorderDim`     | Card borders, dividers  |
| Accent Border | `#F2380F` | `BorderAccent`  | Active/selected borders |
| Focus Ring    | `#5A78C8` | `BorderFocus`   | Focused input border    |

---

## 🏷️ Category Accents

Used in Tools Hub to color-code tool categories:

| Category     | Color        | Hex       | C# Token       |
|--------------|-------------|-----------|-----------------|
| Export       | Neon Orange     | `#F2380F` | `CatExport`     |
| Families     | Glow Orange | `#FF8A4C` | `CatFamily`     |
| Quick Views  | Emerald     | `#10B981` | `CatQuickView`  |
| Views/Sheets | Facet Blue  | `#5A78C8` | `CatViewSheet`  |

---

## 🔤 Typography

| Property    | Value      |
|-------------|------------|
| Font Family | `Segoe UI` |
| Body Size   | `13px`     |
| Label Size  | `12px`     |
| Header Size | `14px`     |
| Weight      | `SemiBold` for headers, `Normal` for body |

---

## 📏 Spacing & Radii

| Token          | Value            | Usage                  |
|----------------|------------------|------------------------|
| `CardRadius`   | `8px`            | Card / group box       |
| `ButtonRadius` | `6px`            | Buttons                |
| `InputRadius`  | `4px`            | Input fields, combos   |
| `CardPadding`  | `14, 10, 14, 14` | Card inner padding     |

---

## 🖼️ Ribbon Icon Style Guide

All 12 ribbon icons are **programmatic vector drawings** in `Core/RibbonIcons.cs` — no PNG files.

### Style Rules
- **Method:** WPF `DrawingContext` → `RenderTargetBitmap` at exactly 96 DPI
- **Sizes:** `32×32` for `LargeImage`, `16×16` for `Image`
- **Fill style:** Solid flat shapes — no gradients, no 3D effects
- **Stroke:** Rounded caps (`PenLineCap.Round`), rounded joins (`PenLineJoin.Round`)
- **Palette:** Uses only the 6 brand colors above + `White`

### Icon Inventory

| # | Button         | Shape Description                         | Primary Color  |
|---|----------------|-------------------------------------------|----------------|
| 1 | Start HZ-BIM  | ▶ Play triangle inside circle             | Navy   |
| 2 | AI Chat        | 💬 Speech bubble + amber sparkle          | Navy   |
| 3 | Project Files  | 📁 Folder (dark) + white doc page         | Dark / Primary |
| 4 | Connect Claude | 🔗 Two connected nodes + sparkle          | Primary / Teal |
| 5 | Local AI       | 🧠 CPU chip with pins + teal core         | Primary / Teal |
| 6 | Tools Hub      | ⊞ 2×2 colored grid                       | All 4 colors   |
| 7 | Export         | ⬆ Arrow rising from U-shaped tray         | Navy   |
| 8 | Families       | 📦 3 nested offset squares + white "+"    | Dark/Primary/Teal |
| 9 | Quick Views    | 👁 Eye with pupil + amber speed lines     | Primary / Amber|
| 10| Views & Sheets | 📄 3 stacked pages + white text lines     | Slate/Dark/Primary |
| 11| Settings       | ⚙ 8-tooth gear cog                       | Navy   |
| 12| Check Updates  | 🔄 Circular arrow + teal download arrow   | Primary / Teal |

### Badge Overlays (Toggle State)
- **Running (ON):** Green circle (`#10B981`) + white checkmark → `WithCheckBadge()`
- **Stopped (OFF):** Red circle (`#EF4444`) + white X → `WithCrossBadge()`

---

## 📁 File Reference

| Purpose              | File Path                                |
|----------------------|------------------------------------------|
| **Design System**    | `UI/Themes/DarkTheme.cs`                 |
| **Ribbon Icons**     | `Core/RibbonIcons.cs`                    |
| **Chat Icons**       | `UI/Themes/ChatIcons.cs`                 |
| **This Reference**   | `DESIGN_SYSTEM.md` ← you are here       |

---

## ✅ Rules for New Windows / Features

1. **Always** call `DarkTheme.Apply(this)` in your window constructor
2. **Never** hardcode color values — use `DarkTheme.BgCard`, `DarkTheme.BrandPrimary`, etc.
3. **Use factory methods** — `MakePrimaryButton()`, `MakeTextBox()`, `MakeGroupBox()`, etc.
4. **New icons** must use only the 6 brand colors + white, drawn as vectors
5. **Category colors** must map to `CatExport`, `CatFamily`, `CatQuickView`, or `CatViewSheet`
