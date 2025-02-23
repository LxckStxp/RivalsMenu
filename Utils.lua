-- Utils.lua
-- Shared utility functions with optimized player database for Rivals

local Utils = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Player database
local PlayerDatabase = {
    Players = {}, -- { [player] = { RootPart, Humanoid, LastUpdate, Directory } }
    Directories = {}, -- Cached directories where players were found
    Connections = {}
}

-- Initialize the database
function PlayerDatabase:Initialize()
    print("Initializing PlayerDatabase...")
    self:FullScan()

    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end)

    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)

    local lastScan = tick()
    self.Connections.Scan = RunService.Heartbeat:Connect(function()
        if tick() - lastScan >= 60 then
            self:ScanCachedDirectories()
            lastScan = tick()
        end
    end)
end

-- Perform a full workspace scan
function PlayerDatabase:FullScan()
    print("Performing full workspace scan...")
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("Part")
            if rootPart then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= LocalPlayer then
                    self:AddPlayer(player, rootPart.Parent)
                end
            end
        end
    end
    print("Full scan completed. Found directories: " .. #self.Directories)
end

-- Scan cached directories
function PlayerDatabase:ScanCachedDirectories()
    if #self.Directories == 0 then return end
    print("Scanning cached directories...")

    for _, directory in pairs(self.Directories) do
        if directory and directory.Parent then
            for _, obj in pairs(directory:GetDescendants()) do
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
                            self:AddPlayer(player, directory)
                        end
                    end
                end
            end
        end
    end

    -- Clean up stale entries
    for player, data in pairs(self.Players) do
        if tick() - data.LastUpdate > 10 then
            self:RemovePlayer(player)
        end
    end
end

-- Add a player to the database
function PlayerDatabase:AddPlayer(player, directory)
    if self.Players[player] then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildOfClass("Part")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    directory = directory or character.Parent

    if rootPart and humanoid then
        self.Players[player] = {
            RootPart = rootPart,
            Humanoid = humanoid,
            LastUpdate = tick(),
            Directory = directory
        }

        if directory and not table.find(self.Directories, directory) then
            table.insert(self.Directories, directory)
            print("Cached new directory: " .. directory:GetFullName())
        end

        local conn = player.CharacterAdded:Connect(function(newChar)
            local newRoot = newChar:WaitForChild("HumanoidRootPart", 5) or newChar:FindFirstChildOfClass("Part")
            local newHum = newChar:WaitForChild("Humanoid", 5)
            local newDir = newChar.Parent
            if newRoot and newHum then
                self.Players[player] = {
                    RootPart = newRoot,
                    Humanoid = newHum,
                    LastUpdate = tick(),
                    Directory = newDir
                }
                if not table.find(self.Directories, newDir) then
                    table.insert(self.Directories, newDir)
                    print("Cached new directory from CharacterAdded: " .. newDir:GetFullName())
                end
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

-- Public Utilities
function Utils.GetPlayers()
    local playerList = {}
    for player, data in pairs(PlayerDatabase.Players) do
        if data.RootPart and data.Humanoid and data.Humanoid.Health > 0 then
            data.LastUpdate = tick()
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

function Utils.Destroy()
    for _, conn in pairs(PlayerDatabase.Connections) do
        conn:Disconnect()
    end
    PlayerDatabase.Players = {}
    PlayerDatabase.Directories = {}
    PlayerDatabase.Connections = {}
    print("PlayerDatabase destroyed.")
end

function Utils.ForceFullScan()
    print("Executing forced full scan...")
    PlayerDatabase:FullScan()
end

function Utils.SmoothAim(camera, targetPos, smoothness)
    local mouse = LocalPlayer:GetMouse()
    local currentPos = Vector2.new(mouse.X, mouse.Y)
    local delta = (Vector2.new(targetPos.X, targetPos.Y) - currentPos) * smoothness
    mousemoverel(delta.X, delta.Y)
end

function Utils.SnapAim(camera, targetPos)
    local mouse = LocalPlayer:GetMouse()
    local deltaX = targetPos.X - mouse.X
    local deltaY = targetPos.Y - mouse.Y
    mousemoverel(deltaX, deltaY)
end

-- Initialize the database on load
PlayerDatabase:Initialize()

return Utils
