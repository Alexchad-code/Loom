--!strict
-- Select list. The open popup is parented to the tab so it can escape the row,
-- and only one popup is ever open per tab.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local Input = require("@self/../Core/Input")
local SignalModule = require("@self/../Core/Signal")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme
type Connection = SignalModule.Connection

local ROW = 30
local ROW_GAP = 2
local MAX_ROWS = 5
local MIN_WIDTH = 170

local function summarize(order: { string }, selected: { [string]: boolean? }, multi: boolean): string
	local names = {}
	for _, name in order do
		if selected[name] then
			table.insert(names, name)
		end
	end

	if #names == 0 then
		return "None"
	end
	if multi then
		return if #names == 1 then names[1] else `{#names} selected`
	end
	return names[1]
end

local function current(order: { string }, selected: { [string]: boolean? }, multi: boolean): any
	if multi then
		local names = {}
		for _, name in order do
			if selected[name] then
				table.insert(names, name)
			end
		end
		return names
	end

	for _, name in order do
		if selected[name] then
			return name
		end
	end
	return nil
end

local function inside(object: GuiObject, point: Vector2): boolean
	local origin = object.AbsolutePosition
	local size = object.AbsoluteSize
	return point.X >= origin.X
		and point.X <= origin.X + size.X
		and point.Y >= origin.Y
		and point.Y <= origin.Y + size.Y
end

local function isPointer(inputObject: InputObject): boolean
	local kind = inputObject.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = Element })

export type Dropdown = Element.Internal & {
	Set: (self: Dropdown, value: any) -> (),
	Get: (self: Dropdown) -> any,
	SetOptions: (self: Dropdown, names: { string }) -> (),
	Clear: (self: Dropdown) -> (),
	Close: (self: Dropdown) -> (),
	Header: TextButton,
	_Config: { [string]: any },
	_Tab: any,
	_Multi: boolean,
	_Search: boolean,
	_Order: { string },
	_Selected: { [string]: boolean? },
	_Rows: { { Row: TextButton, Check: GuiObject, Name: string } },
	_Visible: number,
	_Open: boolean,
	_Filter: string,
	_Popup: Frame?,
	_Scroller: ScrollingFrame?,
	_SearchBox: Frame?,
	_SearchInput: TextBox?,
	_HeaderLabel: TextLabel,
	_Chevron: GuiObject,
	_Outside: Connection?,
	_Refresh: (self: Dropdown) -> (),
	_Publish: (self: Dropdown, notify: boolean) -> (),
	_Row: (self: Dropdown, name: string, order: number) -> (),
	_Render: (self: Dropdown, filter: string?) -> (),
	_Height: (self: Dropdown) -> number,
	_Fit: (self: Dropdown) -> (),
	_Place: (self: Dropdown) -> (),
	_Build: (self: Dropdown) -> (),
	_Select: (self: Dropdown, name: string) -> (),
	_OpenMenu: (self: Dropdown) -> (),
}

function Dropdown._Refresh(self: Dropdown)
	self._HeaderLabel.Text = summarize(self._Order, self._Selected, self._Multi)
	for _, row in self._Rows do
		row.Check.Visible = self._Selected[row.Name] == true
	end
end

function Dropdown._Publish(self: Dropdown, notify: boolean)
	self:_Refresh()
	self.Value = current(self._Order, self._Selected, self._Multi)

	if notify then
		self:_emit(self.Value)
		if self._Config.Callback then
			self._Config.Callback(self.Value)
		end
	end
end

function Dropdown._Row(self: Dropdown, name: string, order: number)
	local scroller = self._Scroller
	if not scroller then
		return
	end

	local theme = self.Theme
	local row = New("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, ROW),
		LayoutOrder = order,
		BackgroundColor3 = theme.SurfaceHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, nil, scroller)
	Ui.corner(row, Ui.control(theme))

	Ui.text(theme, row, {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Text = name,
	})

	local check = Ui.icon(row, theme, "check", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		TextSize = 13,
		Visible = self._Selected[name] == true,
	})
	Ui.tint(check, theme.Accent)

	Ui.hover(row, function(hovered: boolean)
		local active = self.Theme
		Animate.play(
			row,
			{ BackgroundTransparency = if hovered then 0.12 + active.SurfaceHoverTransparency * 0.88 else 1 },
			0.12,
			active.Easing
		)
	end)

	row.Activated:Connect(function()
		self:_Select(name)
	end)

	table.insert(self._Rows, { Row = row, Check = check, Name = name })
