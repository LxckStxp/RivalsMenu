-- ESP.lua
-- Sophisticated ESP for Rivals with sleek, modern visuals and error handling

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- ESP Configuration
local CONFIG = {
    BOX_COLOR = Color3.fromRGB(255, 50, 50), -- Vibrant red
    OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    BOX_TRANSPARENCY = 0.6,
    NAME_SIZE = UDim2.new(0, 200, 0, 40),
    NAME_OFFSET = Vector3.new(0, 3.5, 0),
    HEALTH_BAR_WIDTH = 4,
    HEALTH_BAR_COLOR = Color3.fromRGB(50, 255, 50), -- Green for health
    TEXT_COLOR = Color3.fromRGB(255, 255, 255)
}

function ESP.new()
    local self = setmetatable({}, ESP)
    self.Enabled = false
    self.TeamCheck = true
    self.ThroughWalls = true
    self.Color = CONFIG.BOX_COLOR
    self.ESPObjects = {} -- { [player] = ESPObject }
    self.Connection = nil
    return self
end

-- ESP Object for individual players
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player, character, espInstance)
    local self = setmetatable({}, ESPObject)
    self.Player = player
    self.Character = character
    self.ESPInstance = espInstance
    self.BillboardGui = nil
    self.NameLabel = nil
    self.HealthBar = nil
    self.HealthFill = nil
    self.Box = nil
    self.Outline = nil
    self.Connection = nil
    self:Initialize()
    return self
end

function ESPObject:Initialize()
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart") or self.Character:FindFirstChildOfClass("Part")
    if not (humanoid and rootPart) then
        warn("Failed to initialize ESP for " .. self.Player.Name .. ": Missing humanoid or root part")
        return
    end

    -- Create BillboardGui for name and health
    self.BillboardGui = Instance.new("BillboardGui")
    self.BillboardGui.Name = "ESP_" .. self.Player.Name
    self.BillboardGui.Adornee = rootPart
    self.BillboardGui.Size = CONFIG.NAME_SIZE
    self.BillboardGui.StudsOffset = CONFIG.NAME_OFFSET
    self.BillboardGui.AlwaysOnTop = self.ESPInstance.ThroughWalls
    self.BillboardGui.ClipsDescendants = true
    self.BillboardGui.Parent = CoreGui

    -- Name Label with background
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Size = UDim2.new(1, 0, 1, 0)
    self.NameLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.NameLabel.BackgroundTransparency = 0.7
    self.NameLabel.Text = self.Player.Name
    self.NameLabel.TextColor3 = CONFIG.TEXT_COLOR
    self.NameLabel.TextScaled = true
    self.NameLabel.Font = Enum.Font.GothamBold
    self.NameLabel.TextStrokeTransparency = 0.3
    self.NameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    self.NameLabel.BorderSizePixel = 0
    self.NameLabel.Parent = self.BillboardGui

    -- Health Bar (vertical on the left)
    local height = self:GetCharacterHeight()
    self.HealthBar = Instance.new("Frame")
    self.HealthBar.Size = UDim2.new(0, CONFIG.HEALTH_BAR_WIDTH, 0, height * 10)
    self.HealthBar.Position = UDim2.new(-0.2, -CONFIG.HEALTH_BAR_WIDTH - 2, 0.5, -height * 5)
    self.HealthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.HealthBar.BorderSizePixel = 0
    self.HealthBar.Parent = self.BillboardGui

    self.HealthFill = Instance.new("Frame")
    self.HealthFill.Size = UDim2.new(1, 0, math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 0)
    self.HealthFill.Position = UDim2.new(0, 0, 1, 0)
    self.HealthFill.AnchorPoint = Vector2.new(0, 1)
    self.HealthFill.BackgroundColor3 = CONFIG.HEALTH_BAR_COLOR
    self.HealthFill.BorderSizePixel = 0
    self.HealthFill.Parent = self.HealthBar

    -- Single outline box around character
    local boxSize = self:GetCharacterBounds()
    self.Box = Instance.new("BoxHandleAdornment")
    self.Box.Name = "ESPBox"
    self.Box.Adornee = rootPart
    self.Box.Size = boxSize + Vector3.new(0.5, 0.5, 0.5)
    self.Box.Color3 = self.ESPInstance.Color
    self.Box.Transparency = CONFIG.BOX_TRANSPARENCY
    self.Box.AlwaysOnTop = self.ESPInstance.ThroughWalls
    self.Box.ZIndex = 1
    self.Box.Parent = self.BillboardGui

    self.Outline = Instance.new("BoxHandleAdornment")
    self.Outline.Name = "ESPOutline"
    self.Outline.Adornee = rootPart
    self.Outline.Size = boxSize + Vector3.new(0.7, 0.7, 0.7)
    self.Outline.Color3 = CONFIG.OUTLINE_COLOR
    self.Outline.Transparency = 0
    self.Outline.AlwaysOnTop = self.ESPInstance.ThroughWalls
    self.Outline.ZIndex = 0
    self.Outline.Parent = self.BillboardGui

    -- Handle respawn
    self.Connection = self.Player.CharacterAdded:Connect(function(newChar)
        self:Destroy()
        if self.ESPInstance.Enabled then
            local newESP = ESPObject.new(self.Player, newChar, self.ESPInstance)
            self.ESPInstance.ESPObjects[self.Player] = newESP
            print("ESP respawned for: " .. self.Player.Name)
        end
    end)
