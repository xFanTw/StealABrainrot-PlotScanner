-- Plot Scanner Source - Steal a Brainrot

local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local lp = Players.LocalPlayer
while not lp do task.wait(0.1) end
while not lp:FindFirstChildOfClass("PlayerGui") do task.wait(0.1) end


local Packages     = ReplicatedStorage:WaitForChild("Packages")
local Datas        = ReplicatedStorage:WaitForChild("Datas")
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Utils        = ReplicatedStorage:WaitForChild("Utils")

local Synchronizer  = require(Packages:WaitForChild("Synchronizer"))
local AnimalsData   = require(Datas:WaitForChild("Animals"))
local AnimalsShared = require(Shared:WaitForChild("Animals"))
local NumberUtils   = require(Utils:WaitForChild("NumberUtils"))


local C = {
	bg      = Color3.fromRGB(13,  17,  23),
	card    = Color3.fromRGB(22,  27,  34),
	card2   = Color3.fromRGB(30,  35,  45),
	border  = Color3.fromRGB(48,  54,  61),
	accent  = Color3.fromRGB(220, 38,  38),
	cyan    = Color3.fromRGB(0,   229, 255),
	red     = Color3.fromRGB(248, 113, 113),
	yellow  = Color3.fromRGB(250, 204, 21),
	text    = Color3.fromRGB(230, 237, 243),
	text2   = Color3.fromRGB(139, 148, 158),
	text3   = Color3.fromRGB(88,  96,  105),
}


local function fmtGen(v)
	if not v or v == 0 then return "?" end
	
	local ok, str = pcall(function() return NumberUtils:ToString(v) end)
	if ok and type(str) == "string" and str ~= "" then
		return str
	end
	
	local function trunc1(n) return math.floor(n * 10) / 10 end
	if v >= 1e12 then return tostring(trunc1(v/1e12)) .. "T"
	elseif v >= 1e9 then return tostring(trunc1(v/1e9)) .. "B"
	elseif v >= 1e6 then return tostring(trunc1(v/1e6)) .. "M"
	elseif v >= 1e3 then return tostring(trunc1(v/1e3)) .. "K"
	end
	return tostring(math.floor(v))
end

local function getChannel(plotName)
	local ok, ch = pcall(function() return Synchronizer:Get(plotName) end)
	return ok and ch or nil
end

local function getPlotOwnerName(plot)
	
	local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
	if ok and ch then
		local owner = ch:Get("Owner")
		if owner then
			if typeof(owner) == "Instance" and owner:IsA("Player") then
				return owner.Name
			end
			if type(owner) == "table" and owner.Name then
				return owner.Name
			end
		end
	end

	local ok2, name = pcall(function()
		return plot.PlotSign.SurfaceGui.Frame.TextLabel.Text
	end)
	if ok2 and name and name ~= "" and not name:lower():find("^empty") then
		return name:gsub("'s Base$",""):gsub(" Base$",""):match("^%s*(.-)%s*$")
	end
	return ""
end

local function getPlotLabel(plot)
	local ok, name = pcall(function()
		return plot.PlotSign.SurfaceGui.Frame.TextLabel.Text
	end)
	if ok and name and name ~= "" then return name end
	return plot.Name
end


local function scanPlot(plot, ownerNick)
	local pets = {}
	local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
	if not ok or not ch then return pets end

	local animalList = ch:Get("AnimalList")
	if not animalList then return pets end

	for slot, entry in pairs(animalList) do
		if type(entry) ~= "table" or not entry.Index then continue end

		local info = AnimalsData[entry.Index]
		if not info then continue end

		local mut = entry.Mutation or "None"
		if mut == "Yin Yang" then mut = "YinYang" end


		local gv = 0
		if type(entry.Generation) == "number" and entry.Generation > 0 then
			gv = entry.Generation
		elseif type(entry.Cash) == "number" and entry.Cash > 0 then
			gv = entry.Cash
		else
			local ok2, g = pcall(function()
				return AnimalsShared:GetGeneration(entry.Index, entry.Mutation, entry.Traits, nil)
			end)
			if ok2 and g then gv = g end
		end
		if gv <= 0 then continue end
		task.wait()

		local traits = {}
		if type(entry.Traits) == "table" then
			for _, t in ipairs(entry.Traits) do
				table.insert(traits, tostring(t))
			end
		end

		table.insert(pets, {
			name               = info.DisplayName or entry.Index,
			gen_value          = gv,
			generation_display = "$" .. fmtGen(gv) .. "/s",
			rarity             = info.Rarity or "",
			mutation           = mut,
			traits             = traits,
			account            = ownerNick or "",
			slot               = tostring(slot),
			uuid               = entry.UUID or "",
		})
	end

	table.sort(pets, function(a, b) return a.gen_value > b.gen_value end)
	return pets
