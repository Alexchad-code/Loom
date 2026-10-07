--!strict
-- Visual primitives. Everything drawn by Loom is assembled from these, so the
-- active Theme is the only thing that decides how a window looks.

local New = require("@self/New")
local Animate = require("@self/Animate")
local Icons = require("@self/Icons")
local ThemeModule = require("@self/Theme")

type Theme = ThemeModule.Theme

local Ui = {}

--- Full pill radius. UICorner clamps scale to 0.5 on the shorter axis.
local PILL = UDim.new(1, 0)

--- Multiplies a colour towards black (factor < 1) or white (factor > 1).
function Ui.shade(color: Color3, factor: number): Color3
	if factor <= 1 then
		return Color3.new(color.R * factor, color.G * factor, color.B * factor)
	end
	local lift = factor - 1
	return Color3.new(
		color.R + (1 - color.R) * lift,
		color.G + (1 - color.G) * lift,
		color.B + (1 - color.B) * lift
	)
end

function Ui.corner(parent: Instance, radius: UDim): UICorner
	return New("UICorner", { CornerRadius = radius }, nil, parent)
end

function Ui.stroke(parent: Instance, theme: Theme, color: Color3?, transparency: number?): UIStroke
	return New("UIStroke", {
		Color = color or theme.Stroke,
		Thickness = theme.StrokeWidth,
		Transparency = transparency or theme.StrokeTransparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, nil, parent)
end

--- Uniform padding, or (top, right, bottom, left) with the usual CSS fallbacks.
function Ui.pad(parent: Instance, top: number, right: number?, bottom: number?, left: number?): UIPadding
	local r = right or top
	local b = bottom or r
	local l = left or r
	return New("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l),
	}, nil, parent)
end

--- Vertical (default) or horizontal list layout using the theme's gap.
function Ui.list(parent: Instance, theme: Theme, horizontal: boolean?): UIListLayout
	return New("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, theme.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, parent)
end

--- A raised surface: themed background, theme.Corner radius, hairline stroke.
function Ui.surface(parent: Instance, theme: Theme, props: { [string]: any }?): Frame
	local merged: { [string]: any } = {
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}

	if props then
		for key, value in props do
			merged[key] = value
		end
	end

	local frame = New("Frame", merged, nil, parent)
	Ui.corner(frame, UDim.new(0, theme.Corner))
	Ui.stroke(frame, theme)
	return frame
end

--- A control well: text boxes, keybind buttons and dropdown headers sit in these.
function Ui.inset(parent: Instance, theme: Theme, props: { [string]: any }?): Frame
	local merged: { [string]: any } = {
		BackgroundColor3 = theme.Inset,
		BackgroundTransparency = theme.InsetTransparency,
		BorderSizePixel = 0,
	}

	if props then
		for key, value in props do
			merged[key] = value
		end
	end

	local frame = New("Frame", merged, nil, parent)
	Ui.corner(frame, Ui.control(theme))
	return frame
end

--- Corner radius for controls: rows, buttons, inputs, switch tracks, sidebar
--- entries. A style that rounds everything (iOS, Material) gets a pill instead
--- of a radius, which is most of what makes those styles recognisable.
function Ui.control(theme: Theme): UDim
	return if theme.Round then PILL else UDim.new(0, theme.SmallCorner)
end

--- A filled, fully rounded shape: toggle tracks, slider rails, badges.
function Ui.pill(parent: Instance, theme: Theme, color: Color3, transparency: number?): Frame
	local frame = New("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
	}, nil, parent)
	Ui.corner(frame, PILL)
	return frame
end

--- TextLabel with Loom's typography defaults; `props` wins over every default.
function Ui.text(theme: Theme, parent: Instance, props: { [string]: any }?): TextLabel
	local merged: { [string]: any } = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = theme.Font,
		TextSize = theme.FontSize,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}

	if props then
		for key, value in props do
			merged[key] = value
		end
	end

	return New("TextLabel", merged, nil, parent)
end

