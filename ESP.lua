-- ESP.lua
-- Sophisticated ESP for Rivals with per-part highlighting and enhanced visuals

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- ESP Configuration
local CONFIG = {
    BOX_TRANSPARENCY = 0.7,
    BOX_OUTLINE_THICKNESS = 1,
    NAME_SIZE = UDim2.new(0, 250, 0, 60),
    NAME_OFFSET = Vector3.new(0, 5, 0),
    HEALTH_BAR_HEIGHT = 8,
    DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)
}

function ESP.new()
    local self = setmetatable({}, ESP)
    self.Enabled = false
    self.TeamCheck = true
    self.ThroughWalls = true
    self.Color = CONFIG.DEFAULT_COLOR
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
    self.Boxes = {} -- { [part] = { Box, Outline } }
    self.Connection = nil
    self:Initialize()
    return self
end

function ESPObject:Initialize()
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart") or self.Character:FindFirstChildOfClass("Part")
    if not (humanoid and rootPart) then return end

    -- Create BillboardGui for name and health
    self.BillboardGui = Instance.new("BillboardGui")
    self.BillboardGui.Name = "ESP_" .. self.Player.Name
    self.BillboardGui.Adornee = rootPart
    self.BillboardGui.Size = CONFIG.NAME_SIZE
    self.BillboardGui.StudsOffset = CONFIG.NAME_OFFSET
    self.BillboardGui.AlwaysOnTop = self.ESPInstance.ThroughWalls
    self.BillboardGui.ClipsDescendants = true
    self.BillboardGui.Parent = CoreGui

    -- Name Label
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    self.NameLabel.Position = UDim2.new(0, 0, 0, 0)
    self.NameLabel.BackgroundTransparency = 1
    self.NameLabel.Text = self.Player.Name
    self.NameLabel.TextColor3 = self.ESPInstance.Color
    self.NameLabel.TextScaled = true
    self.NameLabel.Font = Enum.Font.SourceSansBold
    self.NameLabel.TextStrokeTransparency = 0.5
    self.NameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    self.NameLabel.Parent = self.BillboardGui

    -- Health Bar
    self.HealthBar = Instance.new("Frame")
    self.HealthBar.Size = UDim2.new(1, -10, 0, CONFIG.HEALTH_BAR_HEIGHT)
    self.HealthBar.Position = UDim2.new(0, 5, 0.6, 5)
    self.HealthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.HealthBar.BorderSizePixel = 0
    self.HealthBar.Parent = self.BillboardGui

    self.HealthFill = Instance.new("Frame")
    self.HealthFill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    self.HealthFill.Position = UDim2.new(0, 0, 0, 0)
    self.HealthFill.BackgroundColor3 = self.ESPInstance.Color
    self.HealthFill.BorderSizePixel = 0
    self.HealthFill.Parent = self.HealthBar

    -- Create boxes for each part
    self:UpdateBoxes()

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

function ESPObject:UpdateBoxes()
    local character = self.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part")
    if not rootPart then return end

    local currentParts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part ~= rootPart then
            currentParts[part] = true
            if not self.Boxes[part] then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox_" .. part.Name
                box.Adornee = part
                box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
                box.Color3 = self.ESPInstance.Color
                box.Transparency = CONFIG.BOX_TRANSPARENCY
                box.AlwaysOnTop = self.ESPInstance.ThroughWalls
                box.ZIndex = 1
                box.Parent = self.BillboardGui

                local outline = Instance.new("BoxHandleAdornment")
                outline.Name = "ESPOutline_" .. part.Name
                outline.Adornee = part
                outline.Size = part.Size + Vector3.new(0.3, 0.3, 0.3)
                outline.Color3 = Color3.new(0, 0, 0)
                outline.Transparency = 0
                outline.AlwaysOnTop = self.ESPInstance.ThroughWalls
                outline.ZIndex = 0
                outline.Parent = self.BillboardGui

                self.Boxes[part] = { Box = box, Outline = outline }
            end
        end
    end

    -- Remove boxes for parts no longer present
    for part, boxData in pairs(self.Boxes) do
        if not currentParts[part] then
            boxData.Box:Destroy()
            boxData.Outline:Destroy()
            self.Boxes[part] = nil
        end
    end
end

function ESPObject:Update()
    local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = self.Character:FindFirstChild("HumanoidRootPart") or self.Character:FindFirstChildOfClass("Part")
    if not (humanoid and rootPart) then return end

    -- Update name and health
    self.NameLabel.Text = self.Player.Name
    self.NameLabel.TextColor3 = self.ESPInstance.Color
    self.HealthFill.Size = UDim2.new(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 0, 1, 0)
    self.HealthFill.BackgroundColor3 = self.ESPInstance.Color

    -- Update BillboardGui properties
    self.BillboardGui.Adornee = rootPart
    self.BillboardGui.AlwaysOnTop = self.ESPInstance.ThroughWalls

    -- Update boxes
    for part, boxData in pairs(self.Boxes) do
        boxData.Box.Adornee = part
        boxData.Box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
        boxData.Box.Color3 = self.ESPInstance.Color
        boxData.Box.AlwaysOnTop = self.ESPInstance.ThroughWalls
        boxData.Outline.Adornee = part
        boxData.Outline.Size = part.Size + Vector3.new(0.3, 0.3, 0.3)
        boxData.Outline.AlwaysOnTop = self.ESPInstance.ThroughWalls
    end
end

function ESPObject:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.BillboardGui then
        self.BillboardGui:Destroy()
    end
    self.Boxes = {}
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
        for _, boxData in pairs(obj.Boxes) do
            boxData.Box.AlwaysOnTop = state
            boxData.Outline.AlwaysOnTop = state
        end
    end
end

function ESP:SetColor(color)
    self.Color = color
    print("ESP Color updated to: " .. tostring(color))
    for _, obj in pairs(self.ESPObjects) do
        obj.NameLabel.TextColor3 = color
        obj.HealthFill.BackgroundColor3 = color
        for _, boxData in pairs(obj.Boxes) do
            boxData.Box.Color3 = color
        end
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
                        -- Create or recreate ESP for new/changed character
                        if espObj then
                            espObj:Destroy()
                            self.ESPObjects[player] = nil
                        end
                        local newESP = ESPObject.new(player, character, self)
                        if newESP.BillboardGui then -- Ensure initialization succeeded
                            self.ESPObjects[player] = newESP
                            print("ESP created for: " .. player.Name)
                        end
                    else
                        -- Update existing ESP
                        espObj:Update()
                        espObj:UpdateBoxes() -- Ensure boxes stay in sync
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
