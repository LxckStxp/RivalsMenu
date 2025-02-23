-- ESP.lua
-- Sophisticated ESP for Rivals with 2D boxes and 3D BillboardGui for name/health

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- ESP Configuration
local CONFIG = {
    BOX_COLOR = Color3.fromRGB(255, 50, 50), -- Vibrant red
    OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    BOX_THICKNESS = 2,
    BOX_PADDING = 2,
    NAME_SIZE = UDim2.new(0, 220, 0, 50),
    NAME_OFFSET = Vector3.new(0, 3.5, 0),
    HEALTH_BAR_WIDTH = 8,
    HEALTH_BAR_HEIGHT = 6,
    HEALTH_BAR_COLOR_START = Color3.fromRGB(50, 255, 50), -- Green for full health
    HEALTH_BAR_COLOR_END = Color3.fromRGB(255, 50, 50), -- Red for low health
    MAX_DISTANCE = 800, -- Maximum distance (studs) for ESP visibility
    MIN_BOX_SIZE = 20 -- Minimum box size in pixels to ensure readability
}

function ESP.new()
    local self = setmetatable({}, ESP)
    self.Enabled = false
    self.TeamCheck = true
    self.ThroughWalls = true
    self.Color = CONFIG.BOX_COLOR
    self.ESPObjects = {} -- { [player] = { Box, Outline, BillboardGui, NameLabel, HealthBar, HealthFill } }
    self.Connection = nil
    return self
end

function ESP:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("ESP enabled with 2D boxes and 3D BillboardGui.")
    
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
        obj.Box:Remove()
        obj.Outline:Remove()
        if obj.BillboardGui then obj.BillboardGui:Destroy() end
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
        obj.Box.Color = color
        if obj.NameLabel then obj.NameLabel.TextColor3 = color end
        if obj.HealthFill then obj.HealthFill.BackgroundColor3 = self:GetHealthColor(obj.Character:FindFirstChildOfClass("Humanoid")) end
    end
end

function ESP:CreateESPForPlayer(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part")
    if not (humanoid and rootPart) then
        warn("Failed to create ESP for " .. player.Name .. ": Missing humanoid or root part")
        return
    end

    local box = Drawing.new("Square")
    box.Thickness = CONFIG.BOX_THICKNESS
    box.Color = self.Color
    box.Filled = false
    box.Visible = false

    local outline = Drawing.new("Square")
    outline.Thickness = CONFIG.BOX_THICKNESS + 1
    outline.Color = CONFIG.OUTLINE_COLOR
    outline.Filled = false
    outline.Visible = false

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard_" .. player.Name
    billboard.Adornee = rootPart
    billboard.Size = CONFIG.NAME_SIZE
    billboard.StudsOffset = CONFIG.NAME_OFFSET
    billboard.AlwaysOnTop = self.ThroughWalls
    billboard.ClipsDescendants = true
    billboard.Parent = CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    nameLabel.BackgroundTransparency = 0.6
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = CONFIG.TEXT_COLOR
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.BorderSizePixel = 0
    nameLabel.Parent = billboard

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, -10, 0, CONFIG.HEALTH_BAR_HEIGHT)
    healthBar.Position = UDim2.new(0, 5, 0.5, 5)
    healthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = billboard

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 0, 0)
    healthFill.BackgroundColor3 = self:GetHealthColor(humanoid)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBar

    return {
        Box = box,
        Outline = outline,
        BillboardGui = billboard,
        NameLabel = nameLabel,
        HealthBar = healthBar,
        HealthFill = healthFill,
        Character = character
    }
end

function ESP:GetCharacterBounds(character)
    local parts = {}
    for _, part in pairs(character:GetChildren()) do
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

function ESP:GetHealthColor(humanoid)
    if not humanoid or humanoid.Health <= 0 then return CONFIG.HEALTH_BAR_COLOR_END end
    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    return Color3.fromRGB(
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.R * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.R * (1 - healthPercent)),
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.G * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.G * (1 - healthPercent)),
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.B * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.B * (1 - healthPercent))
    )
end