end


local function countPets(plot)
	local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
	if not ok or not ch then return 0 end
	local animalList = ch:Get("AnimalList")
	if not animalList then return 0 end
	local count = 0
	for _, entry in pairs(animalList) do
		if type(entry) == "table" and entry.Index and AnimalsData[entry.Index] then
			count = count + 1
		end
	end
	return count
end

local function getAllPlots()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return {} end
	local list = {}
	for _, p in ipairs(plots:GetChildren()) do
		local owner = getPlotOwnerName(p)
		table.insert(list, { plot=p, label=getPlotLabel(p), owner=owner, enabled=false })
	end
	table.sort(list, function(a, b)
		local aOcc = a.owner ~= ""
		local bOcc = b.owner ~= ""
		if aOcc ~= bOcc then return aOcc end
		return a.owner < b.owner
	end)
	return list
end


local function mk(cls, props, parent)
	local i = Instance.new(cls)
	for k,v in pairs(props or {}) do i[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function corner(r, p) mk("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end
local function pad(l,r,t,b,p)
	local x=mk("UIPadding",{},p)
	x.PaddingLeft=UDim.new(0,l or 0); x.PaddingRight=UDim.new(0,r or 0)
	x.PaddingTop=UDim.new(0,t or 0); x.PaddingBottom=UDim.new(0,b or 0)
end

local old = lp.PlayerGui:FindFirstChild("RobloxGui_Internal")
if old then old:Destroy() end

local sg = mk("ScreenGui",{Name="RobloxGui_Internal",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},lp.PlayerGui)

local win = mk("Frame",{
	Size=UDim2.new(0,360,0,480),
	Position=UDim2.new(0.5,-180,0.5,-240),
	BackgroundColor3=C.bg, BorderSizePixel=0,
	Active=true, Draggable=true,
},sg)
corner(10,win)
mk("UIStroke",{Color=C.border,Thickness=1},win)

local bar = mk("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.card,BorderSizePixel=0},win)
corner(10,bar)
mk("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.card,BorderSizePixel=0},bar)
mk("UIStroke",{Color=C.border,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},bar)
mk("Frame",{Size=UDim2.new(0,3,0,24),Position=UDim2.new(0,14,0,10),BackgroundColor3=C.accent,BorderSizePixel=0},bar)
mk("TextLabel",{
	Size=UDim2.new(1,-80,1,0),Position=UDim2.new(0,24,0,0),
	BackgroundTransparency=1,Text="Heresy Plot Scanner",
	TextColor3=C.text,TextSize=13,Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left,
},bar)
local closeBt = mk("TextButton",{
	Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-36,0,9),
	BackgroundColor3=C.card2,Text="✕",TextColor3=C.text2,
	TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0,AutoButtonColor=false,
},bar)
corner(6,closeBt)
closeBt.MouseButton1Click:Connect(function() sg:Destroy() end)

local body = mk("Frame",{
	Size=UDim2.new(1,-20,1,-54),Position=UDim2.new(0,10,0,50),
	BackgroundTransparency=1,BorderSizePixel=0,
},win)

mk("TextLabel",{
	Size=UDim2.new(1,0,0,18),
	BackgroundTransparency=1,
	Text="BASES  ·  selecione uma ou mais",
	TextColor3=C.text3,TextSize=10,Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left,
},body)

local countBadge = mk("TextLabel",{
	Size=UDim2.new(0,60,0,18),Position=UDim2.new(1,-60,0,0),
	BackgroundTransparency=1,Text="",
	TextColor3=C.accent,TextSize=10,Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Right,
},body)

local scroll = mk("ScrollingFrame",{
	Size=UDim2.new(1,0,0,252),Position=UDim2.new(0,0,0,24),
	BackgroundColor3=C.card,BorderSizePixel=0,
	ScrollBarThickness=3,ScrollBarImageColor3=C.accent,
	CanvasSize=UDim2.new(0,0,0,0),ClipsDescendants=true,
},body)
corner(8,scroll)
mk("UIStroke",{Color=C.border,Thickness=1},scroll)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},scroll)
pad(4,4,4,4,scroll)

mk("Frame",{
	Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,284),
	BackgroundColor3=C.border,BorderSizePixel=0,
},body)

