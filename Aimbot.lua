-- Aimbot.lua
-- Aimbot functionality for Rivals

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/RivalsScript/main/Utils.lua"))()
local Aimbot = {}
Aimbot.__index = Aimbot

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function Aimbot.new()
    local self = setmetatable({}, Aimbot)
    self.Enabled = false
    self.FOV = 150
    self.Target = nil
    self.Connection = nil
    return self
end

function Aimbot:Enable()
    if self.Enabled then return end
    self.Enabled = true
    
    self.Connection = RunService.RenderStepped:Connect(function()
        if self.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            self:Update()
        end
    end)
end

function Aimbot:Disable()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function Aimbot:SetFOV(value)
    self.FOV = value
end

function Aimbot:Update()
    local localPlayer = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    
    local closestPlayer, closestDist = nil, self.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    
    if closestPlayer then
        self.Target = closestPlayer
        local targetHead = closestPlayer.Character.Head
        local targetPos = camera:WorldToViewportPoint(targetHead.Position)
        Utils.SmoothAim(camera, targetPos)
    else
        self.Target = nil
    end
end

function Aimbot:Destroy()
    self:Disable()
end

return Aimbot
