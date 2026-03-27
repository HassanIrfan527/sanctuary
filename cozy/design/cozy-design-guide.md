# Cozy Theme — Design Guide & Color Palette

Reference palette and design tokens for building Cozy theme components
(notification daemons, widgets, overlays, etc.)

---

## Everforest Dark Palette

### Backgrounds
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| bg_dim     | `#232a2e` | Deepest background, overlays        |
| bg0        | `#2d353b` | Primary background                  |
| bg1        | `#343f44` | Raised surfaces (cards, popups)     |
| bg2        | `#3d484d` | Selection, hover states             |
| bg3        | `#475258` | Borders, dividers                   |
| bg4        | `#4f585e` | Subtle separators                   |
| bg5        | `#56635f` | Disabled/muted backgrounds          |

### Semantic Backgrounds
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| bg_red     | `#514045` | Error/destructive background        |
| bg_green   | `#425047` | Success background                  |
| bg_blue    | `#3a515d` | Info background                     |
| bg_yellow  | `#4d4c43` | Warning background                  |
| bg_visual  | `#543a48` | Visual selection highlight          |

### Foreground
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| fg         | `#d3c6aa` | Primary text                        |
| grey0      | `#7a8478` | Disabled text, timestamps           |
| grey1      | `#859289` | Secondary text, subtitles           |
| grey2      | `#9da9a0` | Tertiary text, placeholders         |

### Accents
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| red        | `#e67e80` | Errors, critical, destructive       |
| orange     | `#e69875` | Warnings, attention                 |
| yellow     | `#dbbc7f` | Caution, highlights                 |
| green      | `#a7c080` | Success, active, confirm            |
| aqua       | `#83c092` | Links, secondary accent             |
| blue       | `#7fbbb3` | Primary accent, focus               |
| purple     | `#d699b6` | Special, badges, tags               |

---

## Everforest Light Palette

### Backgrounds
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| bg_dim     | `#efebd4` | Deepest background, overlays        |
| bg0        | `#fdf6e3` | Primary background                  |
| bg1        | `#f4f0d9` | Raised surfaces (cards, popups)     |
| bg2        | `#efebd4` | Selection, hover states             |
| bg3        | `#e6e2cc` | Borders, dividers                   |
| bg4        | `#e0dcc7` | Subtle separators                   |
| bg5        | `#bdc3af` | Disabled/muted backgrounds          |

### Semantic Backgrounds
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| bg_red     | `#fbe3da` | Error/destructive background        |
| bg_green   | `#f0f1d2` | Success background                  |
| bg_blue    | `#e9f0e9` | Info background                     |
| bg_yellow  | `#faedcd` | Warning background                  |
| bg_visual  | `#eaedc8` | Visual selection highlight          |

### Foreground
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| fg         | `#5c6a72` | Primary text                        |
| grey0      | `#a6b0a0` | Disabled text, timestamps           |
| grey1      | `#939f91` | Secondary text, subtitles           |
| grey2      | `#829181` | Tertiary text, placeholders         |

### Accents
| Token      | Hex       | Usage                              |
|------------|-----------|-------------------------------------|
| red        | `#f85552` | Errors, critical, destructive       |
| orange     | `#f57d26` | Warnings, attention                 |
| yellow     | `#dfa000` | Caution, highlights                 |
| green      | `#8da101` | Success, active, confirm            |
| aqua       | `#35a77c` | Links, secondary accent             |
| blue       | `#3a94c5` | Primary accent, focus               |
| purple     | `#df69ba` | Special, badges, tags               |

---

## Design Tokens

### Spacing
| Token  | Value | Usage                        |
|--------|-------|------------------------------|
| xs     | 4px   | Inline padding, icon gaps    |
| sm     | 8px   | Element padding              |
| md     | 12px  | Card padding, list gaps      |
| lg     | 16px  | Section padding              |
| xl     | 24px  | Panel margins                |
| xxl    | 32px  | Page-level margins           |

### Border Radius
| Token     | Value | Usage                      |
|-----------|-------|----------------------------|
| sharp     | 0px   | Badges, tags               |
| sm        | 6px   | Buttons, inputs            |
| md        | 12px  | Cards, popups              |
| lg        | 17px  | Panels, launcher (fuzzel)  |
| pill      | 999px | Pill buttons, toggles      |

### Typography
| Role       | Font               | Weight   | Size  |
|------------|--------------------|----------|-------|
| body       | Google Sans Flex    | Regular  | 14px  |
| subtitle   | Google Sans Flex    | Medium   | 12px  |
| title      | Google Sans Flex    | SemiBold | 16px  |
| heading    | Google Sans Flex    | Bold     | 20px  |
| mono       | JetBrains Mono     | Regular  | 13px  |

