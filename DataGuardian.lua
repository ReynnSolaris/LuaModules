local m = {}

local SlotExample = {

}

local SampleData = {
	Slot1 = SlotExample,
}

function TableToFolder(r, Table)
	local Main = Instance.new("Folder", game.ReplicatedStorage:WaitForChild("PlayerData"))
	Main.Name = tostring(r)
	function Search(par, tb)
		for x, v in pairs(tb) do
			local b = nil
			if typeof(v) == "table" then
				local T = Instance.new("Folder", par)
				T.Name = tostring(x)
				Search(T, v)
			elseif typeof(v) == "boolean" then
				b = Instance.new("BoolValue", par)
			elseif typeof(v) == "string" then
				b = Instance.new("StringValue", par)
			elseif typeof(v) == "number" then
				b = Instance.new("NumberValue", par)
			end
			if b ~= nil then
				b.Name = tostring(x)
				b.Value = v
				--b.Changed:connect(function(val)
				--	tb[b.Name] = val
				--	print(tostring(b.Name), tostring(x), tostring(v), tostring(par))
				--end)
			end
		end
	end
	Search(Main, Table)
	return Main
end

local folderToTable = function(folder)
	local main = {}
	function Search(last, par)
		for _, x in next, par:GetChildren() do
			if x:IsA'Folder' then
				last[x.Name] = {}
				Search(last[x.Name] , x)
			else
				last[x.Name] = x.Value
			end
		end
	end
	Search(main, folder)
	return main
end

function m.InitDatastore(...)
	local args = {...}
	local f = Instance.new("Folder", game.ServerStorage)
	f.Name = "PlayerData"
	f:Clone().Parent = game.ReplicatedStorage
	print("Successfully created datastore: ["..(args[1] ~= nil and args[1] or "GlobalData").."]")
	return setmetatable({
		["DS"] = game:GetService("DataStoreService"):GetDataStore(args[1] ~= nil and args[1] or "GlobalData")
	},{
		__index = function(self, index)
			if m[index] ~= nil then
				if typeof(m[index]) == "function" then
					return function(self, ...)
						return m[index](self, ...)
					end
				else
					return m[index]
				end
			end
		end
	})
end

function m:LoadData(P, wipedata)
	local f = game.ServerStorage:FindFirstChild("PlayerData")
	if not f then
		return
	end
	print(wipedata)
	local d = script.DataTemplate:Clone()
	d.Parent = f
	d.Name = tostring(P)
	local data = self.DS:GetAsync(P.UserId)
	if data == nil then
		data = SampleData
		print("Created new data")
	end
	if wipedata then
		if data["WipeData"] ~= nil then
			if wipedata ~= data.WipeData then
				print("Data was wiped.")
				data = SampleData
			end
		else
			data = SampleData
			print("Data was wiped.")
		end
		data.WipeData = wipedata
	end
	local mod = require(d)
	for x, v in pairs(data) do
		mod[x] = v
	end
	
	TableToFolder(P, mod)
	print("Successfully init: "..tostring(P))
	return d
end

function m:SaveData(P)
	print("Saving Data for: "..tostring(P))
	local mod = self:RetrieveData(P)
	local data = require(mod)
	local dataa = game.ReplicatedStorage.PlayerData:FindFirstChild(tostring(P))
	if dataa then
		data = folderToTable(dataa)
		dataa:Destroy()
	end
	self.DS:SetAsync(P.UserId, data)
	mod:Destroy()
end

function m:RetrieveData(P)
	local f = game.ServerStorage:FindFirstChild("PlayerData")
	if not f then
		return
	end
	return f:FindFirstChild(tostring(P)), game.ReplicatedStorage.PlayerData:FindFirstChild(tostring(P))
end

function m:AddToTable(P, tbl, var, val)
	local d, f = self:RetrieveData(P)
	if d and f then
		local b = nil
		local tb = require(d)[tbl]
		tb[var] = val
		local par = f:FindFirstChild(tbl)
		if typeof(val) == "boolean" then
			b = Instance.new("BoolValue", par)
		elseif typeof(val) == "string" then
			b = Instance.new("StringValue", par)
		elseif typeof(val) == "number" then
			b = Instance.new("NumberValue", par)
		end
		if b ~= nil then
			b.Name = tostring(var)
			b.Value = val
			b.Changed:connect(function(val)
				tb[b.Name] = val
			end)
		end
	end
end


return m