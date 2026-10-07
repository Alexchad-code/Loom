--!strict
-- Draws the generated Lucide polylines with thin rotated frames. Roblox has no
-- vector paths and Loom ships no image assets, so an icon is a container of
-- segments: one frame per line piece, rotated to its own angle.

local New = require("@self/../New")
local Data = require("@self/Data")

--- Lucide designs on a 24x24 grid; the icon box is whatever the caller asks for.
local GRID = 24

local Draw = {}

--- One line piece, lengthened by the stroke width so consecutive pieces meet
--- without a notch at the joint.
local function segment(
	parent: Instance,
	line: { number },
	index: number,
	unit: number,
	stroke: number,
	color: Color3
)
	local x1 = line[index]
	local y1 = line[index + 1]
	local x2 = line[index + 2]
	local y2 = line[index + 3]

	local dx = (x2 - x1) * unit
	local dy = (y2 - y1) * unit
	if dx == 0 and dy == 0 then
		return
	end

	New("Frame", {
		Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + stroke, stroke),
		Position = UDim2.new(0, (x1 + x2) / 2 * unit, 0, (y1 + y2) / 2 * unit),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, nil, parent)
end

--- Draws `name` as a container of segment frames. `props` is the same table an
--- element passes a glyph icon: Position, AnchorPoint and Size matter, the text
--- properties are ignored, and anything else is copied onto the container.
function Draw.new(
	parent: Instance,
	name: string,
	props: { [string]: any },
	color: Color3,
	thickness: number?
): Frame
	local size = 16
	local explicit = props.Size
	if explicit ~= nil and explicit.X.Offset > 0 then
		size = explicit.X.Offset
	end

	local merged: { [string]: any } = {
		Name = props.Name or "Icon",
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}
	for key, value in props do
		if key ~= "Size" and key ~= "TextSize" and key ~= "Text" and key ~= "Font" then
			merged[key] = value
		end
	end

	local container = New("Frame", merged, nil, parent)
	local stroke = thickness or math.max(1, size / 12)
	local unit = size / GRID

	for _, line in Data[name] do
		for index = 1, #line - 2, 2 do
			segment(container, line, index, unit, stroke, color)
		end
	end

	return container
end

return Draw