function ESP:Update()
    local localPlayer = Players.LocalPlayer
    local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- Clean up ESP for players no longer detected
    for player, obj in pairs(self.ESPObjects) do
        local stillDetected = false
        for _, data in pairs(Utils.GetPlayers()) do
            if data.Player == player then
                stillDetected = true
                break
            end
        end
        if not stillDetected then
            obj.Box:Remove()
            obj.Outline:Remove()
            if obj.BillboardGui then obj.BillboardGui:Destroy() end
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
                local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part"))
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not (humanoid and rootPart) then continue end

                -- Check distance (800 studs max)
                if localRoot then
                    local distance = (rootPart.Position - localRoot.Position).Magnitude
                    if distance > CONFIG.MAX_DISTANCE then
                        local obj = self.ESPObjects[player]
                        if obj then
                            obj.Box.Visible = false
                            obj.Outline.Visible = false
                            if obj.BillboardGui then
                                obj.BillboardGui.Enabled = false
                            end
                        end
                        continue
                    else
                        local obj = self.ESPObjects[player]
                        if obj and obj.BillboardGui then
                            obj.BillboardGui.Enabled = true
                        end
                    end
                end

                local espObj = self.ESPObjects[player]
                if not espObj or espObj.Character ~= character then
                    -- Create or recreate ESP for new/changed character
                    if espObj then
                        espObj.Box:Remove()
                        espObj.Outline:Remove()
                        if espObj.BillboardGui then espObj.BillboardGui:Destroy() end
                    end
                    local newESP = self:CreateESPForPlayer(player, character)
                    if newESP then
                        self.ESPObjects[player] = newESP
                        print("ESP created for: " .. player.Name)
                    end
                else
                    -- Update existing ESP
                    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    if not onScreen and not self.ThroughWalls then
                        espObj.Box.Visible = false
                        espObj.Outline.Visible = false
                        if espObj.BillboardGui then
                            espObj.BillboardGui.Enabled = false
                        end
                        continue
                    end

                    -- Calculate box size based on character bounds
                    local bounds = self:GetCharacterBounds(character)
                    local sizeY = math.max((Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, bounds.Y / 2, 0)).Y -
                                         Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, bounds.Y / 2, 0)).Y) or CONFIG.MIN_BOX_SIZE, CONFIG.MIN_BOX_SIZE)
                    local sizeX = math.max(sizeY * (bounds.X / bounds.Y) or CONFIG.MIN_BOX_SIZE, CONFIG.MIN_BOX_SIZE)
                    local pos2D = Vector2.new(pos.X, pos.Y)

                    -- Box and outline
                    espObj.Box.Position = Vector2.new(pos2D.X - sizeX / 2 - CONFIG.BOX_PADDING, pos2D.Y - sizeY / 2 - CONFIG.BOX_PADDING)
                    espObj.Box.Size = Vector2.new(sizeX + CONFIG.BOX_PADDING * 2, sizeY + CONFIG.BOX_PADDING * 2)
                    espObj.Box.Visible = true
                    espObj.Outline.Position = Vector2.new(pos2D.X - sizeX / 2 - CONFIG.BOX_PADDING - 1, pos2D.Y - sizeY / 2 - CONFIG.BOX_PADDING - 1)
                    espObj.Outline.Size = Vector2.new(sizeX + CONFIG.BOX_PADDING * 2 + 2, sizeY + CONFIG.BOX_PADDING * 2 + 2)
                    espObj.Outline.Visible = true

                    -- Update BillboardGui (name and health)
                    if espObj.BillboardGui then
                        espObj.BillboardGui.Adornee = rootPart
                        espObj.BillboardGui.AlwaysOnTop = self.ThroughWalls
                        espObj.BillboardGui.Enabled = true

                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            espObj.NameLabel.Text = player.Name
                            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            espObj.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                            espObj.HealthFill.BackgroundColor3 = self:GetHealthColor(humanoid)
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

function ESP:GetHealthColor(humanoid)
    if not humanoid or humanoid.Health <= 0 then return CONFIG.HEALTH_BAR_COLOR_END end
    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    return Color3.fromRGB(
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.R * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.R * (1 - healthPercent)),
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.G * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.G * (1 - healthPercent)),
        math.floor(CONFIG.HEALTH_BAR_COLOR_START.B * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.B * (1 - healthPercent))
    )
end

return ESP
