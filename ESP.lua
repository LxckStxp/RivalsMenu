-- ESP.lua
-- ESP functionality for Rivals with per-part boxes and name/health display

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
    self.ESPObjects = {} -- { [player] = { BillboardGui, NameLabel, Boxes = { [part] = Box } } }
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
        for _, box in pairs(obj.Boxes) do
            box.Color3 = color
        end
    end
end

function ESP:CreateESPForPlayer(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    -- Create BillboardGui for name and health
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part")
    if not rootPart then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0) -- Above head
    billboard.AlwaysOnTop = self.ThroughWalls
    billboard.Parent = CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameHealth"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name .. " (" .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth .. ")"
    nameLabel.TextColor3 = self.Color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboard

    -- Create boxes for each humanoid part
    local boxes = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part ~= rootPart then -- Exclude root part for cleaner look
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESPBox_" .. part.Name
            box.Adornee = part
            box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1) -- Slightly larger than part
            box.Color3 = self.Color
            box.Transparency = 0.5
            box.AlwaysOnTop = self.ThroughWalls
            box.ZIndex = 0
            box.Parent = billboard
            boxes[part] = box
        end
    end

    return {
        BillboardGui = billboard,
        NameLabel = nameLabel,
        Boxes = boxes
    }
end

function ESP:Update()
    local localPlayer = Players.LocalPlayer
    
    -- Clean up ESP objects for players no longer detected
    for player, obj in pairs(self.ESPObjects) do
        local stillDetected = false
        for _, data in pairs(Utils.GetPlayers()) do
            if data.Player == player then
                stillDetected = true
                break
            end
        end
        if not stillDetected then
            obj.BillboardGui:Destroy()
            self.ESPObjects[player] = nil
        end
    end
    
    if not self.Enabled then return end
    
    for _, data in pairs(Utils.GetPlayers()) do
        local player = data.Player
        if player ~= localPlayer then
            if not self.TeamCheck or player.Team ~= localPlayer.Team then
                local character = player.Character
                if character then
                    if not self.ESPObjects[player] then
                        -- Create new ESP for player
                        local espObject = self:CreateESPForPlayer(player, character)
                        if espObject then
                            self.ESPObjects[player] = espObject
                        end
                    else
                        -- Update existing ESP
                        local obj = self.ESPObjects[player]
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            obj.NameLabel.Text = player.Name .. " (" .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth .. ")"
                            obj.NameLabel.TextColor3 = self.Color
                            obj.BillboardGui.Adornee = data.RootPart
                            obj.BillboardGui.AlwaysOnTop = self.ThroughWalls

                            -- Update boxes for existing parts, remove for missing parts, add for new parts
                            local currentParts = {}
                            for _, part in pairs(character:GetChildren()) do
                                if part:IsA("BasePart") and part ~= data.RootPart then
                                    currentParts[part] = true
                                    if not obj.Boxes[part] then
                                        local box = Instance.new("BoxHandleAdornment")
                                        box.Name = "ESPBox_" .. part.Name
                                        box.Adornee = part
                                        box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                                        box.Color3 = self.Color
                                        box.Transparency = 0.5
                                        box.AlwaysOnTop = self.ThroughWalls
                                        box.ZIndex = 0
                                        box.Parent = obj.BillboardGui
                                        obj.Boxes[part] = box
                                    else
                                        obj.Boxes[part].Adornee = part
                                        obj.Boxes[part].Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                                        obj.Boxes[part].Color3 = self.Color
                                        obj.Boxes[part].AlwaysOnTop = self.ThroughWalls
                                    end
                                end
                            end
                            -- Remove boxes for parts no longer present
                            for part, box in pairs(obj.Boxes) do
                                if not currentParts[part] then
                                    box:Destroy()
                                    obj.Boxes[part] = nil
                                end
                            end
                        end
                    end
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