end

function Dropdown._Render(self: Dropdown, filter: string?)
	local scroller = self._Scroller
	if not scroller then
		return
	end

	for _, child in scroller:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._Rows = {}

	local needle = string.lower(filter or self._Filter)
	self._Filter = needle

	local visible = 0
	for _, name in self._Order do
		if needle == "" or string.find(string.lower(name), needle, 1, true) then
			visible += 1
			self:_Row(name, visible)
		end
	end

	self._Visible = visible
	scroller.CanvasSize = UDim2.fromOffset(0, visible * (ROW + ROW_GAP))
	scroller.Size = UDim2.new(1, 0, 0, math.min(visible, MAX_ROWS) * (ROW + ROW_GAP))
	self:_Fit()
end

function Dropdown._Height(self: Dropdown): number
	local rows = math.min(self._Visible, MAX_ROWS)
	return 12 + (if self._SearchBox then 34 else 0) + rows * (ROW + ROW_GAP)
end

function Dropdown._Fit(self: Dropdown)
	local popup = self._Popup
	if not popup then
		return
	end
	popup.Size = UDim2.fromOffset(math.max(self.Header.AbsoluteSize.X, MIN_WIDTH), self:_Height())
end

function Dropdown._Place(self: Dropdown)
	local popup = self._Popup
	if not popup then
		return
	end

	local host: Frame = self._Tab.Popups
	local origin = host.AbsolutePosition
	local hostHeight = host.AbsoluteSize.Y
	local position = self.Header.AbsolutePosition
	local size = self.Header.AbsoluteSize

	self:_Fit()

	local height = popup.Size.Y.Offset
	local top = position.Y - origin.Y + size.Y + 4
	if top + height > hostHeight then
		top = math.max(0, position.Y - origin.Y - 4 - height)
	end

	popup.Position = UDim2.fromOffset(position.X - origin.X, top)
end

function Dropdown._Build(self: Dropdown)
	local theme = self.Theme
	local popup = New("Frame", {
		Name = "DropdownPopup",
		BackgroundColor3 = theme.Popup,
		BackgroundTransparency = theme.PopupTransparency,
		BorderSizePixel = 0,
		Visible = false,
		GroupTransparency = 1,
		ZIndex = 50,
	}, nil, self._Tab.Popups)
	Ui.corner(popup, UDim.new(0, theme.Corner))
	Ui.stroke(popup, theme)
	Ui.shadow(popup, theme, 16)
	self._Popup = popup

	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, popup)
	Ui.pad(content, 6)
	Ui.list(content, theme)

	if self._Search then
		local box =
			Ui.inset(content, theme, { Name = "Search", Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1 })
		Ui.pad(box, 0, 8, 0, 8)

		local input = New("TextBox", {
			Name = "Input",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = theme.Font,
			TextSize = theme.FontSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = "Search",
			PlaceholderColor3 = theme.TextFaint,
			Text = "",
		}, nil, box)
		input:GetPropertyChangedSignal("Text"):Connect(function()
			self:_Render(input.Text)
		end)

		self._SearchBox = box
		self._SearchInput = input
	end

	local scroller = New("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, nil, content)
	Ui.scrollbar(scroller, theme)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, ROW_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, scroller)
	self._Scroller = scroller

	self:_Render(nil)
end

function Dropdown._OpenMenu(self: Dropdown)
	local tab = self._Tab
	if tab.OpenPopup and tab.OpenPopup ~= self then
		tab.OpenPopup:Close()
	end
	tab.OpenPopup = self

	if not self._Popup then
		self:_Build()
	end

	local popup = self._Popup :: Frame
	self._Open = true
	popup.Visible = true
	self:_Place()

	Animate.play(popup, { GroupTransparency = 0 }, 0.14, self.Theme.Easing)
	Animate.play(self._Chevron, { Rotation = 180 }, 0.16, self.Theme.Easing)

	self._Outside = Input.Began:Connect(function(inputObject: InputObject)
		if not isPointer(inputObject) then
			return
		end

		local point = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
		if inside(popup, point) or inside(self.Header, point) then
			return
		end

		self:Close()
	end)
end

function Dropdown._Select(self: Dropdown, name: string)
	if self._Multi then
		self._Selected[name] = (not self._Selected[name]) or nil
	else
		table.clear(self._Selected)
		self._Selected[name] = true
	end

	self:_Publish(true)

	if not self._Multi then
		self:Close()
	end
