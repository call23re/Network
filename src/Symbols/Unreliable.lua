local Unreliable = newproxy(true)
getmetatable(Unreliable).__tostring = function()
	return "<Network.Unreliable>"
end
return Unreliable