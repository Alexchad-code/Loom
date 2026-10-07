--!strict
-- The operating-system styles: iOS, macOS, Windows 11, GNOME Adwaita and
-- Material You, each in a light and a dark variant.

local Token = require("@self/../Token")
local Base = require("@self/Base")

type Theme = Token.Theme

local Os: { [string]: Theme } = {}

Os.iOS = Base.style(Base.Glass, {
	Light = true,

	Window = Color3.fromRGB(255, 255, 255),
	WindowTransparency = 0.1,
	Sidebar = Color3.fromRGB(242, 242, 247),
	SidebarTransparency = 0.35,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.5,
	SurfaceHover = Color3.fromRGB(255, 255, 255),
	SurfaceHoverTransparency = 0.35,
	Inset = Color3.fromRGB(118, 118, 128),
	InsetTransparency = 0.88,
	Track = Color3.fromRGB(233, 233, 234),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(255, 255, 255),
	PopupTransparency = 0.06,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.7,

	Text = Color3.fromRGB(0, 0, 0),
	TextDim = Color3.fromRGB(142, 142, 147),
	TextFaint = Color3.fromRGB(199, 199, 204),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(10, 132, 255),
	AccentB = Color3.fromRGB(100, 210, 255),
	Success = Color3.fromRGB(52, 199, 89),
	Warning = Color3.fromRGB(255, 159, 10),
	Danger = Color3.fromRGB(255, 59, 48),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 59, 48),
	DotMinimize = Color3.fromRGB(255, 159, 10),
	DotZoom = Color3.fromRGB(52, 199, 89),

	Corner = 20,
	SmallCorner = 12,
	Round = true,
	Indicator = 0,
	EntryAccent = false,

	RowHeight = 52,
	Pad = 16,
	Gap = 10,
	SidebarWidth = 158,

	Font = Enum.Font.Gotham,
	MediumFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,
	FontSize = 15,
	SmallFontSize = 13,
	TitleFontSize = 15,

	Gloss = 0.12,
	Blur = 30,
	Shadow = 0.3,
	Gradient = false,
	SwitchOn = Color3.fromRGB(52, 199, 89),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.22,
	Easing = Enum.EasingStyle.Quint,
})

Os["iOS Dark"] = Base.style(Base.Glass, {
	Light = false,

	Window = Color3.fromRGB(28, 28, 30),
	WindowTransparency = 0.1,
	Sidebar = Color3.fromRGB(44, 44, 46),
	SidebarTransparency = 0.3,
	Surface = Color3.fromRGB(44, 44, 46),
	SurfaceTransparency = 0.4,
	SurfaceHover = Color3.fromRGB(58, 58, 60),
	SurfaceHoverTransparency = 0.3,
	Inset = Color3.fromRGB(118, 118, 128),
	InsetTransparency = 0.68,
	Track = Color3.fromRGB(57, 57, 61),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(44, 44, 46),
	PopupTransparency = 0.05,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.85,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(152, 152, 159),
	TextFaint = Color3.fromRGB(90, 90, 94),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(10, 132, 255),
	AccentB = Color3.fromRGB(100, 210, 255),
	Success = Color3.fromRGB(48, 209, 88),
	Warning = Color3.fromRGB(255, 159, 10),
	Danger = Color3.fromRGB(255, 69, 58),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 69, 58),
	DotMinimize = Color3.fromRGB(255, 159, 10),
	DotZoom = Color3.fromRGB(48, 209, 88),

	Corner = 20,
	SmallCorner = 12,
	Round = true,
	Indicator = 0,
	EntryAccent = false,

	RowHeight = 52,
	Pad = 16,
	Gap = 10,
	SidebarWidth = 158,

	Font = Enum.Font.Gotham,
	MediumFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,
	FontSize = 15,
	SmallFontSize = 13,
	TitleFontSize = 15,

	Gloss = 0.12,
	Blur = 30,
	Shadow = 0.3,
	Gradient = false,
	SwitchOn = Color3.fromRGB(48, 209, 88),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.22,
	Easing = Enum.EasingStyle.Quint,
})

