local function handle_mapvote(ply, votetime, should_cancel)
	if not should_cancel then
		MapVote.Start(votetime, nil, nil, nil)
		ulx.fancyLogAdmin(ply, "#A started a mapvote")
	else
		MapVote.Cancel()
		ulx.fancyLogAdmin(ply, "#A stopped the mapvote")
	end
end

local cmd = ulx.command("MapVote", "mapvote", handle_mapvote, "!mapvote")
cmd:addParam{ type = ULib.cmds.NumArg, min = 25, default = 40, hint = "time", ULib.cmds.optional, ULib.cmds.round }
cmd:addParam{ type = ULib.cmds.BoolArg, invisible = true }
cmd:defaultAccess(ULib.ACCESS_ADMIN)
cmd:help("Invokes the map vote logic")
cmd:setOpposite("stopvote", {_, _, true}, "!stopvote")
