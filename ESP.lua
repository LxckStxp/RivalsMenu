-- ESP.lua
-- Sophisticated 2D on-screen ESP for Rivals with enhanced visuals and distance limit

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- ESP Configuration
local CONFIG = {
    BOX_COLOR = Color3.fromRGB(255, 50, 50), -- Vibrant red
    OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    BOX_THICKNESS = 2,
    BOX_PADDING = 2,
    NAME_SIZE = 18,
    NAME_OFFSET_Y = -25,
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
    self.ESPObjects = {} -- { [player] = { Box, Outline, Name, HealthBar, HealthFill } }
    self.Connection = nil
    return self
end

function ESP:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("ESP enabled with 2D drawing.")
    
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
        obj.Name:Remove()
        if obj.HealthBar then obj.HealthBar:Remove() end
        if obj.HealthFill then obj.HealthFill:Remove() end
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
        obj.Name.Color = color
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

    local name = Drawing.new("Text")
    name.Size = CONFIG.NAME_SIZE
    name.Center = true
    name.Outline = true
    name.Color = CONFIG.TEXT_COLOR
    name.Font = Drawing.Fonts.UI
    name.Visible = false

    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Color = Color3.fromRGB(20, 20, 20) -- Dark background
    healthBar.Filled = true
    healthBar.Visible = false

    local healthFill = Drawing.new("Square")
    healthFill.Thickness = 1
    healthFill.Color = CONFIG.HEALTH_BAR_COLOR_START
    healthFill.Filled = true
    healthFill.Visible = false

    return {
        Box = box,
        Outline = outline,
        Name = name,
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
            obj.Name:Remove()
            if obj.HealthBar then obj.HealthBar:Remove() end
            if obj.HealthFill then obj.HealthFill:Remove() end
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
                            obj.Name.Visible = false
                            if obj.HealthBar then obj.HealthBar.Visible = false end
                            if obj.HealthFill then obj.HealthFill.Visible = false end
                        end
                        continue
                    end
                end

                local espObj = self.ESPObjects[player]
                if not espObj or espObj.Character ~= character then
                    -- Create or recreate ESP for new/changed character
                    if espObj then
                        espObj.Box:Remove()
                        espObj.Outline:Remove()
                        espObj.Name:Remove()
                        if espObj.HealthBar then espObj.HealthBar:Remove() end
                        if espObj.HealthFill then espObj.HealthFill:Remove() end
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
                        espObj.Name.Visible = false
                        if espObj.HealthBar then espObj.HealthBar.Visible = false end
                        if espObj.HealthFill then espObj.HealthFill.Visible = false end
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

                    -- Name
                    espObj.Name.Position = Vector2.new(pos2D.X, pos2D.Y + CONFIG.NAME_OFFSET_Y)
                    espObj.Name.Text = player.Name
                    espObj.Name.Visible = true

                    -- Health Bar (improved design with gradient)
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barHeight = sizeY * healthPercent
                    local barY = pos2D.Y - sizeY / 2 - CONFIG.BOX_PADDING - 2
                    espObj.HealthBar.Position = Vector2.new(pos2D.X - CONFIG.HEALTH_BAR_WIDTH / 2 - sizeX / 2 - CONFIG.BOX_PADDING - 2, barY + sizeY - CONFIG.HEALTH_BAR_HEIGHT)
                    espObj.HealthBar.Size = Vector2.new(CONFIG.HEALTH_BAR_WIDTH, CONFIG.HEALTH_BAR_HEIGHT)
                    espObj.HealthBar.Visible = true

                    espObj.HealthFill.Position = Vector2.new(pos2D.X - CONFIG.HEALTH_BAR_WIDTH / 2 - sizeX / 2 - CONFIG.BOX_PADDING - 2, barY + sizeY - CONFIG.HEALTH_BAR_HEIGHT - (sizeY - CONFIG.HEALTH_BAR_HEIGHT) * (1 - healthPercent))
                    espObj.HealthFill.Size = Vector2.new(CONFIG.HEALTH_BAR_WIDTH, (sizeY - CONFIG.HEALTH_BAR_HEIGHT) * healthPercent + CONFIG.HEALTH_BAR_HEIGHT)
                    espObj.HealthFill.Color = Color3.fromRGB(
                        math.floor(CONFIG.HEALTH_BAR_COLOR_START.R * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.R * (1 - healthPercent)),
                        math.floor(CONFIG.HEALTH_BAR_COLOR_START.G * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.G * (1 - healthPercent)),
                        math.floor(CONFIG.HEALTH_BAR_COLOR_START.B * healthPercent + CONFIG.HEALTH_BAR_COLOR_END.B * (1 - healthPercent))
                    )
                    espObj.HealthFill.Visible = true
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
