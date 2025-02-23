-- Utils.lua
-- Shared utility functions for ESP and Aimbot

local Utils = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function Utils.SmoothAim(camera, targetPos)
    local mouse = Players.LocalPlayer:GetMouse()
    local currentPos = Vector2.new(mouse.X, mouse.Y)
    local delta = (Vector2.new(targetPos.X, targetPos.Y) - currentPos) * 0.1 -- Smoothing factor
    mousemoverel(delta.X, delta.Y)
end

function Utils.CreateESPBox(part)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if part and part.Parent then
            local camera = workspace.CurrentCamera
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local size = (camera:WorldToViewportPoint(part.Position - Vector3.new(0, 3, 0)).Y - 
                            camera:WorldToViewportPoint(part.Position + Vector3.new(0, 3, 0)).Y) * 1.5
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

return Utils
