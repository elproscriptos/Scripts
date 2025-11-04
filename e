repeat task.wait() until game:IsLoaded()
task.wait(1)
local Players=game:GetService("Players")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local PlaceId=game.PlaceId
local JobId=game.JobId
local Webhook_URL="https://discord.com/api/webhooks/1434613898270736530/ZUgzRA73I65rxaKgrSMciek-nX11l_pq4H-8Nwx9kB2FcDlPtmwDsIbe6iYNhBkez9Jp"
local MIN_MILLIONS=1
local ALLOWED_RARITIES={"Secret","Brainrot God"}
local PROXY="https://brotato-three.vercel.app/games/v1/games/"
local PAGE_LIMIT=100
local teleportFunc=queueonteleport or queue_on_teleport
local fileName="VisitedServers.txt"
if not isfile(fileName) then writefile(fileName,"") end

local function parseMoney(text)
	if not text then return 0 end
	text=text:gsub(",",""):upper()
	local num=tonumber(text:match("[%d%.]+")) or 0
	if text:find("B") then return num*1000 elseif text:find("M") then return num elseif text:find("K") then return num/1000 else return num/1_000_000 end
end

local function sendWebhook(displayName,rarity,money,players)
	local serverid=readfile("VisitedServers.txt")
	local data={["content"]="",["embeds"]={{["title"]="🐾 **Brainrot Found!**",["color"]=tonumber(0x00FFFF),["fields"]={{["name"]="🐶 Name",["value"]=tostring(displayName or "Unknown"),["inline"]=true},{["name"]="🌟 Rarity",["value"]=tostring(rarity or "N/A"),["inline"]=true},{["name"]="💸 Money Per Second",["value"]=tostring(money).."M",["inline"]=true},{["name"]="👥 Players",["value"]=tostring(players).."/8",["inline"]=true},{["name"]="🔗 Join Link",["value"]="https://www.roblox.com/games/start?placeId="..PlaceId.."&gameInstanceId="..serverid,["inline"]=false}}}}
	local encoded=HttpService:JSONEncode(data)
	pcall(function() request({Url=Webhook_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=encoded}) end)
end

local function scanServer()
	for _,descendant in ipairs(workspace:GetDescendants()) do
		if descendant.Name=="AnimalOverhead" and descendant:IsA("BillboardGui") then
			local genLabel=descendant:FindFirstChild("Generation")
			local displayName=descendant:FindFirstChild("DisplayName")
			local rarityLabel=descendant:FindFirstChild("Rarity")
			if genLabel and displayName and rarityLabel then
				local money=parseMoney(genLabel.Text)
				local rarity=rarityLabel.Text
				if money>=MIN_MILLIONS and table.find(ALLOWED_RARITIES,rarity) then
					local players=#Players:GetPlayers()
					sendWebhook(displayName.Text,rarity,money,players)
				end
			end
		end
	end
end

local function getAvailableServers()
	local servers={}
	local visited={}
	if isfile(fileName) then
		for line in string.gmatch(readfile(fileName),"[^\r\n]+") do
			visited[line]=true
		end
	end
	local cursor=""
	repeat
		local url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d%s",PROXY,PlaceId,PAGE_LIMIT,cursor~="" and "&cursor="..cursor or "")
		local success,response=pcall(function() return game:HttpGet(url) end)
		if not success then break end
		local data=HttpService:JSONDecode(response)
		if data and data.data then
			for _,server in ipairs(data.data) do
				if type(server)=="table" and server.id~=JobId and tonumber(server.playing)<tonumber(server.maxPlayers) and not visited[server.id] then
					table.insert(servers,server.id)
				end
			end
		end
		cursor=data.nextPageCursor or ""
	until cursor=="" or #servers>=50
	return servers
end

local function serverHop()
	local servers=getAvailableServers()
	if #servers==0 then return end
	for _,serverId in ipairs(servers) do
		local success=pcall(function()
			TeleportService:TeleportToPlaceInstance(PlaceId,serverId,player)
		end)
		if success then
			writefile("VisitedServers.txt",serverId)
			break
		end
	end
end

while true do
	scanServer()
	if teleportFunc then
		teleportFunc([[loadstring(game:HttpGet("https://raw.githubusercontent.com/elproscriptos/Scripts/refs/heads/main/e"))()]])
	end
	serverHop()
	task.wait(1)
end