Os.macOS = Base.style(Base.Glass, {
	Light = true,

	Window = Color3.fromRGB(242, 242, 247),
	WindowTransparency = 0.15,
	Sidebar = Color3.fromRGB(233, 233, 236),
	SidebarTransparency = 0.25,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.55,
	SurfaceHover = Color3.fromRGB(255, 255, 255),
	SurfaceHoverTransparency = 0.4,
	Inset = Color3.fromRGB(255, 255, 255),
	InsetTransparency = 0.45,
	Track = Color3.fromRGB(217, 217, 222),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(255, 255, 255),
	PopupTransparency = 0.05,
	Stroke = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0.9,

	Text = Color3.fromRGB(29, 29, 31),
	TextDim = Color3.fromRGB(110, 110, 115),
	TextFaint = Color3.fromRGB(174, 174, 178),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(0, 122, 255),
	AccentB = Color3.fromRGB(10, 132, 255),
	Success = Color3.fromRGB(52, 199, 89),
	Warning = Color3.fromRGB(255, 204, 0),
	Danger = Color3.fromRGB(255, 59, 48),

	Chrome = "traffic",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 95, 87),
	DotMinimize = Color3.fromRGB(254, 188, 46),
	DotZoom = Color3.fromRGB(40, 200, 64),

	Corner = 12,
	SmallCorner = 6,
	Indicator = 0,
	EntryAccent = true,

	RowHeight = 38,
	Pad = 14,
	Gap = 7,
	SidebarWidth = 165,

	Font = Enum.Font.Gotham,
	MediumFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,
	FontSize = 13,
	SmallFontSize = 11,
	TitleFontSize = 13,

	Gloss = 0.16,
	Blur = 40,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(10, 132, 255),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.2,
	Easing = Enum.EasingStyle.Quint,
})

Os["macOS Dark"] = Base.style(Base.Glass, {
	Light = false,

	Window = Color3.fromRGB(35, 35, 38),
	WindowTransparency = 0.2,
	Sidebar = Color3.fromRGB(42, 42, 44),
	SidebarTransparency = 0.2,
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceTransparency = 0.9,
	SurfaceHover = Color3.fromRGB(255, 255, 255),
	SurfaceHoverTransparency = 0.84,
	Inset = Color3.fromRGB(0, 0, 0),
	InsetTransparency = 0.55,
	Track = Color3.fromRGB(72, 72, 74),
	TrackTransparency = 0,
	Popup = Color3.fromRGB(44, 44, 47),
	PopupTransparency = 0.05,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.88,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(152, 152, 157),
	TextFaint = Color3.fromRGB(110, 110, 115),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(10, 132, 255),
	AccentB = Color3.fromRGB(100, 210, 255),
	Success = Color3.fromRGB(48, 209, 88),
	Warning = Color3.fromRGB(255, 214, 10),
	Danger = Color3.fromRGB(255, 69, 58),

	Chrome = "traffic",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 95, 87),
	DotMinimize = Color3.fromRGB(254, 188, 46),
	DotZoom = Color3.fromRGB(40, 200, 64),

	Corner = 12,
	SmallCorner = 6,
	Indicator = 0,
	EntryAccent = true,

	RowHeight = 38,
	Pad = 14,
	Gap = 7,
	SidebarWidth = 165,

	Font = Enum.Font.Gotham,
	MediumFont = Enum.Font.GothamMedium,
	BoldFont = Enum.Font.GothamBold,
	FontSize = 13,
	SmallFontSize = 11,
	TitleFontSize = 13,

	Gloss = 0.16,
	Blur = 40,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(10, 132, 255),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.2,
	Easing = Enum.EasingStyle.Quint,
})

Os.Windows = Base.style(Base.Desktop, {
	Light = true,

	Window = Color3.fromRGB(243, 243, 243),
	Sidebar = Color3.fromRGB(234, 234, 234),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceHover = Color3.fromRGB(251, 251, 251),
	Inset = Color3.fromRGB(255, 255, 255),
	Track = Color3.fromRGB(176, 176, 176),
	Popup = Color3.fromRGB(249, 249, 249),
	Stroke = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0.9,

	Text = Color3.fromRGB(26, 26, 26),
	TextDim = Color3.fromRGB(93, 93, 93),
	TextFaint = Color3.fromRGB(138, 138, 138),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(0, 103, 192),
	AccentB = Color3.fromRGB(0, 120, 212),
	Success = Color3.fromRGB(15, 123, 15),
	Warning = Color3.fromRGB(157, 93, 0),
	Danger = Color3.fromRGB(196, 43, 28),

	DotClose = Color3.fromRGB(196, 43, 28),
	DotMinimize = Color3.fromRGB(247, 177, 0),
	DotZoom = Color3.fromRGB(15, 123, 15),

	Corner = 8,
	SmallCorner = 4,

	RowHeight = 44,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 156,

	Font = Enum.Font.SourceSans,
	MediumFont = Enum.Font.SourceSansSemibold,
	BoldFont = Enum.Font.SourceSansBold,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 20,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(0, 103, 192),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.16,
	Easing = Enum.EasingStyle.Quad,
})

