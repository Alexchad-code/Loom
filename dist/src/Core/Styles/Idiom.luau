--!strict
-- Non-desktop idioms: soft UI, brutalist, vaporwave, classic desktop, pixel
-- game, Minecraft, and Discord. Each is a patch over one of the structural
-- bases in Base.luau.

local Token = require("@self/../Token")
local Base = require("@self/Base")

type Theme = Token.Theme

local Idiom: { [string]: Theme } = {}

--- The soft base is already this style's structure, so only the palette and the
--- depth that sells the effect differ.
Idiom.Neumorph = Base.style(Base.Soft, {
	Sidebar = Color3.fromRGB(221, 227, 234),
	Inset = Color3.fromRGB(216, 223, 232),
	SurfaceHover = Color3.fromRGB(214, 220, 229),
	Gloss = 0.12,
	Shadow = 0.95,
})

Idiom["Neumorph Dark"] = Base.style(Base.Soft, {
	Light = false,

	Window = Color3.fromRGB(36, 39, 46),
	Sidebar = Color3.fromRGB(33, 36, 42),
	Surface = Color3.fromRGB(36, 39, 46),
	SurfaceHover = Color3.fromRGB(42, 46, 54),
	Inset = Color3.fromRGB(30, 33, 39),
	Track = Color3.fromRGB(46, 50, 58),
	Popup = Color3.fromRGB(36, 39, 46),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.94,

	Text = Color3.fromRGB(227, 231, 238),
	TextDim = Color3.fromRGB(166, 174, 190),
	TextFaint = Color3.fromRGB(115, 124, 140),
	OnAccent = Color3.fromRGB(18, 20, 26),

	Accent = Color3.fromRGB(122, 162, 247),
	AccentB = Color3.fromRGB(155, 184, 255),
	SwitchOn = Color3.fromRGB(122, 162, 247),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),

	Gloss = 0.12,
	Shadow = 0.95,
})

Idiom.Brutalist = Base.style(Base.Flat, {
	Window = Color3.fromRGB(0, 0, 0),
	Sidebar = Color3.fromRGB(17, 17, 17),
	Surface = Color3.fromRGB(0, 0, 0),
	SurfaceHover = Color3.fromRGB(26, 26, 26),
	Inset = Color3.fromRGB(10, 10, 10),
	Track = Color3.fromRGB(38, 38, 38),
	Popup = Color3.fromRGB(0, 0, 0),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0,
	StrokeWidth = 3,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(191, 191, 191),
	TextFaint = Color3.fromRGB(128, 128, 128),
	OnAccent = Color3.fromRGB(0, 0, 0),

	Accent = Color3.fromRGB(255, 230, 0),
	AccentB = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(0, 230, 118),
	Warning = Color3.fromRGB(255, 179, 0),
	Danger = Color3.fromRGB(255, 23, 68),

	Indicator = 4,
	EntryAccent = true,
	RowHeight = 46,
	Pad = 14,
	Gap = 10,
	SidebarWidth = 150,

	Font = Enum.Font.BuilderSansExtraBold,
	MediumFont = Enum.Font.BuilderSansExtraBold,
	BoldFont = Enum.Font.BuilderSansExtraBold,
	FontSize = 15,
	SmallFontSize = 13,
	TitleFontSize = 16,

	SwitchOn = Color3.fromRGB(255, 230, 0),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(0, 0, 0),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.04,
})

Idiom.Vaporwave = Base.style(Base.Glass, {
	Chrome = "caption",
	Round = true,
	EntryAccent = true,

	Window = Color3.fromRGB(43, 16, 85),
	WindowTransparency = 0.12,
	Sidebar = Color3.fromRGB(59, 31, 110),
	SidebarTransparency = 0.35,
	Surface = Color3.fromRGB(74, 44, 130),
	SurfaceTransparency = 0.45,
	SurfaceHover = Color3.fromRGB(90, 56, 160),
	SurfaceHoverTransparency = 0.4,
	Inset = Color3.fromRGB(31, 11, 61),
	InsetTransparency = 0.35,
	Track = Color3.fromRGB(106, 74, 168),
	TrackTransparency = 0.4,
	Popup = Color3.fromRGB(43, 16, 85),
	PopupTransparency = 0.08,
	Stroke = Color3.fromRGB(148, 208, 255),
	StrokeTransparency = 0.6,

	Text = Color3.fromRGB(253, 242, 255),
	TextDim = Color3.fromRGB(214, 188, 245),
	TextFaint = Color3.fromRGB(169, 139, 214),
	OnAccent = Color3.fromRGB(43, 16, 85),

	Accent = Color3.fromRGB(255, 106, 213),
	AccentB = Color3.fromRGB(148, 208, 255),
	Success = Color3.fromRGB(123, 224, 173),
	Warning = Color3.fromRGB(255, 209, 102),
	Danger = Color3.fromRGB(255, 92, 138),

	Corner = 20,
	Gloss = 0.3,
	Blur = 18,
	Shadow = 0.7,
	RowHeight = 46,
	SidebarWidth = 160,

	Font = Enum.Font.JosefinSans,
	MediumFont = Enum.Font.JosefinSans,
	BoldFont = Enum.Font.Michroma,
	TitleFontSize = 16,

	SwitchOn = Color3.fromRGB(255, 106, 213),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(43, 16, 85),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.3,
	Easing = Enum.EasingStyle.Back,
})

