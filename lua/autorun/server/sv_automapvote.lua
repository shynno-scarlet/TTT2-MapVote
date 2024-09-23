hook.Add("Initialize", "AutoMapVote", function()
	if GAMEMODE_NAME ~= "terrortown" then
		return
	end

	local rounds = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
	local time = math.max(0, GetConVar("ttt_time_limit_minutes"):GetInt() * 60 - CurTime())
	SetGlobalInt("ttt_rounds_left", rounds)

	local call_vote = (rounds <= 0) or (time <= 0)

	if call_vote then
		-- stop TTT timer
		timer.Stop("end2prep")
		MapVote.Start(nil,nil,nil,nil)
	end
end)
