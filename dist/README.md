# Loom

A Roblox UI library in Luau. One bundled file, 33 styles, 136 vector icons and
every element you expect — and nothing to host: the icons are drawn from their
geometry at runtime instead of being loaded as images. It also speaks five other
libraries' dialects — Rayfield, Fluent, Linoria, Obsidian and WindUI — so a
script already written against one of them can keep its calls.

`Loom.Version` is `"1.1.0"`.

```
local Loom = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/dist/loom.lua"))()

local Window = Loom:CreateWindow({ Name = "My Script", Theme = "Glass" })
local Main = Window:CreateTab("Main", "home")

Main:Toggle({ Text = "Enabled", Flag = "enabled", Default = true })
Main:Slider({ Text = "Speed", Flag = "speed", Min = 8, Max = 100, Default = 16 })

Window:Notify({ Title = "Loaded", Content = "Ready.", Kind = "success" })
```

Press `RightControl` to hide or show the window. A fuller example is in
[example.luau](example.luau).

## Window

```lua
local Window = Loom:CreateWindow({
	Name = "Loom",            -- title bar text
	Theme = "Nice",           -- a style name, or a style table
	Size = Vector2.new(660, 480),
	Keybind = "RightControl", -- Enum.KeyCode or a name; false to disable
	Parent = nil,             -- else gethui(), else CoreGui, else PlayerGui
})
```

| Method | Does |
| --- | --- |
| `CreateTab(name, icon?)` | New tab. The first one created is selected. `icon` is any name from `Loom.Icons.names()`, a unicode glyph, or an `rbxassetid://` id. |
| `SelectTab(tabOrName)` | Bring a tab to the front, by tab or by tab name. Fires `Window.TabSelected`. |
| `SetTheme(nameOrTable)` | Restyle everything already on screen. |
| `Notify(config)` | Toast. `{ Title, Content, Kind = "info"\|"success"\|"warning"\|"danger", Duration }`. |
| `SetVisible(bool)` / `Toggle()` | Show or hide the window. |
| `Minimize()` | Collapse to the title bar, or expand again. |
| `Maximize()` | Fill the viewport, or go back to the size it had before. On macOS this is what the green dot does. |
| `SetSize(size)` | Resize to a `Vector2`, floored at the same 380x260 minimum the constructor uses. |
| `Center()` | Put the window back in the middle of the screen after it has been dragged. |
| `SetScale(scale)` / `GetScale()` | Zoom the whole window, clamped to 0.5-1.5. Dragging and resizing divide the cursor delta by the scale, so the window stays under the pointer at any zoom. |
| `SetKeybind(key)` | Take an `Enum.KeyCode`, a name like `"K"`, or `nil` to disable the shortcut; the header hint follows. An unknown name leaves it alone. |
| `GetFlag(name)` / `SetFlag(name, value)` | Read or drive any element by its `Flag`. |
| `GetFlags()` | Every flag and its current value, as one table. |
| `SaveConfig(name)` / `LoadConfig(name)` | Write or apply every flagged element. Returns the path / whether it loaded. |
| `OnTheme(fn)` | Run `fn(theme)` on every theme change. |
| `OnClose(fn)` | Run `fn()` before teardown when the window is destroyed. |
| `CreateSettingsTab()` | Add the built-in appearance panel: a searchable style browser plus live interface controls. |
| `Destroy()` | Tear the whole thing down. Safe to call twice. |

Fields: `Window.Theme`, `Window.Tabs`, `Window.Flags`, `Window.Selected`,
`Window.Panel`, `Window.Sidebar`, `Window.Body`, `Window.Popups`.

## Elements

Every element takes `Text`, an optional `Description`, an optional `Flag` for
config, and an optional `Callback` that fires with the new value.