local statusLbl = mk("TextLabel",{
	Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,292),
	BackgroundTransparency=1,Text="Carregando plots...",
	TextColor3=C.text2,TextSize=11,Font=Enum.Font.Gotham,
	TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
},body)

local copyBt = mk("TextButton",{
	Size=UDim2.new(1,0,0,38),Position=UDim2.new(0,0,0,330),
	BackgroundColor3=C.accent,Text="Copiar JSON",
	TextColor3=Color3.fromRGB(0,0,0),TextSize=13,Font=Enum.Font.GothamBold,
	BorderSizePixel=0,AutoButtonColor=false,
},body)
corner(8,copyBt)
copyBt.MouseEnter:Connect(function() copyBt.BackgroundColor3=Color3.fromRGB(239,68,68) end)
copyBt.MouseLeave:Connect(function() copyBt.BackgroundColor3=C.accent end)

local refBt = mk("TextButton",{
	Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,374),
	BackgroundColor3=C.card,Text="↻  Atualizar lista",
	TextColor3=C.text2,TextSize=11,Font=Enum.Font.Gotham,
	BorderSizePixel=0,AutoButtonColor=false,
},body)
corner(6,refBt)
mk("UIStroke",{Color=C.border,Thickness=1},refBt)
refBt.MouseEnter:Connect(function() refBt.BackgroundColor3=C.card2 end)
refBt.MouseLeave:Connect(function() refBt.BackgroundColor3=C.card end)


local plotRows = {}

local function getSelectedCount()
	local n = 0
	for _, r in ipairs(plotRows) do if r.enabled then n = n + 1 end end
	return n
end

local function updateBadge()
	local n = getSelectedCount()
	countBadge.Text = n > 0 and (n .. " selecionada" .. (n>1 and "s" or "")) or ""
end

