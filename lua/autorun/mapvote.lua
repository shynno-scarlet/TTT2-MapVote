MapVote = {}
MapVote.Config = {}

-- CONFIG (sort of)
local flags = {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}
MapVote.Config = {
	MapLimit = CreateConVar("mapvote_maplimit","24",flags,"",12,48),
	TimeLimit = CreateConVar("mapvote_timelimit","40",flags,"",15,60),
	AllowCurrentMap = CreateConVar("mapvote_allowcurrentmap","0",flags,"",0,1)
}

MapVote.CurrentMaps = {}
MapVote.Votes = {}

MapVote.Allow = false

MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN = 3

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("mapvote/cl_mapvote.lua")

	include("mapvote/sv_mapvote.lua")
else
	include("mapvote/cl_mapvote.lua")
end
