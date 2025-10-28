local Promise = require(script.Parent.Parent.Parent.Promise)

local function Defer()
	local res, rej;

	local promise = Promise.new(function(Resolve, Reject)
		res = Resolve
		rej = Reject
	end)

	return {
		Promise = promise,
		Resolve = res,
		Reject = rej
	}
end

return Defer