--- A filled selection is what the original tab strip did, so the accent does
--- that job here rather than the indicator bar.
Idiom.Retro = Base.style(Base.Flat, {
	Light = true,
	Indicator = 0,
	EntryAccent = true,

	Window = Color3.fromRGB(192, 192, 192),
	Sidebar = Color3.fromRGB(192, 192, 192),
	Surface = Color3.fromRGB(192, 192, 192),
	SurfaceHover = Color3.fromRGB(212, 208, 200),
	Inset = Color3.fromRGB(255, 255, 255),
	Track = Color3.fromRGB(128, 128, 128),
	Popup = Color3.fromRGB(192, 192, 192),
	Stroke = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(0, 0, 0),
	TextDim = Color3.fromRGB(64, 64, 64),
	TextFaint = Color3.fromRGB(128, 128, 128),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(0, 0, 128),
	AccentB = Color3.fromRGB(16, 132, 208),
	Success = Color3.fromRGB(0, 128, 0),
	Warning = Color3.fromRGB(128, 128, 0),
	Danger = Color3.fromRGB(128, 0, 0),

	RowHeight = 28,
	Pad = 8,
	Gap = 4,
	SidebarWidth = 140,

	Font = Enum.Font.Arial,
	MediumFont = Enum.Font.Arial,
	BoldFont = Enum.Font.ArialBold,
	FontSize = 12,
	SmallFontSize = 11,
	TitleFontSize = 12,

	SwitchOn = Color3.fromRGB(0, 0, 128),
	SwitchKnob = Color3.fromRGB(192, 192, 192),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(192, 192, 192),

	Duration = 0.02,
})

--- An arcade cabinet HUD: navy field, gold accents, hard 2px edges.
Idiom.Pixel = Base.style(Base.Flat, {
	TitleAlign = Enum.TextXAlignment.Center,
	Indicator = 4,
	EntryAccent = true,
	Gradient = true,

	Window = Color3.fromRGB(27, 27, 47),
	Sidebar = Color3.fromRGB(22, 22, 43),
	Surface = Color3.fromRGB(35, 35, 63),
	SurfaceHover = Color3.fromRGB(44, 44, 78),
	Inset = Color3.fromRGB(20, 20, 40),
	Track = Color3.fromRGB(51, 51, 92),
	Popup = Color3.fromRGB(35, 35, 63),
	Stroke = Color3.fromRGB(64, 64, 107),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(234, 240, 255),
	TextDim = Color3.fromRGB(169, 180, 216),
	TextFaint = Color3.fromRGB(112, 121, 168),
	OnAccent = Color3.fromRGB(20, 20, 43),

	Accent = Color3.fromRGB(255, 217, 61),
	AccentB = Color3.fromRGB(255, 140, 66),
	Success = Color3.fromRGB(94, 214, 122),
	Warning = Color3.fromRGB(255, 201, 60),
	Danger = Color3.fromRGB(255, 92, 122),

	Shadow = 0.35,
	SwitchOn = Color3.fromRGB(255, 217, 61),
	SwitchKnob = Color3.fromRGB(234, 240, 255),
	SwitchKnobOn = Color3.fromRGB(20, 20, 43),
	SliderKnob = Color3.fromRGB(255, 217, 61),

	TitleFontSize = 15,
	Duration = 0.05,
})

