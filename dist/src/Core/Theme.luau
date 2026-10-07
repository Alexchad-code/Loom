--!strict
-- The style registry. Every visual decision in Loom reads its tokens, so an
-- entire look is one table: Window:SetTheme("macOS"). The structural presets
-- themselves live in Styles/.

local Token = require("@self/Token")
local Styles = require("@self/Styles")

export type Theme = Token.Theme

local Themes: { [string]: Theme } = {}

Themes.Nice = {
	Name = "Nice",
	Light = false,

	Window = Color3.fromRGB(16, 17, 22),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(13, 14, 19),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(24, 26, 33),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(33, 36, 46),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(33, 36, 47),
	InsetTransparency = 0,
	Track = Color3.fromRGB(44, 48, 62),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(22, 24, 31),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(44, 48, 60),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(231, 234, 242),
	TextDim = Color3.fromRGB(152, 159, 175),
	TextFaint = Color3.fromRGB(100, 108, 124),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(108, 132, 255),
	AccentB = Color3.fromRGB(168, 108, 255),
	Success = Color3.fromRGB(74, 222, 128),
	Warning = Color3.fromRGB(250, 176, 80),
	Danger = Color3.fromRGB(248, 90, 110),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(248, 90, 110),
	DotMinimize = Color3.fromRGB(250, 176, 80),
	DotZoom = Color3.fromRGB(74, 222, 128),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(108, 132, 255),
	SwitchKnob = Color3.fromRGB(231, 234, 242),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(231, 234, 242),

	Corner = 12,
	SmallCorner = 8,
	StrokeWidth = 1,
	RowHeight = 44,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 148,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 15,

	Gloss = 0.1,
	Blur = 16,
	Shadow = 0.55,

	Duration = 0.18,
	Easing = Enum.EasingStyle.Quad,
}

Themes.Glossy = {
	Name = "Glossy",
	Light = false,

	Window = Color3.fromRGB(8, 9, 14),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(6, 7, 12),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(18, 20, 32),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(27, 30, 48),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(11, 13, 22),
	InsetTransparency = 0,
	Track = Color3.fromRGB(32, 36, 56),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(12, 14, 24),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(44, 50, 78),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(240, 244, 255),
	TextDim = Color3.fromRGB(158, 168, 200),
	TextFaint = Color3.fromRGB(88, 97, 132),
	OnAccent = Color3.fromRGB(6, 8, 16),

	Accent = Color3.fromRGB(56, 214, 255),
	AccentB = Color3.fromRGB(140, 96, 255),
	Success = Color3.fromRGB(80, 232, 150),
	Warning = Color3.fromRGB(255, 204, 92),
	Danger = Color3.fromRGB(255, 96, 124),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(255, 96, 124),
	DotMinimize = Color3.fromRGB(255, 204, 92),
	DotZoom = Color3.fromRGB(80, 232, 150),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(56, 214, 255),
	SwitchKnob = Color3.fromRGB(240, 244, 255),
	SwitchKnobOn = Color3.fromRGB(6, 8, 16),
	SliderKnob = Color3.fromRGB(240, 244, 255),

	Corner = 14,
	SmallCorner = 9,
	StrokeWidth = 1,
	RowHeight = 46,
	Pad = 16,
	Gap = 9,
	SidebarWidth = 152,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 15,

	Gloss = 0.3,
	Blur = 12,
	Shadow = 0.75,

	Duration = 0.24,
	Easing = Enum.EasingStyle.Quint,
}