local function refreshPlots()
	for _, r in ipairs(plotRows) do r.row:Destroy() end
	plotRows = {}
	statusLbl.TextColor3 = C.text2
	statusLbl.Text = "Carregando..."

	local list = getAllPlots()
	if #list == 0 then
		statusLbl.Text = "Nenhuma base encontrada."
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		updateBadge()
		return
	end

	for i, entry in ipairs(list) do
		if i % 4 == 0 then task.wait(0.05) end 
		local petCount = countPets(entry.plot)

		local row = mk("Frame",{
			Size=UDim2.new(1,0,0,44),
			BackgroundColor3=C.card, BorderSizePixel=0, LayoutOrder=i,
		},scroll)
		corner(6,row)

		local toggleBg = mk("Frame",{
			Size=UDim2.new(0,36,0,20),
			Position=UDim2.new(0,8,0.5,-10),
			BackgroundColor3=C.card2, BorderSizePixel=0,
		},row)
		corner(10,toggleBg)
		mk("UIStroke",{Color=C.border,Thickness=1},toggleBg)
		local pill = mk("Frame",{
			Size=UDim2.new(0,14,0,14),
			Position=UDim2.new(0,3,0.5,-7),
			BackgroundColor3=C.text3, BorderSizePixel=0,
		},toggleBg)
		corner(7,pill)

		local nameCol = mk("Frame",{
			Size=UDim2.new(1,-100,1,0),
			Position=UDim2.new(0,54,0,0),
			BackgroundTransparency=1,
		},row)
		local nameLbl = mk("TextLabel",{
			Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),
			BackgroundTransparency=1, Text=entry.label,
			TextColor3=C.text2, TextSize=11, Font=Enum.Font.GothamBold,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},nameCol)
		local ownerLbl = mk("TextLabel",{
			Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,22),
			BackgroundTransparency=1,
			Text=entry.owner ~= "" and ("@"..entry.owner) or "",
			TextColor3=C.text3, TextSize=9, Font=Enum.Font.Gotham,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},nameCol)

		mk("TextLabel",{
			Size=UDim2.new(0,50,1,0),Position=UDim2.new(1,-58,0,0),
			BackgroundTransparency=1,
			Text=petCount.." pets",
			TextColor3= petCount > 0 and C.accent or C.text3,
			TextSize=10,Font=Enum.Font.Gotham,
			TextXAlignment=Enum.TextXAlignment.Right,
		},row)

		local rEntry = { entry=entry, row=row, enabled=false }
		table.insert(plotRows, rEntry)

		local clickArea = mk("TextButton",{
			Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,
		},row)
		clickArea.MouseButton1Click:Connect(function()
			rEntry.enabled = not rEntry.enabled
			if rEntry.enabled then
				for _, c in ipairs(toggleBg:GetChildren()) do
					if c:IsA("UIStroke") then c.Color=C.accent end
				end
				toggleBg.BackgroundColor3 = Color3.fromRGB(80,20,20)
				pill.Position = UDim2.new(1,-17,0.5,-7)
				pill.BackgroundColor3 = C.accent
				nameLbl.TextColor3 = C.text
				ownerLbl.TextColor3 = C.accent
				row.BackgroundColor3 = Color3.fromRGB(40,20,20)
			else
				for _, c in ipairs(toggleBg:GetChildren()) do
					if c:IsA("UIStroke") then c.Color=C.border end
				end
				toggleBg.BackgroundColor3 = C.card2
				pill.Position = UDim2.new(0,3,0.5,-7)
				pill.BackgroundColor3 = C.text3
				nameLbl.TextColor3 = C.text2
				ownerLbl.TextColor3 = C.text3
				row.BackgroundColor3 = C.card
			end
			updateBadge()
			statusLbl.TextColor3 = C.text2
			statusLbl.Text = getSelectedCount() .. " base(s) selecionada(s)"
		end)
	end

	scroll.CanvasSize = UDim2.new(0,0,0, #list*45+8)
	statusLbl.Text = #list .. " bases encontradas"
	updateBadge()
end


copyBt.MouseButton1Click:Connect(function()
	local selected = {}
	for _, r in ipairs(plotRows) do
		if r.enabled then table.insert(selected, r.entry) end
	end

	if #selected == 0 then
		statusLbl.TextColor3 = C.yellow
		statusLbl.Text = "Selecione ao menos uma base."
		return
	end

	copyBt.Text = "Escaneando..."
	copyBt.BackgroundColor3 = C.card2
	copyBt.TextColor3 = C.text2
	task.wait(0.05)

	local allPets = {}
	for idx, entry in ipairs(selected) do
		if idx > 1 then task.wait(0.1) end 
		local ok, pets = pcall(scanPlot, entry.plot, entry.owner)
		if ok and pets then
			for _, p in ipairs(pets) do
				table.insert(allPets, p)
			end
		end
	end

	table.sort(allPets, function(a,b) return a.gen_value > b.gen_value end)

	copyBt.Text = "Copy JSON"
	copyBt.BackgroundColor3 = C.accent
	copyBt.TextColor3 = Color3.fromRGB(0,0,0)

	if #allPets == 0 then
		statusLbl.TextColor3 = C.yellow
		statusLbl.Text = "Nenhum pet encontrado nas bases selecionadas."
		return
	end

	local json = HttpService:JSONEncode(allPets)
	if setclipboard then
		setclipboard(json)
		statusLbl.TextColor3 = C.accent
		statusLbl.Text = "✓ " .. #allPets .. " pets copiados! Cole no Auto List."
	else
		writefile("heresy_scan.json", json)
		statusLbl.TextColor3 = C.accent
		statusLbl.Text = "✓ Salvo: heresy_scan.json (" .. #allPets .. " pets)"
	end
end)

refBt.MouseButton1Click:Connect(refreshPlots)
refreshPlots()
