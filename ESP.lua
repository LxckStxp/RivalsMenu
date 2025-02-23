-- ESP.lua
-- ESP functionality for Rivals with database-driven detection and 3D GUI visualization

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

function ESP.new()
    local self = setmetatable({}, ESP)
    self.Enabled = false
    self.TeamCheck = true
    self.ThroughWalls = true
    self.Color = Color3.fromRGB(255, 0, 0) -- Default red
    self.ESPObjects = {} -- { [player] = { BillboardGui, Box } }
    self.Connection = nil
    return self
end

function ESP:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("ESP enabled.")
    
    self.Connection = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function ESP:Disable()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    for _, obj in pairs(self.ESPObjects) do
        obj.BillboardGui:Destroy()
    end
    self.ESPObjects = {}
    print("ESP disabled.")
end

function ESP:SetTeamCheck(state)
    self.TeamCheck = state
    print("ESP Team Check set to: " .. tostring(state))
    self:Update()
end

function ESP:SetThroughWalls(state)
    self.ThroughWalls = state
    print("ESP Through Walls set to: " .. tostring(state))
    self:Update()
end

function ESP:SetColor(color)
    self.Color = color
    print("ESP Color updated to: " .. tostring(color))
    for _, obj in pairs(self.ESPObjects) do
        obj.Box.Color3 = color
    end
end

function ESP:Update()
    local localPlayer = Players.LocalPlayer
    
    -- Clean up existing ESP objects for players no longer detected
    for player, obj in pairs(self.ESPObjects) do
        if not Utils.GetPlayers()[player] then
            obj.BillboardGui:Destroy()
            self.ESPObjects[player] = nil
        end
    end
    
    if not self.Enabled then return end
    
    for _, data in pairs(Utils.GetPlayers()) do
        local player = data.Player
        if player ~= localPlayer then
            if not self.TeamCheck or player.Team ~= localPlayer.Team then
                if not self.ESPObjects[player] then
                    -- Create new ESP object if not already present
                    local rootPart = data.RootPart
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ESP_" .. player.Name
                    billboard.Adornee = rootPart
                    billboard.Size = UDim2.new(0, 100, 0, 100)
                    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Above player's head
                    billboard.AlwaysOnTop = self.ThroughWalls
                    billboard.Parent = CoreGui
                    
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "ESPBox"
                    box.Adornee = rootPart
                    box.Size = Vector3.new(4, 6, 4) -- Width, height, depth
                    box.Color3 = self.Color
                    box.Transparency = 0.5
                    box.AlwaysOnTop = self.ThroughWalls
                    box.ZIndex = 0
                    box.Parent = billboard
                    
                    self.ESPObjects[player] = {
                        BillboardGui = billboard,
                        Box = box
                    }
                else
                    -- Update existing ESP object
                    local obj = self.ESPObjects[player]
                    obj.BillboardGui.Adornee = data.RootPart
                    obj.BillboardGui.AlwaysOnTop = self.ThroughWalls
                    obj.Box.Adornee = data.RootPart
                    obj.Box.Color3 = self.Color
                    obj.Box.AlwaysOnTop = self.ThroughWalls
                end
            end
        end
    end
end

function ESP:Destroy()
    self:Disable()
    self.ESPObjects = {}
    print("ESP instance destroyed.")
end

return ESP