end

function ESPObject:GetCharacterHeight()
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 6 end -- Default height if no humanoid
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart")
    local head = self.Character:FindFirstChild("Head")
    if rootPart and head then
        return (head.Position - rootPart.Position).Y * 1.2 -- Approximate height with buffer
    end
    return 6 -- Fallback
end

function ESPObject:GetCharacterBounds()
    local parts = {}
    for _, part in pairs(self.Character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return Vector3.new(4, 6, 4) end -- Default size

    local minPos, maxPos = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, part in pairs(parts) do
        local pos = part.Position
        local size = part.Size / 2
        minPos = Vector3.new(math.min(minPos.X, pos.X - size.X), math.min(minPos.Y, pos.Y - size.Y), math.min(minPos.Z, pos.Z - size.Z))
        maxPos = Vector3.new(math.max(maxPos.X, pos.X + size.X), math.max(maxPos.Y, pos.Y + size.Y), math.max(maxPos.Z, pos.Z + size.Z))
    end
    return maxPos - minPos
end

function ESPObject:Update()
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart") or self.Character:FindFirstChildOfClass("Part")
    if not (humanoid and rootPart and self.BillboardGui and self.NameLabel and self.HealthFill and self.Box and self.Outline) then
        print("Skipping ESP update for " .. self.Player.Name .. " due to missing components")
        return
    end

    -- Update name and health
    self.NameLabel.Text = self.Player.Name
    self.HealthFill.Size = UDim2.new(1, 0, math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 0)

    -- Update BillboardGui properties
    self.BillboardGui.Adornee = rootPart
    self.BillboardGui.AlwaysOnTop = self.ESPInstance.ThroughWalls

    -- Update box and outline
    local boxSize = self:GetCharacterBounds()
    self.Box.Adornee = rootPart
    self.Box.Size = boxSize + Vector3.new(0.5, 0.5, 0.5)
    self.Box.Color3 = self.ESPInstance.Color
    self.Box.AlwaysOnTop = self.ESPInstance.ThroughWalls
    self.Outline.Adornee = rootPart
    self.Outline.Size = boxSize + Vector3.new(0.7, 0.7, 0.7)
    self.Outline.AlwaysOnTop = self.ESPInstance.ThroughWalls
end

function ESPObject:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.BillboardGui then
        self.BillboardGui:Destroy()
    end
end

-- Main ESP Methods
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
        obj:Destroy()
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
    for _, obj in pairs(self.ESPObjects) do
        obj.BillboardGui.AlwaysOnTop = state
        obj.Box.AlwaysOnTop = state
        obj.Outline.AlwaysOnTop = state
    end
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
    
    -- Remove ESP for players no longer detected
    for player, obj in pairs(self.ESPObjects) do
        local stillDetected = false
        for _, data in pairs(Utils.GetPlayers()) do
            if data.Player == player then
                stillDetected = true
                break
            end
        end
        if not stillDetected then
            obj:Destroy()
            self.ESPObjects[player] = nil
            print("ESP removed for: " .. player.Name)
        end
    end
    
    if not self.Enabled then return end
    
    for _, data in pairs(Utils.GetPlayers()) do
        local player = data.Player
        if player ~= localPlayer then
            if not self.TeamCheck or player.Team ~= localPlayer.Team then
                local character = player.Character
                if character then
                    local espObj = self.ESPObjects[player]
                    if not espObj or espObj.Character ~= character then
                        if espObj then
                            espObj:Destroy()
                            self.ESPObjects[player] = nil
                        end
                        local newESP = ESPObject.new(player, character, self)
                        if newESP.BillboardGui then
                            self.ESPObjects[player] = newESP
                            print("ESP created for: " .. player.Name)
                        end
                    else
                        espObj:Update()
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
