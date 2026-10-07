--!strict
-- Instance builder: New(class, props?, children?, parent?).
--
-- Parent precedence: an explicit `parent` argument wins over `props.Parent`, so
-- New("Frame", { Size = ... }, nil, holder) is never silently reparented to nil.

export type Props = { [string]: any }

local function New(className: string, props: Props?, children: { Instance }?, parent: Instance?): any
	local instance = Instance.new(className)

	if props then
		for key, value in props do
			if key ~= "Parent" then
				(instance :: any)[key] = value
			end
		end
	end

	if children then
		for _, child in children do
			child.Parent = instance
		end
	end

	local target = parent
	if target == nil and props ~= nil and props.Parent ~= nil then
		target = props.Parent
	end
	instance.Parent = target

	return instance
end

return New