### Shadows (dark mode only)
| Level   | CSS                                         |
|---------|---------------------------------------------|
| subtle  | `0 1px 3px rgba(0,0,0,0.3)`                 |
| card    | `0 2px 8px rgba(0,0,0,0.4)`                 |
| popup   | `0 4px 16px rgba(0,0,0,0.5)`                |
| overlay | `0 8px 32px rgba(0,0,0,0.6)`                |

### Opacity
| Token      | Value | Usage                            |
|------------|-------|----------------------------------|
| solid      | 1.0   | Primary content                  |
| high       | 0.87  | Secondary text                   |
| medium     | 0.60  | Disabled, inactive               |
| low        | 0.38  | Hints, placeholders              |
| surface    | 0.90  | Translucent panel backgrounds    |
| overlay    | 0.78  | Dim layers behind modals         |

---

## Component Recipes

### Notification Daemon (swaync / custom)
```
Background:     bg1 (#343f44)  at 95% opacity
Border:         bg3 (#475258)  1px solid
Title text:     fg  (#d3c6aa)
Body text:      grey2 (#9da9a0)
Timestamp:      grey0 (#7a8478)
Close button:   grey1 (#859289) → red (#e67e80) on hover
Urgency low:    left border 3px aqua (#83c092)
Urgency normal: left border 3px blue (#7fbbb3)
Urgency critical: left border 3px red (#e67e80), bg_red (#514045) background
Border radius:  md (12px)
Padding:        md (12px)
Gap between:    sm (8px)
```

### Popup / Tooltip
```
Background:     bg2 (#3d484d)
Border:         bg3 (#475258)  1px solid
Text:           fg  (#d3c6aa)
Border radius:  sm (6px)
Padding:        sm (8px) horizontal, xs (4px) vertical
Shadow:         popup level
```

### Widget Card (clock, weather, etc.)
```
Background:     bg1 (#343f44) at surface opacity (0.90)
Border:         bg3 (#475258)  1px solid
Title:          fg  (#d3c6aa)  title weight
Value:          green (#a7c080) or blue (#7fbbb3)
Subtitle:       grey1 (#859289)
Border radius:  md (12px)
Padding:        lg (16px)
Shadow:         card level
```

### Button
```
Primary:        blue (#7fbbb3) bg, bg_dim (#232a2e) text
Secondary:      bg2 (#3d484d) bg, fg (#d3c6aa) text
Destructive:    red (#e67e80) bg, bg_dim (#232a2e) text
Hover:          10% lighter
Active:         5% darker
Border radius:  sm (6px)
Padding:        sm (8px) vertical, md (12px) horizontal
```

---

## Hyprland Integration

### Border Colors (dark)
```
Active:   rgba(7fbbb3ee)   — blue accent
Inactive: rgba(2d353baa)   — bg0, semi-transparent
```

### Border Colors (light)
```
Active:   rgba(3a94c5ee)   — blue accent
Inactive: rgba(e6e2ccaa)   — bg3, semi-transparent
```

---

## CSS Variables Template

Copy into any GTK/CSS-based component:

```css
:root {
    --bg-dim: #232a2e;
    --bg0: #2d353b;
    --bg1: #343f44;
    --bg2: #3d484d;
    --bg3: #475258;
    --bg4: #4f585e;
    --bg5: #56635f;
    --fg: #d3c6aa;
    --red: #e67e80;
    --orange: #e69875;
    --yellow: #dbbc7f;
    --green: #a7c080;
    --aqua: #83c092;
    --blue: #7fbbb3;
    --purple: #d699b6;
    --grey0: #7a8478;
    --grey1: #859289;
    --grey2: #9da9a0;
}
```

## QML Properties Template

For Quickshell or custom QML widgets:

```qml
readonly property color bgDim: "#232a2e"
readonly property color bg0: "#2d353b"
readonly property color bg1: "#343f44"
readonly property color bg2: "#3d484d"
readonly property color bg3: "#475258"
readonly property color fg: "#d3c6aa"
readonly property color red: "#e67e80"
readonly property color orange: "#e69875"
readonly property color yellow: "#dbbc7f"
readonly property color green: "#a7c080"
readonly property color aqua: "#83c092"
readonly property color blue: "#7fbbb3"
readonly property color purple: "#d699b6"
readonly property color grey0: "#7a8478"
readonly property color grey1: "#859289"
readonly property color grey2: "#9da9a0"
```