| | Config keys |
| --- | --- |
| `Tab:Section{ Text }` | `Text` |
| `Tab:Divider()` | – |
| `Tab:Label{ Text }` | `Text`, `Height?` — wraps and grows |
| `Tab:Paragraph{ Title, Text }` | `Title`, `Text` — wraps and grows |
| `Tab:Button{ Text, Callback }` | `Text`, `Height?` |
| `Tab:Toggle{ ... }` | `Default: boolean` |
| `Tab:Slider{ ... }` | `Min`, `Max`, `Default`, `Rounding` (decimals), `Suffix` |
| `Tab:Dropdown{ ... }` | `Options: {string}`, `Default`, `Multi`, `Search` |
| `Tab:Textbox{ ... }` | `Default`, `Placeholder`, `ClearOnFocus`, `Numeric` |
| `Tab:Keybind{ ... }` | `Default: Enum.KeyCode \| string` |
| `Tab:ColorPicker{ ... }` | `Default: Color3`, `Alpha` |

Each returns an instance with `Set(value)`, `Get()`, `SetText(text)`,
`SetVisible(bool)`, `GetVisible()`, `Changed` (a Signal) and `Destroy()`.
Programmatic changes fire `Callback` too, except while a config is loading.

Beyond those, an element offers `GetFlag()` and `SetDescription(text)` — which
builds the line under the title on a row created without one, and clears it with
`nil`, laying the row out exactly as if the description had been in the config to
begin with. A tab offers `Clear()`, which destroys every element on it and drops
their flags while the tab and its page survive, ready to be filled again, and
`GetFlag(name)` / `SetFlag(name, value)` for one element on that tab.

## Styles

33 styles in four groups. `Loom.Theme.names()` lists every one of them.

| Group | Styles | What it is |
| --- | --- | --- |
| The originals | `Nice`, `Glossy`, `Glass`, `Poly`, `Pro`, `Goofy` (light), `Clean` (light) | The first seven: dark greys, a glassy pair, a flat teal, two light ones. |
| Operating systems | `iOS`, `iOS Dark`, `macOS`, `macOS Dark`, `Windows`, `Windows Dark`, `Linux`, `Linux Dark`, `Android`, `Android Dark` | Apple glass with green pill switches and a circular close; macOS traffic lights, a centred title and Finder-style selection; Windows 11 Fluent caption glyphs on 4px controls; GNOME's lone close button and wide sidebar; Material You's big round sheet with a filled selected tab. |
| Idioms | `Neumorph`, `Neumorph Dark`, `Brutalist`, `Vaporwave`, `Retro`, `Pixel`, `Minecraft`, `Discord`, `Discord Light` | Soft UI that presses out of its own shadow; square black-and-yellow brutalist; glossy purple vaporwave; Windows 95 greys with a navy title bar; an arcade-cabinet navy and gold; Minecraft's stone inventory GUI; Discord's blurple. |
| Editor palettes | `Nord`, `Dracula`, `Tokyo Night`, `Gruvbox`, `Catppuccin`, `One Dark`, `Solarized` (light) | The desktop structure in a colour scheme you already know. |

A style is still a flat token table — colours, radii, row height, padding,
fonts, gloss, blur, shadow, duration and easing — but it carries *structure*
too, which is why `SetTheme` can restyle a window that is already on screen and
why an iOS window does not look like a Fluent one:

| Token | Does |
| --- | --- |
| `Chrome` | How the window draws its controls: `"traffic"` (three coloured dots at the top left, macOS), `"caption"` (glyph buttons at the top right, Windows), `"close"` (a single close button, GNOME and Material). |
| `TitleAlign` | A left-aligned or centred title. |
| `Round` | Controls — rows, buttons, inputs, switch tracks, sidebar entries — become pills instead of using a radius. |
| `Indicator` | Pixel width of the selected sidebar entry's accent bar; `0` on the styles that select with a fill instead. |
| `EntryAccent` | The selected entry is filled with the accent and its text uses `OnAccent`. |
| `Gradient` | Accent fills sweep from `Accent` to `AccentB` instead of staying flat. |
| `SwitchOn` / `SwitchKnob` / `SwitchKnobOn` | The switch track while on, and the knob while off and while on. |
| `SliderKnob` | The slider knob. |
| `DotClose` / `DotMinimize` / `DotZoom` | The traffic-light colours. |