Themes.Glass = {
	Name = "Glass",
	Light = false,

	Window = Color3.fromRGB(12, 15, 20),
	WindowTransparency = 0.35,
	Sidebar = Color3.fromRGB(255, 255, 255),
	SidebarTransparency = 0.94,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.9,
	SurfaceHover = Color3.fromRGB(255, 255, 255),
	SurfaceHoverTransparency = 0.82,
	Inset = Color3.fromRGB(255, 255, 255),
	InsetTransparency = 0.93,
	Track = Color3.fromRGB(255, 255, 255),
	TrackTransparency = 0.8,
	Popup = Color3.fromRGB(16, 19, 26),
	PopupTransparency = 0.15,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.76,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(216, 222, 232),
	TextFaint = Color3.fromRGB(156, 164, 178),
	OnAccent = Color3.fromRGB(10, 14, 24),

	Accent = Color3.fromRGB(132, 172, 255),
	AccentB = Color3.fromRGB(190, 132, 255),
	Success = Color3.fromRGB(120, 235, 170),
	Warning = Color3.fromRGB(255, 205, 130),
	Danger = Color3.fromRGB(255, 120, 140),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(255, 120, 140),
	DotMinimize = Color3.fromRGB(255, 205, 130),
	DotZoom = Color3.fromRGB(120, 235, 170),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(132, 172, 255),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(10, 14, 24),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Corner = 16,
	SmallCorner = 10,
	StrokeWidth = 1,
	RowHeight = 46,
	Pad = 16,
	Gap = 9,
	SidebarWidth = 150,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 15,

	Gloss = 0.2,
	Blur = 30,
	Shadow = 0.65,

	Duration = 0.26,
	Easing = Enum.EasingStyle.Quint,
}

Themes.Poly = {
	Name = "Poly",
	Light = false,

	Window = Color3.fromRGB(22, 25, 32),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(19, 22, 28),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(30, 34, 42),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(38, 43, 53),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(25, 29, 36),
	InsetTransparency = 0,
	Track = Color3.fromRGB(44, 50, 62),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(26, 30, 38),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(54, 60, 74),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(228, 232, 238),
	TextDim = Color3.fromRGB(150, 158, 172),
	TextFaint = Color3.fromRGB(96, 104, 120),
	OnAccent = Color3.fromRGB(8, 22, 20),

	Accent = Color3.fromRGB(0, 194, 168),
	AccentB = Color3.fromRGB(0, 163, 194),
	Success = Color3.fromRGB(74, 222, 128),
	Warning = Color3.fromRGB(255, 184, 92),
	Danger = Color3.fromRGB(255, 104, 104),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(255, 104, 104),
	DotMinimize = Color3.fromRGB(255, 184, 92),
	DotZoom = Color3.fromRGB(74, 222, 128),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(0, 194, 168),
	SwitchKnob = Color3.fromRGB(228, 232, 238),
	SwitchKnobOn = Color3.fromRGB(8, 22, 20),
	SliderKnob = Color3.fromRGB(228, 232, 238),

	Corner = 3,
	SmallCorner = 2,
	StrokeWidth = 1,
	RowHeight = 42,
	Pad = 12,
	Gap = 7,
	SidebarWidth = 144,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0.05,
	Blur = 0,
	Shadow = 0.35,

	Duration = 0.12,
	Easing = Enum.EasingStyle.Quad,
}

Themes.Pro = {
	Name = "Pro",
	Light = false,

	Window = Color3.fromRGB(24, 26, 31),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(21, 23, 28),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(32, 35, 42),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(40, 44, 53),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(27, 29, 35),
	InsetTransparency = 0,
	Track = Color3.fromRGB(46, 51, 62),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(28, 31, 38),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(48, 53, 64),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(233, 235, 238),
	TextDim = Color3.fromRGB(158, 164, 174),
	TextFaint = Color3.fromRGB(106, 113, 126),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(59, 130, 246),
	AccentB = Color3.fromRGB(37, 99, 235),
	Success = Color3.fromRGB(34, 197, 94),
	Warning = Color3.fromRGB(245, 158, 11),
	Danger = Color3.fromRGB(239, 68, 68),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(239, 68, 68),
	DotMinimize = Color3.fromRGB(245, 158, 11),
	DotZoom = Color3.fromRGB(34, 197, 94),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(59, 130, 246),
	SwitchKnob = Color3.fromRGB(233, 235, 238),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(233, 235, 238),

	Corner = 6,
	SmallCorner = 4,
	StrokeWidth = 1,
	RowHeight = 42,
	Pad = 12,
	Gap = 7,
	SidebarWidth = 146,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.45,

	Duration = 0.15,
	Easing = Enum.EasingStyle.Quad,
}

