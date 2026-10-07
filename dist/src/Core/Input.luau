--!strict
-- Input plumbing. One set of UserInputService connections feeds every keybind
-- and drag handler, instead of each element owning its own listener.

local SignalModule = require("@self/Signal")

local Signal = SignalModule

type Connection = SignalModule.Connection

local UserInputService = game:GetService("UserInputService")

local Input = {
	Began = Signal.new(),
	Changed = Signal.new(),
	Ended = Signal.new(),
}

--- True while a TextBox has focus, so shortcuts stay out of the way of typing.
function Input.typing(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function isPointer(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local function isPointerMove(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	Input.Began:Fire(input, gameProcessed)
end)

UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
	Input.Changed:Fire(input, gameProcessed)
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
	Input.Ended:Fire(input, gameProcessed)
end)

--- Drags `target` by `handle`. `onMove` fires on every step, to clamp or snap.
function Input.drag(handle: GuiObject, target: GuiObject, onMove: (() -> ())?)
	local grab = handle.InputBegan:Connect(function(input: InputObject)
		if not isPointer(input) then
			return
		end

		local start = input.Position
		local origin = target.Position

		local moveConnection: Connection
		local endConnection: Connection

		local function stop()
			moveConnection:Disconnect()
			endConnection:Disconnect()
		end

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			if not isPointerMove(move) then
				return
			end
			local delta = move.Position - start
			target.Position = UDim2.new(
				origin.X.Scale,
				origin.X.Offset + delta.X,
				origin.Y.Scale,
				origin.Y.Offset + delta.Y
			)
			if onMove then
				onMove()
			end
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == input.UserInputType then
				stop()
			end
		end)
	end)

	return grab
end

--- Resizes `target` from `handle`. `mode` picks which edges follow the cursor.
function Input.resize(
	handle: GuiObject,
	target: GuiObject,
	mode: "both" | "x" | "width",
	minimum: Vector2?
): RBXScriptConnection
	local floor = minimum or Vector2.new(240, 180)

	return handle.InputBegan:Connect(function(input: InputObject)
		if not isPointer(input) then
			return
		end

		local start = input.Position
		local originSize = target.Size

		local moveConnection: Connection
		local endConnection: Connection

		local function stop()
			moveConnection:Disconnect()
			endConnection:Disconnect()
		end

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			if not isPointerMove(move) then
				return
			end
			local delta = move.Position - start
			local width = originSize.X.Offset
			local height = originSize.Y.Offset

			if mode ~= "x" then
				width = math.max(floor.X, width + delta.X)
			end
			if mode ~= "width" then
				height = math.max(floor.Y, height + delta.Y)
			end

			target.Size = UDim2.fromOffset(width, height)
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == input.UserInputType then
				stop()
			end
		end)
	end)
end

return Input
