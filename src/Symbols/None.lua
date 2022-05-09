local None = newproxy(true)
getmetatable(None).__tostring = function()
	return "<Network.None>"
end
return None