--- The inventory GUI: stone panels, dark bevels, grass green and gold.
Idiom.Minecraft = Base.style(Base.Flat, {
	Light = true,
	Indicator = 4,
	EntryAccent = true,

	Window = Color3.fromRGB(198, 198, 198),
	Sidebar = Color3.fromRGB(198, 198, 198),
	Surface = Color3.fromRGB(198, 198, 198),
	SurfaceHover = Color3.fromRGB(212, 212, 212),
	Inset = Color3.fromRGB(139, 139, 139),
	Track = Color3.fromRGB(139, 139, 139),
	Popup = Color3.fromRGB(198, 198, 198),
	Stroke = Color3.fromRGB(63, 63, 63),
	StrokeTransparency = 0,

	Text = Color3.fromRGB(63, 63, 63),
	TextDim = Color3.fromRGB(91, 91, 91),
	TextFaint = Color3.fromRGB(122, 122, 122),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(91, 135, 49),
	AccentB = Color3.fromRGB(124, 179, 66),
	Success = Color3.fromRGB(106, 168, 79),
	Warning = Color3.fromRGB(252, 238, 75),
	Danger = Color3.fromRGB(176, 46, 38),

	RowHeight = 36,
	Pad = 10,
	SidebarWidth = 150,

	Font = Enum.Font.Arcade,
	MediumFont = Enum.Font.Arcade,
	BoldFont = Enum.Font.Arcade,
	TitleFontSize = 15,

	Gloss = 0.06,
	SwitchOn = Color3.fromRGB(91, 135, 49),
	SwitchKnob = Color3.fromRGB(198, 198, 198),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(224, 224, 224),

	Duration = 0.04,
})

Idiom.Discord = Base.style(Base.Desktop, {
	Gradient = false,

	Window = Color3.fromRGB(49, 51, 56),
	Sidebar = Color3.fromRGB(43, 45, 49),
	Surface = Color3.fromRGB(56, 58, 64),
	SurfaceHover = Color3.fromRGB(64, 66, 73),
	Inset = Color3.fromRGB(30, 31, 34),
	Track = Color3.fromRGB(78, 80, 88),
	Popup = Color3.fromRGB(43, 45, 49),
	Stroke = Color3.fromRGB(30, 31, 34),
	StrokeTransparency = 0.35,

	Text = Color3.fromRGB(242, 243, 245),
	TextDim = Color3.fromRGB(181, 186, 193),
	TextFaint = Color3.fromRGB(148, 155, 164),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(88, 101, 242),
	AccentB = Color3.fromRGB(71, 82, 196),
	Success = Color3.fromRGB(35, 165, 90),
	Warning = Color3.fromRGB(240, 178, 50),
	Danger = Color3.fromRGB(218, 55, 60),

	Corner = 8,
	SmallCorner = 5,
	RowHeight = 44,
	SidebarWidth = 176,

	Font = Enum.Font.Arimo,
	MediumFont = Enum.Font.ArimoBold,
	BoldFont = Enum.Font.ArimoBold,
	FontSize = 15,
	TitleFontSize = 15,

	Gloss = 0,
	Shadow = 0.5,
	SwitchOn = Color3.fromRGB(35, 165, 90),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.14,
})

Idiom["Discord Light"] = Base.style(Base.Desktop, {
	Light = true,
	Gradient = false,

	Window = Color3.fromRGB(255, 255, 255),
	Sidebar = Color3.fromRGB(242, 243, 245),
	Surface = Color3.fromRGB(235, 237, 239),
	SurfaceHover = Color3.fromRGB(223, 225, 229),
	Inset = Color3.fromRGB(227, 229, 232),
	Track = Color3.fromRGB(212, 215, 220),
	Popup = Color3.fromRGB(255, 255, 255),
	Stroke = Color3.fromRGB(227, 229, 232),
	StrokeTransparency = 0.1,

	Text = Color3.fromRGB(6, 6, 7),
	TextDim = Color3.fromRGB(78, 80, 88),
	TextFaint = Color3.fromRGB(128, 132, 142),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(88, 101, 242),
	AccentB = Color3.fromRGB(71, 82, 196),
	Success = Color3.fromRGB(36, 128, 70),
	Warning = Color3.fromRGB(169, 119, 11),
	Danger = Color3.fromRGB(218, 55, 60),

	Corner = 8,
	SmallCorner = 5,
	RowHeight = 44,
	SidebarWidth = 176,

	Font = Enum.Font.Arimo,
	MediumFont = Enum.Font.ArimoBold,
	BoldFont = Enum.Font.ArimoBold,
	FontSize = 15,
	TitleFontSize = 15,

	Gloss = 0,
	Shadow = 0.5,
	SwitchOn = Color3.fromRGB(35, 165, 90),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.14,
})

return Idiom
