--!strict
-- Snapshot dispatch, so listeners may disconnect (or connect) while firing.

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Once: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	DisconnectAll: (self: Signal) -> (),
}

--- Internals. Kept out of the exported types so callers only see the surface.
export type ConnectionInternal = Connection & {
	_callback: (...any) -> (),
	_signal: SignalInternal?,
}

export type SignalInternal = Signal & {
	_connections: { ConnectionInternal },
}

local Connection = {}
Connection.__index = Connection

local Signal = {}
Signal.__index = Signal

function Connection.new(signal: SignalInternal, callback: (...any) -> ()): ConnectionInternal
	return (
		setmetatable({ Connected = true, _signal = signal, _callback = callback }, Connection) :: any
	) :: ConnectionInternal
end

function Connection.Disconnect(self: Connection)
	local internal = self :: ConnectionInternal
	if not internal.Connected then
		return
	end

	internal.Connected = false

	local signal = internal._signal
	internal._signal = nil
	if signal then
		local index = table.find(signal._connections, internal)
		if index then
			table.remove(signal._connections, index)
		end
	end
end

function Signal.new(): SignalInternal
	return (setmetatable({ _connections = {} }, Signal) :: any) :: SignalInternal
end

function Signal.Connect(self: Signal, callback: (...any) -> ()): Connection
	local internal = self :: SignalInternal
	local connection = Connection.new(internal, callback)
	table.insert(internal._connections, connection)
	return connection
end

function Signal.Once(self: Signal, callback: (...any) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal.Fire(self: Signal, ...: any)
	local internal = self :: SignalInternal
	for _, connection in table.clone(internal._connections) do
		if connection.Connected then
			connection._callback(...)
		end
	end
end

function Signal.DisconnectAll(self: Signal)
	local internal = self :: SignalInternal
	for _, connection in table.clone(internal._connections) do
		connection:Disconnect()
	end
end

return Signal
