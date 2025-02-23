-- Utils.lua
-- Shared utility functions with player database for Rivals

local Utils = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Player database
local PlayerDatabase = {
    Players = {}, -- { [player] = { RootPart, Humanoid, LastUpdate } }
    Connections = {}
}

-- Initialize the database
function PlayerDatabase:Initialize()
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end

    -- Handle player joining
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end)

    -- Handle player leaving
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)

    -- Periodic scan for missed players
    self.Connections.Scan = RunService.Heartbeat:Connect(function()
        self:ScanWorkspace()
    end)
end

-- Add a player to the database
function PlayerDatabase:AddPlayer(player)
    if self.Players[player] then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if rootPart and humanoid then
        self.Players[player] = {
            RootPart = rootPart,
            Humanoid = humanoid,
            LastUpdate = tick()
        }

        -- Update on character change
        local conn = player.CharacterAdded:Connect(function(newChar)
            local newRoot = newChar:WaitForChild("HumanoidRootPart", 5) or newChar:FindFirstChildOfClass("Part")
            local newHum = newChar:WaitForChild("Humanoid", 5)
            if newRoot and newHum then
                self.Players[player] = {
                    RootPart = newRoot,
                    Humanoid = newHum,
                    LastUpdate = tick()
                }
            end
        end)
        self.Connections[player.Name .. "_Char"] = conn
    end
end

-- Remove a player from the database
function PlayerDatabase:RemovePlayer(player)
    if self.Players[player] then
        self.Players[player] = nil
        if self.Connections[player.Name .. "_Char"] then
            self.Connections[player.Name .. "_Char"]:Disconnect()
            self.Connections[player.Name .. "_Char"] = nil
        end
    end
end

-- Scan workspace for players missed by conventional methods
function PlayerDatabase:ScanWorkspace()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("Part")
            if rootPart then
                local player = Players:GetPlayerFromCharacter(model)
                if not player then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and not self.Players[plr] then
                            if string.find(string.lower(model.Name), string.lower(plr.Name)) or
                               (plr.Character and (rootPart.Position - plr.Character:GetPivot().Position).Magnitude < 10) then
                                player = plr
                                break
                            end
                        end
                    end
                end
                if player and player ~= LocalPlayer and not self.Players[player] then
                    self:AddPlayer(player)
                end
            end
        end
    end

    -- Clean up stale entries
    for player, data in pairs(self.Players) do
        if tick() - data.LastUpdate > 10 then -- Stale if not updated in 10 seconds
            self:RemovePlayer(player)
        end
    end
end

-- Get all tracked players
function Utils.GetPlayers()
    local playerList = {}
    for player, data in pairs(PlayerDatabase.Players) do
        if data.RootPart and data.Humanoid and data.Humanoid.Health > 0 then
            data.LastUpdate = tick() -- Update timestamp
            table.insert(playerList, {
                Player = player,
                RootPart = data.RootPart,
                Humanoid = data.Humanoid
            })
        else
            PlayerDatabase:RemovePlayer(player)
        end
    end
    return playerList
end

-- Cleanup database
function Utils.Destroy()
    for _, conn in pairs(PlayerDatabase.Connections) do
        conn:Disconnect()
    end
    PlayerDatabase.Players = {}
    PlayerDatabase.Connections = {}
end

-- Smooth aim function (unchanged)
function Utils.SmoothAim(camera, targetPos)
    local mouse = LocalPlayer:GetMouse()
    local currentPos = Vector2.new(mouse.X, mouse.Y)
    local delta = (Vector2.new(targetPos.X, targetPos.Y) - currentPos) * 0.1 -- Smoothing factor
    mousemoverel(delta.X, delta.Y)
end

-- Create ESP box function (unchanged)
function Utils.CreateESPBox(rootPart)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if rootPart and rootPart.Parent then
            local camera = workspace.CurrentCamera
            local pos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local size = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - 
                            camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0)).Y) * 1.5
                box.Size = Vector2.new(size, size)
                box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box:Remove()
            connection:Disconnect()
        end
    end)
    
    return box
end

-- Initialize the database on load
PlayerDatabase:Initialize()

return Utils
