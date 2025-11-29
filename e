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
local fileName="VisitedServers.txt"
if not isfile(fileName)then writefile(fileName,"")end
local function parseMoney(text)
	if not text or text==""then return 0 end
	text=text:gsub(",",""):upper()
	local num=tonumber(text:match("[%d%.]+"))or 0
	if text:find("Q")then
		return num*1_000_000_000
	elseif text:find("T")then
		return num*1_000_000
	elseif text:find("B")then
		return num*1_000
	elseif text:find("M")then
		return num
	elseif text:find("K")then
		return num/1000
	else
		return num
	end
end
local function sendWebhook(displayName,rarity,money,players)
	local data={["content"]="",["embeds"]={{["title"]="🐾 **Brainrot Found!**",["color"]=tonumber(0x00FFFF),["fields"]={
		{["name"]="🐶 Name",["value"]=tostring(displayName or"Unknown"),["inline"]=true},
		{["name"]="🌟 Rarity",["value"]=tostring(rarity or"N/A"),["inline"]=true},
		{["name"]="💸 Money Per Second",["value"]=tostring(money).."M",["inline"]=true},
		{["name"]="👥 Players",["value"]=tostring(players).."/8",["inline"]=true},
		{["name"]="🧩 Join Code:",["value"]="```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(109983668079237,'" .. JobId .. "',game.Players.LocalPlayer)\n```",["inline"]=false}
	}}}}
	local encoded=HttpService:JSONEncode(data)
	pcall(function()request({Url=Webhook_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=encoded})end)
end
local function sendToFirebase(data)
	local jsonData=HttpService:JSONEncode(data)
	request({Url=FIREBASE_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=jsonData})
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
				local rarity=r.Text
				if table.find(ALLOWED_RARITIES,rarity)and money>=MIN_MILLIONS then
					table.insert(brainrots,{Name=n.Text,Rarity=rarity,Money=money,Players=#Players:GetPlayers(),JobId=JobId,PlaceId=PlaceId,Time=os.time()})
				end
			end
		end
	end
	if #brainrots>0 then
		for _,info in ipairs(brainrots)do
			sendToFirebase(info)
			sendWebhook(info.Name,info.Rarity,info.Money,info.Players)
		end
		task.wait(3)
		return true
	end
	return false
end
local function getAvailableServers(maxRetries)
	maxRetries=maxRetries or 3
	local servers={}
	local tries=0
	while tries<maxRetries and #servers==0 do
		tries+=1
		local cursor=nil
		repeat
			local url
			if cursor then
				local encoded=HttpService:UrlEncode(cursor)
				url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d&cursor=%s",PROXY,PlaceId,PAGE_LIMIT,encoded)
			else
				url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d",PROXY,PlaceId,PAGE_LIMIT)
			end
			local success,result=pcall(function()return game:HttpGet(url)end)
			if success then
				local data=HttpService:JSONDecode(result)
				if data and data.data then
					for _,server in ipairs(data.data)do
						if type(server)=="table"and server.id~=JobId and tonumber(server.playing)>=3 and tonumber(server.playing)<tonumber(server.maxPlayers)then
							table.insert(servers,server.id)
						end
					end
				end
				cursor=data.nextPageCursor
			else
				cursor=nil
			end
			task.wait(0.2)
		until not cursor
		if #servers==0 then
			task.wait(2)
		end
	end
	return servers
end

local function serverHop()
	local servers=getAvailableServers(5)
	if #servers>0 then
		local serverId=servers[math.random(1,#servers)]
		writefile("VisitedServers.txt",serverId)
		TeleportService:TeleportToPlaceInstance(PlaceId,serverId,player)
	else
		task.wait(2)
		serverHop()
	end
end
local found=scanServer()
if teleportFunc then
	teleportFunc([[loadstring(game:HttpGet("https://raw.githubusercontent.com/elproscriptos/Scripts/refs/heads/main/e"))()]])
end
if found then
	task.wait(2)
	serverHop()
else
	task.wait(1)
	serverHop()
end
