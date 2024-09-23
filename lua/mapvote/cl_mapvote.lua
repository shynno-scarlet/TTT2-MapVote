surface.CreateFont("RAM_VoteFont", {
	font = "Trebuchet MS",
	size = 19,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("RAM_VoteFontCountdown", {
	font = "Tahoma",
	size = 32,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("RAM_VoteSysButton",
{	font = "Marlett",
	size = 13,
	weight = 0,
	symbol = true,
})

MapVote.EndTime = 0
MapVote.Panel = false

net.Receive("RAM_MapVoteStart", function()
	MapVote.CurrentMaps = {}
	MapVote.Allow = true
	MapVote.Votes = {}

	local amt = net.ReadUInt(32)

	for i = 1, amt do
		local map = net.ReadString()

		MapVote.CurrentMaps[#MapVote.CurrentMaps + 1] = map
	end

	MapVote.EndTime = CurTime() + net.ReadUInt(32)

	if (IsValid(MapVote.Panel)) then
		MapVote.Panel:Remove()
	end

	MapVote.Panel = vgui.Create("RAM_VoteScreen")
	MapVote.Panel:SetMaps(MapVote.CurrentMaps)
end)

net.Receive("RAM_MapVoteUpdate", function()
	local update_type = net.ReadUInt(3)

	if (update_type == MapVote.UPDATE_VOTE) then
		local ply = net.ReadEntity()

		if (IsValid(ply)) then
			local map_id = net.ReadUInt(32)
			MapVote.Votes[ply:SteamID()] = map_id

			if (IsValid(MapVote.Panel)) then
				MapVote.Panel:AddVoter(ply)
			end
		end
	elseif (update_type == MapVote.UPDATE_WIN) then
		if (IsValid(MapVote.Panel)) then
			MapVote.Panel:Flash(net.ReadUInt(32))
		end
	end
end)

net.Receive("RAM_MapVoteCancel", function()
	if IsValid(MapVote.Panel) then
		MapVote.Panel:Remove()
	end
end)

local PANEL = {}

function PANEL:Init()
	self:ParentToHUD()
	self.startTime = SysTime()

	self.Canvas = vgui.Create("Panel", self)
	self.Canvas:MakePopup()
	self.Canvas:SetKeyboardInputEnabled(false)

	self.countDown = vgui.Create("DLabel", self.Canvas)
	self.countDown:SetTextColor(color_white)
	self.countDown:SetFont("RAM_VoteFontCountdown")
	self.countDown:SetText("")
	self.countDown:SetPos(0, 14)

	function self.countDown:PerformLayout()
		self:SizeToContents()
		self:CenterHorizontal()
	end

	self.mapList = vgui.Create("DPanelList", self.Canvas)
	self.mapList:SetPaintBackground(false)
	self.mapList:SetSpacing(4)
	self.mapList:SetPadding(4)
	self.mapList:EnableHorizontal(true)
	self.mapList:EnableVerticalScrollbar()

	self.closeButton = vgui.Create("DButton", self.Canvas)
	self.closeButton:SetText("")

	self.closeButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
	end

	self.closeButton.DoClick = function()
		self:SetVisible(false)
	end

	self.maximButton = vgui.Create("DButton", self.Canvas)
	self.maximButton:SetText("")
	self.maximButton:SetDisabled(true)

	self.maximButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
	end

	self.minimButton = vgui.Create("DButton", self.Canvas)
	self.minimButton:SetText("")
	self.minimButton:SetDisabled(true)

	self.minimButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
	end

	self.Voters = {}
end

function PANEL:PerformLayout()
	self:SetPos(0, 0)
	self:SetSize(ScrW(), ScrH())

	local extra = math.Clamp(1000, 0, ScrW() - 640)
	self.Canvas:StretchToParent(0, 0, 0, 0)
	self.Canvas:SetWide(640 + extra)
	self.Canvas:SetTall(ScrH() - 80)
	self.Canvas:SetPos(0, 0)
	self.Canvas:CenterHorizontal()
	self.Canvas:SetZPos(100)

	self.mapList:StretchToParent(0, 90, 0, 0)

	local buttonPos = 640 + extra - 31 * 3

	self.closeButton:SetPos(buttonPos - 31 * 0, 4)
	self.closeButton:SetSize(31, 31)
	self.closeButton:SetVisible(true)

	self.maximButton:SetPos(buttonPos - 31 * 1, 4)
	self.maximButton:SetSize(31, 31)
	self.maximButton:SetVisible(true)

	self.minimButton:SetPos(buttonPos - 31 * 2, 4)
	self.minimButton:SetSize(31, 31)
	self.minimButton:SetVisible(true)
end

function PANEL:AddVoter(voter)
	for k, v in pairs(self.Voters) do
		if (v.Player and v.Player == voter) then
			return false
		end
	end

	local icon_container = vgui.Create("Panel", self.mapList:GetCanvas())
	local icon = vgui.Create("AvatarImage", icon_container)
	icon:SetSize(32, 32)
	icon:SetZPos(1000)
	icon:SetTooltip(voter:Name())
	icon_container.Player = voter
	icon_container:SetTooltip(voter:Name())
	icon:SetPlayer(voter, 32)

	icon_container:SetSize(36, 36)
	icon:SetPos(2, 2)

	icon_container.Paint = function(s, w, h)
		if (icon_container.img) then
			surface.SetMaterial(icon_container.img)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawTexturedRect(2, 2, 16, 16)
		end
	end

	icon_container:SetMouseInputEnabled(false)
	icon_container:SetAlpha(200)

	table.insert(self.Voters, icon_container)
end

function PANEL:Think()
	for k, v in pairs(self.mapList:GetItems()) do
		v.NumVotes = 0
	end

	for k, v in pairs(self.Voters) do
		if (not IsValid(v.Player)) then
			v:Remove()
		else
			if (not MapVote.Votes[v.Player:SteamID()]) then
				v:Remove()
			else
				local bar = self:GetMapButton(MapVote.Votes[v.Player:SteamID()])

				bar.NumVotes = bar.NumVotes + 1

				if (IsValid(bar)) then
					local NewPos = Vector(4 + bar.x + (40 * (bar.NumVotes - 1)), bar.y + 4, 0)

					if (not v.CurPos or v.CurPos ~= NewPos) then
						v:MoveTo(NewPos.x, NewPos.y, 0.3)
						v.CurPos = NewPos
					end
				end
			end
		end

	end

	local timeLeft = math.Round(math.Clamp(MapVote.EndTime - CurTime(), 0, math.huge))

	self.countDown:SetText(tostring(timeLeft or 0) .. " seconds")
	self.countDown:SizeToContents()
	self.countDown:CenterHorizontal()
end

function PANEL:SetMaps(maps)
	self.mapList:Clear()

	for k, v in RandomPairs(maps) do
		local container = vgui.Create("DLabel", self.mapList)
		container.ID = k
		container.NumVotes = 0
		container:SetSize(180,180)
		container:SetText("")
		container:SetPaintBackgroundEnabled(false)

		function container:PerformLayout()
			self:SetBGColor(54, 201, 138, 255)
		end

		local button = vgui.Create("DImageButton", container)
		button:SetMaterial(map.GetIcon(v))
		button:SetPos(2,2)
		button:SetSize(176,176)
		function button:OnMousePressed(_)
			net.Start("RAM_MapVoteUpdate")
			net.WriteUInt(MapVote.UPDATE_VOTE, 3)
			net.WriteUInt(container.ID, 32)
			net.SendToServer()
		end

		local text = vgui.Create("DLabel", container)
		local textColor = {r = 161, g = 179, b = 207, a = 255}
		text:SetPos(2,120)
		text:SetSize(176,30)
		text:SetText(v)
		text:SetContentAlignment(5)
		text:SetFont("RAM_VoteFont")
		text:SetPaintBackgroundEnabled(true)
		text:SetBGColor(25,28,32,255)
		text:SetTextColor(textColor)
		function text:PerformLayout()
			self:SetBGColor(25,28,32,255)
			self:SetTextColor(textColor)
		end

		self.mapList:AddItem(container)
	end
end

function PANEL:GetMapButton(id)
	for k, v in pairs(self.mapList:GetItems()) do
		if (v.ID == id) then return v end
	end

	return false
end

function PANEL:Paint()
	Derma_DrawBackgroundBlur(self, self.startTime)
end

function PANEL:Flash(id)
	self:SetVisible(true)

	local bar = self:GetMapButton(id)

	local function show()
		bar:SetPaintBackgroundEnabled(true)
		surface.PlaySound("hl1/fvox/blip.wav")
	end

	local function hide()
		bar:SetPaintBackgroundEnabled(false)
	end

	if (IsValid(bar)) then
		for i = 0, 5, 1 do
			local t = i / 4
			local func = hide
			if (i % 2) == 0 then
				func = show
			end
			timer.Simple(t, func)
		end
	end
end

derma.DefineControl("RAM_VoteScreen", "", PANEL, "DPanel")
