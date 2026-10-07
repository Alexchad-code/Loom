--!strict
-- Structural bases for the style presets. A style is a complete token table, so
-- anything that differs from one of these in colour only stays a short patch --
-- but every patch is checked, because a mistyped token name would otherwise
-- leave the base's value on screen and look almost right.

local Token = require("@self/../Token")

type Theme = Token.Theme

export type Base = {
	Glass: Theme,
	Desktop: Theme,
	Flat: Theme,
	Soft: Theme,
	style: (base: Theme, patch: { [string]: any }) -> Theme,
}

local Base = {} :: Base

--- Vibrant translucent panel: heavy backdrop blur, generous radii, the title
--- centred and macOS window dots. The Apple styles and vaporwave start here.
Base.Glass = {
	Name = "Base: Glass",
	Light = false,

	Window = Color3.fromRGB(16, 19, 24),
	WindowTransparency = 0.15,
	Sidebar = Color3.fromRGB(255, 255, 255),
	SidebarTransparency = 0.9,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.88,
	SurfaceHover = Color3.fromRGB(255, 255, 255),
	SurfaceHoverTransparency = 0.8,
	Inset = Color3.fromRGB(255, 255, 255),
	InsetTransparency = 0.92,
	Track = Color3.fromRGB(255, 255, 255),
	TrackTransparency = 0.72,
	Popup = Color3.fromRGB(18, 21, 27),
	PopupTransparency = 0.1,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.8,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(216, 222, 232),
	TextFaint = Color3.fromRGB(156, 164, 178),
	OnAccent = Color3.fromRGB(10, 14, 24),

	Accent = Color3.fromRGB(132, 172, 255),
	AccentB = Color3.fromRGB(190, 132, 255),
	Success = Color3.fromRGB(120, 235, 170),
	Warning = Color3.fromRGB(255, 205, 130),
	Danger = Color3.fromRGB(255, 120, 140),

	Chrome = "traffic",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 95, 87),
	DotMinimize = Color3.fromRGB(254, 188, 46),
	DotZoom = Color3.fromRGB(40, 200, 64),

	Corner = 18,
	SmallCorner = 12,
	Round = false,
	StrokeWidth = 1,
	Indicator = 0,
	EntryAccent = false,

	RowHeight = 48,
	Pad = 16,
	Gap = 10,
	SidebarWidth = 156,

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
	Gradient = true,
	SwitchOn = Color3.fromRGB(132, 172, 255),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.26,
	Easing = Enum.EasingStyle.Quint,
}

--- Opaque desktop application window: caption buttons on the right, tight
--- radii, dense rows, a left-aligned title. Windows, GNOME and the palette
--- styles are patches over this.
Base.Desktop = {
	Name = "Base: Desktop",
	Light = false,

	Window = Color3.fromRGB(27, 29, 34),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(23, 25, 30),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(34, 37, 43),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(42, 46, 54),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(31, 34, 40),
	InsetTransparency = 0,
	Track = Color3.fromRGB(46, 50, 58),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(32, 35, 42),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(58, 63, 73),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(232, 234, 238),
	TextDim = Color3.fromRGB(155, 163, 176),
	TextFaint = Color3.fromRGB(108, 116, 128),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(76, 141, 255),
	AccentB = Color3.fromRGB(124, 107, 255),
	Success = Color3.fromRGB(63, 185, 80),
	Warning = Color3.fromRGB(210, 153, 34),
	Danger = Color3.fromRGB(248, 81, 73),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(248, 81, 73),
	DotMinimize = Color3.fromRGB(210, 153, 34),
	DotZoom = Color3.fromRGB(63, 185, 80),

	Corner = 10,
	SmallCorner = 6,
	Round = false,
	StrokeWidth = 1,
	Indicator = 3,
	EntryAccent = false,

	RowHeight = 42,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 152,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0.06,
	Blur = 0,
	Shadow = 0.45,
	Gradient = true,
	SwitchOn = Color3.fromRGB(76, 141, 255),
	SwitchKnob = Color3.fromRGB(232, 234, 238),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.16,
	Easing = Enum.EasingStyle.Quad,
}