end

function Dropdown.new(tab: any, config: any): Dropdown
	local options: { [string]: any } = config or {}
	local theme: Theme = tab.Theme

	local self: Dropdown = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				Height = options.Height,
				ControlWidth = 160,
				ControlHeight = 30,
			}),
			Dropdown
		) :: any
	) :: Dropdown

	self._Config = options
	self._Tab = tab
	self._Multi = options.Multi == true
	self._Search = options.Search == true
	self._Order = table.clone(options.Options or {})
	self._Selected = {}
	self._Rows = {}
	self._Visible = 0
	self._Open = false
	self._Filter = ""

	local header = New("TextButton", {
		Name = "Dropdown",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Inset,
		BackgroundTransparency = theme.InsetTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, nil, self.Control)
	Ui.corner(header, Ui.control(theme))
	Ui.stroke(header, theme, nil, 0.6)
	self.Header = header

	local headerLabel = Ui.text(theme, header, {
		Name = "Selected",
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = theme.MediumFont,
		Text = "None",
	})
	self._HeaderLabel = headerLabel

	local chevron = Ui.icon(header, theme, "chevron", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -9, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		TextSize = 13,
	})
	Ui.tint(chevron, theme.TextDim)
	self._Chevron = chevron

	local default = options.Default
	if self._Multi then
		if type(default) == "table" then
			for _, name in default do
				if table.find(self._Order, name) then
					self._Selected[name] = true
				end
			end
		end
	elseif type(default) == "string" and table.find(self._Order, default) then
		self._Selected[default] = true
	end

	self.Value = current(self._Order, self._Selected, self._Multi)
	headerLabel.Text = summarize(self._Order, self._Selected, self._Multi)

	header.Activated:Connect(function()
		if self._Open then
			self:Close()
		else
			self:_OpenMenu()
		end
	end)

	self:OnTheme(function(updated: Theme)
		header.BackgroundColor3 = updated.Inset
		header.BackgroundTransparency = updated.InsetTransparency
		headerLabel.Font = updated.MediumFont
		headerLabel.TextSize = updated.FontSize
		headerLabel.TextColor3 = updated.Text
		Ui.tint(chevron, updated.TextDim)

		local popup = self._Popup
		if popup then
			popup.BackgroundColor3 = updated.Popup
			popup.BackgroundTransparency = updated.PopupTransparency
		end

		self:_Refresh()
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Dropdown.Set(self: Dropdown, value: any)
	table.clear(self._Selected)

	if self._Multi then
		if type(value) == "table" then
			for _, name in value do
				if table.find(self._Order, name) then
					self._Selected[name] = true
				end
			end
		end
	elseif type(value) == "string" and table.find(self._Order, value) then
		self._Selected[value] = true
	end

	self:_Publish(true)
end

function Dropdown.Get(self: Dropdown): any
	return current(self._Order, self._Selected, self._Multi)
end

function Dropdown.SetOptions(self: Dropdown, names: { string })
	self._Order = table.clone(names)

	for name in self._Selected do
		if not table.find(self._Order, name) then
			self._Selected[name] = nil
		end
	end

	if self._Popup then
		self:_Render(self._Filter)
	end

	self:_Publish(false)
end

function Dropdown.Clear(self: Dropdown)
	table.clear(self._Selected)
	self:_Publish(true)
end

function Dropdown.Close(self: Dropdown)
	if not self._Open then
		return
	end
	self._Open = false

	local outside = self._Outside
	if outside then
		outside:Disconnect()
		self._Outside = nil
	end

	if self._Tab.OpenPopup == self then
		self._Tab.OpenPopup = nil
	end

	local popup = self._Popup
	if popup then
		Animate.play(popup, { GroupTransparency = 1 }, 0.12, self.Theme.Easing, function()
			if not self._Open then
				popup.Visible = false
			end
		end)
	end

	Animate.play(self._Chevron, { Rotation = 0 }, 0.16, self.Theme.Easing)
end

function Dropdown.SetValue(self: Dropdown, value: any)
	self:Set(value)
end

function Dropdown.GetValue(self: Dropdown): any
	return self:Get()
end

function Dropdown.Destroy(self: Dropdown)
	self:Close()

	local popup = self._Popup
	if popup then
		popup:Destroy()
		self._Popup = nil
	end

	Element.Destroy(self)
end

return Dropdown