Os["Windows Dark"] = Base.style(Base.Desktop, {
	Light = false,

	Window = Color3.fromRGB(32, 32, 32),
	Sidebar = Color3.fromRGB(31, 31, 31),
	Surface = Color3.fromRGB(43, 43, 43),
	SurfaceHover = Color3.fromRGB(50, 50, 50),
	Inset = Color3.fromRGB(45, 45, 45),
	Track = Color3.fromRGB(90, 90, 90),
	Popup = Color3.fromRGB(44, 44, 44),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.88,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(197, 197, 197),
	TextFaint = Color3.fromRGB(139, 139, 139),
	OnAccent = Color3.fromRGB(0, 38, 66),

	Accent = Color3.fromRGB(76, 194, 255),
	AccentB = Color3.fromRGB(96, 205, 255),
	Success = Color3.fromRGB(108, 203, 95),
	Warning = Color3.fromRGB(252, 225, 0),
	Danger = Color3.fromRGB(255, 153, 164),

	DotClose = Color3.fromRGB(196, 43, 28),
	DotMinimize = Color3.fromRGB(247, 177, 0),
	DotZoom = Color3.fromRGB(15, 123, 15),

	Corner = 8,
	SmallCorner = 4,

	RowHeight = 44,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 156,

	Font = Enum.Font.SourceSans,
	MediumFont = Enum.Font.SourceSansSemibold,
	BoldFont = Enum.Font.SourceSansBold,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 20,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(76, 194, 255),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.16,
	Easing = Enum.EasingStyle.Quad,
})

Os.Linux = Base.style(Base.Desktop, {
	Light = true,

	Window = Color3.fromRGB(250, 250, 250),
	Sidebar = Color3.fromRGB(235, 235, 235),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceHover = Color3.fromRGB(242, 242, 242),
	Inset = Color3.fromRGB(255, 255, 255),
	Track = Color3.fromRGB(189, 189, 189),
	Popup = Color3.fromRGB(255, 255, 255),
	Stroke = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0.85,

	Text = Color3.fromRGB(46, 52, 54),
	TextDim = Color3.fromRGB(94, 92, 100),
	TextFaint = Color3.fromRGB(154, 153, 150),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(53, 132, 228),
	AccentB = Color3.fromRGB(28, 113, 216),
	Success = Color3.fromRGB(46, 194, 126),
	Warning = Color3.fromRGB(245, 194, 17),
	Danger = Color3.fromRGB(224, 27, 36),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(224, 27, 36),
	DotMinimize = Color3.fromRGB(245, 194, 17),
	DotZoom = Color3.fromRGB(46, 194, 126),

	Corner = 12,
	SmallCorner = 9,
	Indicator = 0,

	RowHeight = 40,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 172,

	Font = Enum.Font.Ubuntu,
	MediumFont = Enum.Font.Ubuntu,
	BoldFont = Enum.Font.Ubuntu,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(53, 132, 228),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.2,
	Easing = Enum.EasingStyle.Cubic,
})

