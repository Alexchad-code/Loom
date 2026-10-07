--!strict
-- Tween helpers. Every animation in Loom goes through here so durations and
-- easing styles stay consistent with the active theme.

local TweenService = game:GetService("TweenService")

local Animate = {}

export type Done = (played: boolean) -> ()

--- Tween `goal` properties on `instance`. `onDone` fires once, with `false`
--- if the tween was superseded before finishing.
function Animate.play(
	instance: Instance,
	goal: { [string]: any },
	duration: number,
	style: Enum.EasingStyle?,
	onDone: Done?
): Tween
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goal)
	if onDone then
		tween.Completed:Once(function(playbackState)
			onDone(playbackState == Enum.PlaybackState.Completed)
		end)
	end
	tween:Play()
	return tween
end

--- Snap properties with no animation, so a later tween starts from the right place.
function Animate.snap(instance: Instance, goal: { [string]: any })
	for key, value in goal do
		(instance :: any)[key] = value
	end
end

return Animate
