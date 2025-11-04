repeat task.wait() until game:IsLoaded()
task.wait(1)
local Players=game:GetService("Players")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local PlaceId=game.PlaceId
local JobId=game.JobId
local FIREBASE_URL="https://auto-join-logs-default-rtdb.firebaseio.com/brainrots.json"
local MIN_MILLIONS=100
local ALLOWED_RARITIES={"Secret","Brainrot God"}
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
local function sendToFirebase(data)
	local jsonData=HttpService:JSONEncode(data)
	request({Url=FIREBASE_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=jsonData})
end
local function clearFirebase()
	request({Url="https://auto-join-logs-default-rtdb.firebaseio.com/.json",Method="DELETE"})
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
		clearFirebase()
		for _,info in ipairs(brainrots)do
			sendToFirebase(info)
		end
	end
end
local function getAvailableServers()
	local servers={}
	local cursor=""
	repeat
		local url=string.format("%s%s/servers/Public?sortOrder=Asc&limit=%d%s",PROXY,PlaceId,PAGE_LIMIT,cursor~=""and"&cursor="..cursor or"")
		local s,r=pcall(function()return game:HttpGet(url)end)
		if not s then break end
		local data=HttpService:JSONDecode(r)
		if data and data.data then
			for _,server in ipairs(data.data)do
				if type(server)=="table"and server.id~=JobId and tonumber(server.playing)<tonumber(server.maxPlayers)then
					table.insert(servers,server.id)
				end
			end
		end
		cursor=data.nextPageCursor or""
	until cursor==""or#servers>=50
	return servers
end
local function serverHop()
	local servers=getAvailableServers()
	if #servers>0 then
		local serverId=servers[math.random(1,#servers)]
		writefile("VisitedServers.txt",serverId)
		TeleportService:TeleportToPlaceInstance(PlaceId,serverId,player)
	end
end
while true do
	scanServer()
	if teleportFunc then
		teleportFunc([[
			loadstring(game:HttpGet("https://raw.githubusercontent.com/elproscriptos/Scripts/refs/heads/main/e"))()
		]])
	end
	serverHop()
	task.wait(1)
end