Os["Linux Dark"] = Base.style(Base.Desktop, {
	Light = false,

	Window = Color3.fromRGB(36, 36, 36),
	Sidebar = Color3.fromRGB(48, 48, 48),
	Surface = Color3.fromRGB(30, 30, 30),
	SurfaceHover = Color3.fromRGB(48, 48, 48),
	Inset = Color3.fromRGB(30, 30, 30),
	Track = Color3.fromRGB(87, 87, 87),
	Popup = Color3.fromRGB(36, 36, 36),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.9,

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(192, 191, 188),
	TextFaint = Color3.fromRGB(119, 118, 123),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(53, 132, 228),
	AccentB = Color3.fromRGB(98, 160, 234),
	Success = Color3.fromRGB(87, 227, 137),
	Warning = Color3.fromRGB(249, 240, 107),
	Danger = Color3.fromRGB(255, 123, 99),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Center,
	DotClose = Color3.fromRGB(255, 123, 99),
	DotMinimize = Color3.fromRGB(249, 240, 107),
	DotZoom = Color3.fromRGB(87, 227, 137),

	Corner = 12,
	SmallCorner = 9,
	Indicator = 0,

	RowHeight = 40,
	Pad = 14,
	Gap = 8,
	SidebarWidth = 172,

	Font = Enum.Font.Ubuntu,
	MediumFont = Enum.Font.Ubuntu,
	BoldFont = Enum.Font.Ubuntu,
	FontSize = 14,
	SmallFontSize = 12,
	TitleFontSize = 14,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.5,
	Gradient = false,
	SwitchOn = Color3.fromRGB(53, 132, 228),
	SwitchKnob = Color3.fromRGB(255, 255, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(255, 255, 255),

	Duration = 0.2,
	Easing = Enum.EasingStyle.Cubic,
})

Os.Android = Base.style(Base.Desktop, {
	Light = true,

	Window = Color3.fromRGB(255, 251, 254),
	Sidebar = Color3.fromRGB(243, 237, 247),
	Surface = Color3.fromRGB(247, 242, 250),
	SurfaceHover = Color3.fromRGB(236, 230, 240),
	Inset = Color3.fromRGB(243, 237, 247),
	Track = Color3.fromRGB(231, 224, 236),
	Popup = Color3.fromRGB(255, 251, 254),
	Stroke = Color3.fromRGB(121, 116, 126),
	StrokeTransparency = 0.5,

	Text = Color3.fromRGB(29, 27, 32),
	TextDim = Color3.fromRGB(73, 69, 79),
	TextFaint = Color3.fromRGB(121, 116, 126),
	OnAccent = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(103, 80, 164),
	AccentB = Color3.fromRGB(127, 103, 190),
	Success = Color3.fromRGB(76, 122, 56),
	Warning = Color3.fromRGB(178, 106, 0),
	Danger = Color3.fromRGB(179, 38, 30),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(179, 38, 30),
	DotMinimize = Color3.fromRGB(178, 106, 0),
	DotZoom = Color3.fromRGB(76, 122, 56),

	Corner = 24,
	SmallCorner = 16,
	Round = true,
	Indicator = 0,
	EntryAccent = true,

	RowHeight = 52,
	Pad = 18,
	Gap = 12,
	SidebarWidth = 168,

	Font = Enum.Font.Roboto,
	MediumFont = Enum.Font.Roboto,
	BoldFont = Enum.Font.Roboto,
	FontSize = 15,
	SmallFontSize = 12,
	TitleFontSize = 16,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.4,
	Gradient = false,
	SwitchOn = Color3.fromRGB(103, 80, 164),
	SwitchKnob = Color3.fromRGB(255, 251, 254),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
	SliderKnob = Color3.fromRGB(103, 80, 164),

	Duration = 0.24,
	Easing = Enum.EasingStyle.Quint,
})

Os["Android Dark"] = Base.style(Base.Desktop, {
	Light = false,

	Window = Color3.fromRGB(28, 27, 31),
	Sidebar = Color3.fromRGB(28, 27, 31),
	Surface = Color3.fromRGB(33, 31, 38),
	SurfaceHover = Color3.fromRGB(43, 41, 48),
	Inset = Color3.fromRGB(43, 41, 48),
	Track = Color3.fromRGB(73, 69, 79),
	Popup = Color3.fromRGB(33, 31, 38),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.88,

	Text = Color3.fromRGB(230, 225, 229),
	TextDim = Color3.fromRGB(202, 196, 208),
	TextFaint = Color3.fromRGB(147, 143, 153),
	OnAccent = Color3.fromRGB(56, 30, 114),

	Accent = Color3.fromRGB(208, 188, 255),
	AccentB = Color3.fromRGB(182, 157, 248),
	Success = Color3.fromRGB(122, 223, 160),
	Warning = Color3.fromRGB(247, 201, 120),
	Danger = Color3.fromRGB(255, 180, 171),

	Chrome = "close",
	TitleAlign = Enum.TextXAlignment.Left,
	DotClose = Color3.fromRGB(255, 180, 171),
	DotMinimize = Color3.fromRGB(247, 201, 120),
	DotZoom = Color3.fromRGB(122, 223, 160),

	Corner = 28,
	SmallCorner = 16,
	Round = true,
	Indicator = 0,
	EntryAccent = true,

	RowHeight = 52,
	Pad = 18,
	Gap = 12,
	SidebarWidth = 168,

	Font = Enum.Font.Roboto,
	MediumFont = Enum.Font.Roboto,
	BoldFont = Enum.Font.Roboto,
	FontSize = 15,
	SmallFontSize = 12,
	TitleFontSize = 16,

	Gloss = 0,
	Blur = 0,
	Shadow = 0.4,
	Gradient = false,
	SwitchOn = Color3.fromRGB(208, 188, 255),
	SwitchKnob = Color3.fromRGB(202, 196, 208),
	SwitchKnobOn = Color3.fromRGB(56, 30, 114),
	SliderKnob = Color3.fromRGB(208, 188, 255),

	Duration = 0.24,
	Easing = Enum.EasingStyle.Quint,
})

return Os
