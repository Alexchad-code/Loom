--!strict
-- The token record a style fills in, on its own so the style presets can be
-- typed without requiring the registry that loads them. Types only: the empty
-- table at the end is what makes the module requirable.

--- How the window draws its controls: macOS dots, right-hand caption glyphs, or
--- a lone close button the way GNOME and Material sheets do it.
export type Chrome = "traffic" | "caption" | "close"

export type Theme = {
	Name: string,
	Light: boolean,

	Window: Color3,
	WindowTransparency: number,
	Sidebar: Color3,
	SidebarTransparency: number,
	Surface: Color3,
	SurfaceTransparency: number,
	SurfaceHover: Color3,
	SurfaceHoverTransparency: number,
	Inset: Color3,
	InsetTransparency: number,
	Track: Color3,
	TrackTransparency: number,
	Popup: Color3,
	PopupTransparency: number,
	Stroke: Color3,
	StrokeTransparency: number,

	Text: Color3,
	TextDim: Color3,
	TextFaint: Color3,
	OnAccent: Color3,

	Accent: Color3,
	AccentB: Color3,
	Success: Color3,
	Warning: Color3,
	Danger: Color3,

	Chrome: Chrome,
	TitleAlign: Enum.TextXAlignment,
	DotClose: Color3,
	DotMinimize: Color3,
	DotZoom: Color3,

	Corner: number,
	SmallCorner: number,
	Round: boolean,
	StrokeWidth: number,
	Indicator: number,
	EntryAccent: boolean,

	RowHeight: number,
	Pad: number,
	Gap: number,
	SidebarWidth: number,

	Font: Enum.Font,
	MediumFont: Enum.Font,
	BoldFont: Enum.Font,
	MonoFont: Enum.Font,
	FontSize: number,
	SmallFontSize: number,
	TitleFontSize: number,

	Gloss: number,
	Blur: number,
	Shadow: number,
	Gradient: boolean,
	SwitchOn: Color3,
	SwitchKnob: Color3,
	SwitchKnobOn: Color3,
	SliderKnob: Color3,

	Duration: number,
	Easing: Enum.EasingStyle,
}

return {}