Names resolve case- and space-insensitively, so `SetTheme("macos dark")` and
`SetTheme("MACOSDARK")` both land on `macOS Dark`.

```lua
Window:SetTheme("macOS Dark")
Window:SetTheme("Minecraft")
```

A style is a table, so tinting one is a patch — this is how you get a violet
macOS:

```lua
Loom:AddTheme("macOS Dark", { Name = "macOS Violet", Accent = Color3.fromRGB(191, 144, 255) })
Window:SetTheme("macOS Violet")
```

The presets live in [src/Core/Styles](src/Core/Styles): four structural bases —
`Glass`, `Desktop`, `Flat` and `Soft` — with three rosters of patches on top of
them. `Base.style(base, patch)` throws when a patch names a token that does not
exist, so a typo fails the smoke run rather than quietly leaving the base's
value on screen.

## Icons

`Loom.Icons` carries 136 [Lucide](https://lucide.dev) icons as vector geometry,
not images. Naming one draws it: the renderer walks the icon's polylines and lays
down a thin rotated frame per line piece. That is why the window still ships as
one file with nothing to upload, and why an icon is recoloured by the theme like
any other surface.

```lua
local Main = Window:CreateTab("Main", "home")
local Visuals = Window:CreateTab("Visuals", "palette")

Loom.Icons.has("sparkles")   -- true
#Loom.Icons.names()          -- 136
```

| | |
| --- | --- |
| `Icons.names()` | Every icon name, sorted, for building a picker. |
| `Icons.has(name)` | Whether this build carries geometry for it. |
| `Icons.draw(parent, name, theme, props)` | Draws it and returns the container `Frame`, or `nil` for a name this build does not carry. `props` takes the same `Position`, `AnchorPoint` and `Size` a glyph icon takes, plus an optional `Thickness` for the stroke width. |
| `Icons.isAsset(icon)` | Whether the name is an `rbxassetid://` or a bare number, and so should be drawn as an image. |
| `Icons.resolve(icon)` | Turns one of the remaining glyph stand-ins into its character. |

Nothing that used to render stops rendering: a name this build does not carry
falls back to a text label showing it, a raw character still works as a glyph,
and an asset id is still an image.

```lua
Window:CreateTab("Main", "home")            -- drawn geometry
Window:CreateTab("Main", "★")               -- a glyph, resolved as text
Window:CreateTab("Main", "rbxassetid://1")  -- an image, as before
```

The geometry lives in `src/Core/Icons/Data.luau`, generated from the
`lucide-static` dev dependency by [tools/icons.mjs](tools/icons.mjs): it scans
each SVG, flattens paths, arcs and curves into polylines, simplifies them, and
writes a 24x24 table. `npm run icons` regenerates it, and `npm run icons:check` —
part of `npm run check` — fails when the committed table is stale, so it is
always exactly what the tool produces.

## Appearance panel

`Window:CreateSettingsTab()` adds a settings tab in the spirit of an
application's Settings → Appearance page: browse all 33 styles with a search box,
flip to the other half of a style's light/dark pair, pick an accent, and tune
zoom, row height, corner radius, backdrop blur, pill controls and gloss while the
window is on screen.

```lua
Window:CreateSettingsTab()
```

Every change rebuilds one style named `Custom` on top of the base you chose,
applying the overrides as a patch — so dragging a slider repaints the window
instead of adding a registry entry per movement, and the tuned look stays
reachable as `Loom.Theme.get("Custom")` afterwards.

Its controls carry flags, so `SaveConfig` keeps the panel alongside a script's own
values: `loomStyle`, `loomDark`, `loomAccent`, `loomZoom` (0.75-1.35), `loomRow`
(32-60), `loomCorner` (0-24), `loomBlur` (0-48), `loomPills`, `loomGloss` and
`loomKey`. `Reset appearance` clears every override, returns the window to `Nice`
and puts the zoom back to 1.

## Dialects

`Loom.Api` re-expresses the same window in the call surface of five libraries
people already write scripts against, so an existing script keeps its calls and
still gets Loom's styles, icons, config system and executor fallbacks underneath:

```lua
local Fluent = Loom.Api.Fluent

local Window = Fluent:CreateWindow({ Title = "My Script", Theme = "Dark" })
local Main = Window:AddTab({ Title = "Main", Icon = "home" })

Main:AddToggle("enabled", { Title = "Enabled", Default = true })
Fluent:Notify({ Title = "Loaded", Content = "Ready." })
```

| Dialect | Entry point | Tabs | Elements |
| --- | --- | --- | --- |
| `Rayfield` | `:CreateWindow{ Name, Theme }` | `Window:CreateTab(name, icon)` | `Tab:Create*` — Section, Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Label, Paragraph |
| `Fluent` | `:CreateWindow{ Title, SubTitle, Theme, MinimizeKey }` | `Window:AddTab{ Title, Icon }` | `Tab:Add*` — Section, Paragraph, Button, Toggle, Slider, Dropdown, Colorpicker, Keybind, Input |
| `Linoria` | `:CreateWindow{ Title }` | `Window:AddTab(name)` | `Tab:AddLeftGroupbox` / `:AddRightGroupbox`, then `Group:Add*` |
| `Obsidian` | `:CreateWindow{ Title, Footer }` | `Window:AddTab(name, icon)`, `:AddKeyTab(name)` | `Tab:AddGroupbox{ Name, Side }`, `Tab:AddLeftTabbox`, then `Group:Add*` |
| `WindUI` | `:CreateWindow{ Title, Size, Theme }` | `Window:Tab{ Title, Icon }`, `Window:Section{ Title }` | `Button`, `Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`, `Colorpicker`, `Paragraph`, `Space`, `Divider` on a tab, section or group |

Beyond the elements: Rayfield has `:Notify`, `:LoadConfiguration`,
`:SaveConfiguration` and `Dropdown:Refresh`; Fluent has `Fluent.Options`,
`:Notify`, `:SetTheme`, `Window:Dialog` and `Keybind:GetState`; Linoria and
Obsidian have a live `Options` (and `Toggles`) index, `:Notify` and `:Unload`;
WindUI has `WindUI.Options`, `:Notify`, `:Popup` and a 0-based
`Window:SelectTab(index)`.

Every dialect files its flagged rows in its own index, and the entries there are
the real Loom row — `Value`, `:SetValue(v)` and `:OnChanged(fn)` are the ones the
window drives, so nothing can drift out of step with `Set` and `Get`.

`Loom.Api.install()` publishes every dialect into the executor's shared globals
(`getgenv().Rayfield`, `getgenv().Fluent`, …), so a payload written against the
real thing runs on Loom once its `loadstring` line is dropped. `Loom.Api.Names`
lists the five, and `Loom.Api.Support` — the plumbing they are built on — is
useful on its own:

| | |
| --- | --- |
| `Support.color(value)` | A `Color3` from a `Color3`, `"#rrggbb"`, `{ R, G, B }` or a picker's `{ Color = … }`. |
| `Support.key(value)` | An `Enum.KeyCode` from the enum or its name, and `nil` for a mouse button. |
| `Support.kind(value)` | A notification kind from `ok` / `warn` / `error` and friends. |
| `Support.duration(value, fallback)` | Seconds, reading anything past a minute as milliseconds. |
| `Support.precision(increment)` | Decimal places that land a slider on an increment. |
| `Support.icon(value)` | A Loom icon name, or `nil` for an asset id or a number. |
| `Support.style(map, name)` | A dialect's theme name resolved onto a Loom style. |
| `Support.options(values)` | An array, a list of records or a label-to-value dictionary as `{ Names, Values }`. |
| `Support.augment(object, methods)` / `Support.remember(store, element)` | The two moves every dialect makes: add a vocabulary to a real Loom object, and file a flagged row in an index. |

### What a dialect does not change

Loom has one window, one column and no modal, so a few things land on the nearest
real equivalent rather than a copy:

- **One window at a time.** A dialect's `CreateWindow` goes through
  `Loom:CreateWindow`, which replaces the previous window — that is what makes
  re-injection safe, and it means a script should build one window.
- **Groupboxes are captions.** Linoria's and Obsidian's two-column boxes become a
  section header with the rows after it, so `Side` and `IconName` have nowhere to
  go.
- **No modal.** Fluent's `Window:Dialog` and WindUI's `:Popup` show their text as
  a toast and land one real button row per entry, so the callbacks are reachable.
- **No addons.** ThemeManager, SaveManager and InterfaceManager are not
  reimplemented; `Window:SetTheme` and `Window:SaveConfig` cover what they did.
- **Mouse-button keybinds do not bind.** Loom stores an `Enum.KeyCode`, so `"MB1"`
  and `"MB2"` leave a keybind unset rather than pretending.
- **Icons are Loom's.** A Lucide name draws; an asset id or a number gets none.

Each dialect is one file in [src/Api](src/Api) — [Rayfield](src/Api/Rayfield.luau),
[Fluent](src/Api/Fluent.luau), [Linoria](src/Api/Linoria.luau),
[Obsidian](src/Api/Obsidian.luau) and [WindUI](src/Api/WindUI.luau) — built on
[Support.luau](src/Api/Support.luau) and bound by [init.luau](src/Api/init.luau).
They hand back Loom's own elements, extended only where a dialect spells
something differently, which is how a whole vocabulary is added without a second
copy of the state.

## Executor support

`Loom.Env` probes each capability once, under every spelling executors are known
to use, and degrades instead of throwing when one is missing. This is the layer
that decides whether the same bundle runs on Sirus, Delta, Wave, Solara, an
executor using Synapse's spellings, or a client with no executor functions at
all:

| | |
| --- | --- |
| Window parent | your `Parent`, else `gethui()`, else `CoreGui` when a protect function exists, else `PlayerGui`. A container is used only if it actually accepts the ScreenGui, so a locked `CoreGui` or a hidden container that refuses children falls through to the next one. |
| Config files | `writefile` / `write_file`, `readfile` / `read_file`, plus `isfile` / `is_file`, `makefolder` / `make_folder` and `listfiles` / `list_files` where they exist. |
| Clipboard | `setclipboard`, `toclipboard` or `set_clipboard`. |
| HTTP | `request`, `http_request`, `httprequest` or `syn.request`, then `game:HttpGet` as a last resort. |
| Protection | `protect_gui`, `protectgui` or `syn.protect_gui`. |
| Identity | `getthreadidentity`, `getidentity` or `get_thread_identity`. |
| Executor name | `identifyexecutor` or `getexecutorname`. |

```lua
print(Loom.Env.Executor)                          -- "Sirus", or "Unknown"
print(Loom.Env.Identity)                          -- 3, or nil
print(Loom.Env.CanSave, Loom.Env.CanFetch)        -- what this client can do
print(table.concat(Loom.Env.Capabilities, ", "))  -- every capability found

local body = Loom.Env.Fetch("https://example.com")
Loom.Env.Copy("text")
Loom.Env.Write("Loom/notes.txt", "hi")             -- false instead of throwing
```

`Fetch` returns `nil` when nothing can fetch at all; `Copy` and `Write` become
no-ops that report failure. `SaveConfig` returns `nil` on an executor with no
filesystem and `LoadConfig` returns `false` when there is nothing to read.

`Loom:CreateWindow` registers the window in the executor's shared table
(`getgenv().Loom`), so re-injecting a script replaces the previous window instead
of stacking a second one behind it. `Window:Destroy()` clears that registration
and is safe to call more than once.

## Project layout

```
src/
  init.luau          entry point: CreateWindow, AddTheme, shared modules
  Core/              Signal, New, Animate, Theme, Token, Ui, Env, Input,
                     Element, Config
  Core/Icons/        init (the facade), Draw (the vector renderer) and Data
                     (136 Lucide icons, generated by tools/icons.mjs)
  Core/Styles/       Base (the four structural bases) plus the Os, Idiom and
                     Palette rosters — all 33 styles
  Window/            init (shell), Tab, Notify, Settings (the appearance panel)
  Elements/          Button, Toggle, Slider, Dropdown, Textbox, Keybind,
                     ColorPicker, Section, Divider, Label, Paragraph
  Api/               the dialect surfaces: Rayfield, Fluent, Linoria, Obsidian
                     and WindUI over a shared Support
tools/               tree / sourcemap / bundle / icons / smoke pipeline
types/               Roblox API and executor definitions for the analyzer
dist/loom.lua        the built bundle
```

## Development

```
npm install
npm run check     # format, icon table, build, typecheck, then run the library headlessly
npm run icons     # regenerate src/Core/Icons/Data.luau from lucide-static
```

`npm run build` writes `dist/loom.lua`. Modules use Luau string requires
(`require("@self/../Core/Ui")`), which the analyzer resolves through
`sourcemap.json` and the bundler rewrites into an internal module table.

`npm run smoke` is the interesting one: [tools/mock.luau](tools/mock.luau) is a
headless Roblox shim — instances, datatypes, enums, services, `TweenService`,
`HttpService` and the `task` library — and [tools/smoke.mjs](tools/smoke.mjs)
concatenates it with the bundle and one of the assertion files, then runs the
result under the real Luau interpreter. That is what catches the bugs a
typechecker cannot see.

[tools/smoke.luau](tools/smoke.luau) builds a window, creates every element,
drives their values, switches every theme, round-trips a config and tears it all
down. [tools/smoke-styles.luau](tools/smoke-styles.luau) is the style grader: it
applies all 33 styles to a live window and checks that the structure really
changed — which chrome idiom is on screen, that the traffic dots took their
colours from `DotClose`/`DotMinimize`/`DotZoom`, whether the sidebar selects
with a bar or a fill, whether controls became pills, and whether the switch's
fill follows `SwitchOn` and gains or loses its gradient as the theme changes.
[tools/smoke-env.luau](tools/smoke-env.luau) grades the executor layer
under four capability sets the mock can pretend to be: `full` (today's usual
executor), `aliases` (only the alternate spellings), `bare` (no executor
functions, a readonly `_G` and nothing to fetch with) and `locked` (`CoreGui` and
the hidden container both refuse children). Each profile asserts what was
detected, where the window ended up and what each call returns — so a fallback
that silently stops working fails the build.

[tools/smoke-api.luau](tools/smoke-api.luau) covers the rest of the surface: it
draws every icon and measures the result, builds the appearance panel and drives
its controls, and calls the window, tab and element methods added since the first
release. [tools/smoke-adapters.luau](tools/smoke-adapters.luau) grades the five
dialects — every element each one offers, its flag index, its theme mapping, its
notifications and its teardown, plus the `Support` helpers they share. The icon
geometry, the panel, the API and the dialects are graded rather than assumed.

## Credits

The icon geometry comes from [Lucide](https://lucide.dev), which is ISC
licensed, and is generated into `src/Core/Icons/Data.luau` by
[tools/icons.mjs](tools/icons.mjs).