--- Secondary text: descriptions, hints, value readouts.
function Ui.textDim(theme: Theme, parent: Instance, props: { [string]: any }?): TextLabel
	local merged: { [string]: any } = {
		Font = theme.Font,
		TextSize = theme.SmallFontSize,
		TextColor3 = theme.TextFaint,
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end
	return Ui.text(theme, parent, merged)
end

--- An icon: drawn Lucide geometry by name, an image when it looks like an asset
--- id, and a text glyph for anything this build does not carry.
function Ui.icon(parent: Instance, theme: Theme, icon: string, props: { [string]: any }?): GuiObject
	local merged: { [string]: any } = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end

	if Icons.isAsset(icon) then
		merged.Image = icon
		return New("ImageLabel", merged, nil, parent)
	end

	local drawn = Icons.draw(parent, icon, theme, merged)
	if drawn then
		return drawn
	end

	merged.Text = Icons.resolve(icon)
	merged.Font = theme.Font
	merged.TextSize = merged.TextSize or theme.FontSize
	return New("TextLabel", merged, nil, parent)
end

--- Recolours whichever kind of object Ui.icon returned. A drawn icon is a
--- container of segment frames, so every piece takes the colour.
function Ui.tint(object: GuiObject, color: Color3, transparency: number?)
	if object:IsA("TextLabel") then
		object.TextColor3 = color
		if transparency then
			object.TextTransparency = transparency
		end
	elseif object:IsA("ImageLabel") then
		object.ImageColor3 = color
		if transparency then
			object.ImageTransparency = transparency
		end
	elseif object:IsA("Frame") then
		for _, piece in object:GetChildren() do
			local face = piece :: Frame
			face.BackgroundColor3 = color
			if transparency then
				face.BackgroundTransparency = transparency
			end
		end
	end
end

--- Accent sweep used on toggles, sliders, tabs and primary buttons.
function Ui.gradient(parent: Instance, from: Color3, to: Color3, rotation: number?): UIGradient
	return New("UIGradient", {
		Color = ColorSequence.new(from, to),
		Rotation = rotation or 0,
	}, nil, parent)
end

--- Accent fill for a switch track or slider rail: a two-tone sweep on the
--- styles that use one, a flat fill on the ones that do not. `color` is the
--- live one -- a switch fills with SwitchOn, a slider with Accent.
function Ui.accentFill(parent: Instance, theme: Theme, color: Color3): Frame
	local fill = New("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, nil, parent)
	Ui.corner(fill, PILL)

	if theme.Gradient then
		Ui.gradient(fill, color, theme.AccentB)
	end
	return fill
end

--- Re-colours an accent fill for a new theme, adding or dropping its sweep.
function Ui.accentTheme(fill: Frame, theme: Theme, color: Color3)
	fill.BackgroundColor3 = color

	local sweep = fill:FindFirstChildOfClass("UIGradient")
	if not theme.Gradient then
		if sweep then
			sweep:Destroy()
		end
		return
	end

	if sweep then
		(sweep :: UIGradient).Color = ColorSequence.new(color, theme.AccentB)
	else
		Ui.gradient(fill, color, theme.AccentB)
	end
end

--- Specular sheen. Strength comes from theme.Gloss; a zero gloss is a no-op.
function Ui.gloss(parent: Instance, theme: Theme): Frame?
	if theme.Gloss <= 0 then
		return nil
	end

	local overlay = New("Frame", {
		Name = "Gloss",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, nil, parent)

	local top = 1 - theme.Gloss
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, top),
			NumberSequenceKeypoint.new(0.5, math.min(1, top + theme.Gloss * 0.5)),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, nil, overlay)

	return overlay
end

--- Asset-free drop shadow for `target`, built from concentric rounded frames.
---
--- It is parented *beside* the target, not inside it, because a child always
--- draws over its parent's own background -- a shadow parented inside would
--- darken the very surface it is meant to sit behind. The holder mirrors the
--- target's geometry and follows it as it moves and resizes.
function Ui.shadow(target: GuiObject, theme: Theme, spread: number?, radius: number?): Frame?
	if theme.Shadow <= 0 then
		return nil
	end

	local parent = target.Parent
	if parent == nil then
		return nil
	end

	local reach = spread or 22
	local layers = 6
	local corner = radius or theme.Corner

	local holder = New("Frame", {
		Name = "Shadow",
		AnchorPoint = target.AnchorPoint,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = target.ZIndex - 1,
	}, nil, parent)

	local function sync()
		local size = target.Size
		local position = target.Position
		holder.Position = UDim2.new(
			position.X.Scale,
			position.X.Offset - reach / 2,
			position.Y.Scale,
			position.Y.Offset - reach / 2
		)
		holder.Size = UDim2.new(size.X.Scale, size.X.Offset + reach, size.Y.Scale, size.Y.Offset + reach)
	end

	sync()
	target:GetPropertyChangedSignal("Position"):Connect(sync)
	target:GetPropertyChangedSignal("Size"):Connect(sync)
	target:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
		holder.AnchorPoint = target.AnchorPoint
		sync()
	end)

	for index = layers, 1, -1 do
		local grow = math.round(reach * (index / layers))
		local fade = (index - 1) / (layers - 1)
		local alpha = 1 - 0.42 * theme.Shadow * (1 - fade * fade)

		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, grow, 1, grow),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, { New("UICorner", { CornerRadius = UDim.new(0, corner + grow * 0.5) }) }, holder)
	end

	return holder
end

--- Runs `apply(true/false)` on enter/leave. Returns the connections.
function Ui.hover(target: GuiObject, apply: (hovered: boolean) -> ()): { RBXScriptConnection }
	return {
		target.MouseEnter:Connect(function()
			apply(true)
		end),
		target.MouseLeave:Connect(function()
			apply(false)
		end),
	}
end

--- Cross-fades a surface between its resting and hover colours.
function Ui.paintHover(frame: GuiObject, theme: Theme, hovered: boolean, duration: number?)
	Animate.play(frame, {
		BackgroundColor3 = hovered and theme.SurfaceHover or theme.Surface,
		BackgroundTransparency = hovered and theme.SurfaceHoverTransparency or theme.SurfaceTransparency,
	}, duration or 0.14, theme.Easing)
end

--- Styles a ScrollingFrame's bar to match the theme.
function Ui.scrollbar(scroller: ScrollingFrame, theme: Theme)
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageColor3 = theme.TextFaint
	scroller.ScrollBarImageTransparency = 0.25
	scroller.BorderSizePixel = 0
	scroller.BackgroundTransparency = 1
end

--- A hairline rule. `outset` insets it from the parent's padding.
function Ui.divider(parent: Instance, theme: Theme, outset: number?): Frame
	local inset = outset or 0
	return New("Frame", {
		Size = UDim2.new(1, -inset * 2, 0, theme.StrokeWidth),
		Position = UDim2.new(0, inset, 0, 0),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
	}, nil, parent)
end

return Ui