Themes.Goofy = {
	Name = "Goofy",
	Light = true,

	Window = Color3.fromRGB(255, 246, 250),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(255, 232, 242),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(255, 224, 238),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(255, 240, 246),
	InsetTransparency = 0,
	Track = Color3.fromRGB(255, 219, 235),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(255, 255, 255),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(255, 150, 196),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(58, 40, 74),
	TextDim = Color3.fromRGB(124, 106, 140),
	TextFaint = Color3.fromRGB(172, 158, 186),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(255, 79, 163),
	AccentB = Color3.fromRGB(255, 196, 61),
	Success = Color3.fromRGB(52, 199, 123),
	Warning = Color3.fromRGB(255, 159, 60),
	Danger = Color3.fromRGB(255, 84, 116),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(255, 84, 116),
	DotMinimize = Color3.fromRGB(255, 159, 60),
	DotZoom = Color3.fromRGB(52, 199, 123),
	Round = true,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(255, 79, 163),
	SwitchKnob = Color3.fromRGB(58, 40, 74),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(58, 40, 74),

	Corner = 22,
	SmallCorner = 14,
	StrokeWidth = 2,
	RowHeight = 48,
	Pad = 16,
	Gap = 10,
	SidebarWidth = 152,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansBold,
	BoldFont = Enum.Font.BuilderSansExtraBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 16,

	Gloss = 0.1,
	Blur = 0,
	Shadow = 0.35,

	Duration = 0.32,
	Easing = Enum.EasingStyle.Back,
}

Themes.Clean = {
	Name = "Clean",
	Light = true,

	Window = Color3.fromRGB(255, 255, 255),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(249, 250, 252),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(243, 245, 249),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(246, 247, 250),
	InsetTransparency = 0,
	Track = Color3.fromRGB(232, 236, 242),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(255, 255, 255),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(227, 231, 237),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(17, 20, 26),
	TextDim = Color3.fromRGB(90, 97, 108),
	TextFaint = Color3.fromRGB(152, 159, 170),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(37, 99, 235),
	AccentB = Color3.fromRGB(59, 130, 246),
	Success = Color3.fromRGB(22, 163, 74),
	Warning = Color3.fromRGB(217, 119, 6),
	Danger = Color3.fromRGB(220, 38, 38),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(220, 38, 38),
	DotMinimize = Color3.fromRGB(217, 119, 6),
	DotZoom = Color3.fromRGB(22, 163, 74),
	Round = false,
	Indicator = 3,
	EntryAccent = false,
	Gradient = true,
	SwitchOn = Color3.fromRGB(37, 99, 235),
	SwitchKnob = Color3.fromRGB(17, 20, 26),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(17, 20, 26),

	Corner = 10,
	SmallCorner = 7,
	StrokeWidth = 1,
	RowHeight = 44,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 148,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.28,

	Duration = 0.16,
	Easing = Enum.EasingStyle.Quad,
}

for name, preset in Styles do
	Themes[name] = preset
end

--- Presets are found case- and space-insensitively, so "macOS Dark", "macos
--- dark" and "MACOSDARK" all land on the same style.
local function normalize(name: string): string
	return (string.lower(name):gsub("[%s_%-]", ""))
end

local BY_KEY: { [string]: Theme } = {}
for name, theme in Themes do
	BY_KEY[normalize(name)] = theme
end

local Theme = {
	Themes = Themes,
	Default = "Nice",
}

function Theme.get(name: string?): Theme
	local found = if name then Themes[name] or BY_KEY[normalize(name)] else nil
	found = found or Themes[Theme.Default]
	if not found then
		error(`[Loom] no theme named "{name}"`, 2)
	end
	return found
end

--- Registered theme names, sorted. Handy for building a picker.
function Theme.names(): { string }
	local list = {}
	for name in Themes do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

--- Register a variant: Theme.extend("Nice", { Name = "Blood", Accent = Color3.new(1, 0, 0) })
function Theme.extend(base: string, patch: { [string]: any }): Theme
	local merged = table.clone(Theme.get(base))
	for key, value in patch do
		(merged :: any)[key] = value
	end
	Themes[merged.Name] = merged
	BY_KEY[normalize(merged.Name)] = merged
	return merged
end

return Theme