--- Hard-edged terminal: square corners, thick rules, monospaced type, no
--- effects at all. Terminal, brutalist, pixel and retro styles start here.
Base.Flat = {
	Name = "Base: Flat",
	Light = false,

	Window = Color3.fromRGB(10, 10, 10),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(10, 10, 10),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(18, 18, 18),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(28, 28, 28),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(15, 15, 15),
	InsetTransparency = 0,
	Track = Color3.fromRGB(38, 38, 38),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(18, 18, 18),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(46, 46, 46),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(230, 230, 230),
	TextDim = Color3.fromRGB(160, 160, 160),
	TextFaint = Color3.fromRGB(110, 110, 110),
	OnAccent = Color3.fromRGB(0, 0, 0),

	Accent = Color3.fromRGB(230, 230, 230),
	AccentB = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(80, 220, 120),
	Warning = Color3.fromRGB(230, 180, 60),
	Danger = Color3.fromRGB(240, 90, 90),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(240, 90, 90),
	DotMinimize = Color3.fromRGB(230, 180, 60),
	DotZoom = Color3.fromRGB(80, 220, 120),

	Corner = 0,
	SmallCorner = 0,
	Round = false,
	StrokeWidth = 2,
	Indicator = 3,
	EntryAccent = false,

	RowHeight = 40,
	Pad = 12,
	Gap = 6,
	SidebarWidth = 148,

	Font = Enum.Font.Code,
	MediumFont = Enum.Font.Code,
	BoldFont = Enum.Font.Code,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 0,
	Shadow = 0,
	Gradient = false,
	SwitchOn = Color3.fromRGB(230, 230, 230),
	SwitchKnob = Color3.fromRGB(230, 230, 230),
	SwitchKnobOn = Color3.fromRGB(0, 0, 0),
	SliderKnob = Color3.fromRGB(230, 230, 230),

	Duration = 0.06,
	Easing = Enum.EasingStyle.Linear,
}

--- Soft UI: the surface is the window it sits on, edges are hairline highlights
--- rather than borders, and the depth comes from a wide dark shadow. Control
--- wells have to be filled by the style that uses this, since there is no
--- border to read a control by.
Base.Soft = {
	Name = "Base: Soft",
	Light = true,

	Window = Color3.fromRGB(224, 229, 236),
	WindowTransparency = 0,
	Sidebar = Color3.fromRGB(224, 229, 236),
	SidebarTransparency = 0,
	Surface = Color3.fromRGB(224, 229, 236),
	SurfaceTransparency = 0,
	SurfaceHover = Color3.fromRGB(214, 220, 228),
	SurfaceHoverTransparency = 0,
	Inset = Color3.fromRGB(216, 222, 230),
	InsetTransparency = 0,
	Track = Color3.fromRGB(203, 210, 220),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(224, 229, 236),
	PopupTransparency = 0,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.55,

	Text = Color3.fromRGB(74, 85, 104),
	TextDim = Color3.fromRGB(123, 135, 148),
	TextFaint = Color3.fromRGB(163, 173, 185),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(91, 141, 239),
	AccentB = Color3.fromRGB(123, 164, 255),
	Success = Color3.fromRGB(76, 175, 125),
	Warning = Color3.fromRGB(224, 163, 62),
	Danger = Color3.fromRGB(224, 87, 91),

	Chrome = "caption",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(224, 87, 91),
	DotMinimize = Color3.fromRGB(224, 163, 62),
	DotZoom = Color3.fromRGB(76, 175, 125),

	Corner = 18,
	SmallCorner = 14,
	Round = false,
	StrokeWidth = 1,
	Indicator = 0,
	EntryAccent = false,

	RowHeight = 48,
	Pad = 18,
	Gap = 12,
	SidebarWidth = 158,

	Font = Enum.Font.BuilderSans,
	MediumFont = Enum.Font.BuilderSansMedium,
	BoldFont = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.Code,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 15,

	Gloss = 0.1,
	Blur = 0,
	Shadow = 0.9,
	Gradient = true,
	SwitchOn = Color3.fromRGB(91, 141, 239),
	SwitchKnob = Color3.fromRGB(247, 250, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(247, 250, 255),

	Duration = 0.3,
	Easing = Enum.EasingStyle.Quad,
}

--- Every token name, so a preset cannot invent one.
local TOKENS: { [string]: any } = Base.Desktop
local VALID: { [string]: boolean } = {}
for key in TOKENS do
	VALID[key] = true
end

--- Applies a patch over a base. An unknown key is a typo rather than a new
--- token, and it would silently leave the base's value on screen, so it throws
--- here where the smoke run catches it instead of surviving to the screen.
function Base.style(base: Theme, patch: { [string]: any }): Theme
	local merged: Theme = table.clone(base)
	for key, value in patch do
		if not VALID[key] then
			error(`[Loom] "{key}" is not a theme token`, 3)
		end
		(merged :: any)[key] = value
	end
	return merged
end

return Base
