local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

if _G.DesyncScript then
    _G.DesyncScript:Cleanup()
    _G.DesyncScript = nil
    task.wait()
end

_G.DesyncScript = {
    Connections = {},
    Instances = {},
    Drawings = {},
    Enabled = false,
    PositionHistory = {},
    Cleanup = function(self)
        self.Enabled = false
        
        for _, connection in pairs(self.Connections) do 
            if connection and typeof(connection) == "RBXScriptConnection" then 
                connection:Disconnect() 
            end
        end
        
        for _, instance in pairs(self.Instances) do
            if instance and instance.Parent then 
                instance:Destroy() 
            end
        end
        
        for _, drawing in pairs(self.Drawings) do
            if drawing then 
                drawing:Remove() 
            end
        end
        
        table.clear(self.Connections)
        table.clear(self.Instances)
        table.clear(self.Drawings)
        table.clear(self.PositionHistory)
        
        if self.OriginalCFrameIndex then
            hookmetamethod(game, "__index", self.OriginalCFrameIndex)
            self.OriginalCFrameIndex = nil
        end
    end
}

local player = Players.LocalPlayer
local playerCharacter = player.Character or player.CharacterAdded:Wait()
local playerHumanoid = playerCharacter:WaitForChild("Humanoid")
local playerHumanoidRootPart = playerCharacter:WaitForChild("HumanoidRootPart")
local playerHumanoidRootPartCFrame = nil

_G.DesyncScript.Config = {
    Position = {
        X = 0,
        Y = 5,
        Z = 0
    },
    UseServerPrediction = true,
    ServerPrediction = {
        HistoryDuration = 2,
        MaxPing = 300,
        HighPingThreshold = 160,
        HighPingReduction = 0.9
    },
    Visuals = {
        DesyncColor = Color3.fromRGB(0, 162, 255),
        Transparency = 0,
        ShowLine = true,
        Line = {
            MainColor = Color3.fromRGB(255, 255, 255),
            OutlineColor = Color3.fromRGB(0, 0, 0),
            MainThickness = 2,
            OutlineThickness = 3,
            MainTransparency = 1,
            OutlineTransparency = 1,
            Extension = 1
        },
        VisualType = "Both",
        MeshId = "rbxassetid://14123716423",
        MeshScale = Vector3.new(0.1, 0.1, 0.1),
        MeshOffset = Vector3.new(0, -0.8, 0),
        ImageId = "rbxassetid://94277058488615",
        ImageScale = 0.38,
        Highlight = {
            Enabled = true,
            FillColor = Color3.fromRGB(245, 173, 255),
            OutlineColor = Color3.fromRGB(255, 255, 255),
            FillTransparency = 0.7,
            OutlineTransparency = 0.5,
            DepthMode = "AlwaysOnTop"
        }
    }
}

local function getPing()
    local networkPing = player:GetNetworkPing() * 1000
    
    local dataPing = 0
    local item = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
    if item then
        local ok, v = pcall(function()
            return item:GetValueString()
        end)
        if ok and v then
            dataPing = tonumber(v:match("%d+")) or 0
        end
    end
    
    local totalPing = networkPing + dataPing
    
    if totalPing > _G.DesyncScript.Config.ServerPrediction.HighPingThreshold then
        networkPing = networkPing * _G.DesyncScript.Config.ServerPrediction.HighPingReduction
        totalPing = networkPing + dataPing
    end
    
    return math.min(totalPing, _G.DesyncScript.Config.ServerPrediction.MaxPing)
end

local function getPredictedServerPosition()
    if not _G.DesyncScript.Config.UseServerPrediction then
        return playerHumanoidRootPart.Position
    end
    
    local currentTime = tick()
    _G.DesyncScript.PositionHistory[currentTime] = {
        Position = playerHumanoidRootPart.Position,
        Rotation = playerHumanoidRootPart.Rotation
    }
    
    for time in pairs(_G.DesyncScript.PositionHistory) do
        if currentTime - time > _G.DesyncScript.Config.ServerPrediction.HistoryDuration then
            _G.DesyncScript.PositionHistory[time] = nil
        end
    end
    
    local ping = getPing()
    local backtrackTime = currentTime - (ping / 1000)
    
    local closestTime = nil
    local smallestDiff = math.huge
    
    for time, data in pairs(_G.DesyncScript.PositionHistory) do
        local diff = math.abs(time - backtrackTime)
        if diff < smallestDiff then
            smallestDiff = diff
            closestTime = time
        end
    end
    
    if closestTime and _G.DesyncScript.PositionHistory[closestTime] then
        return _G.DesyncScript.PositionHistory[closestTime].Position
    end
    
    return playerHumanoidRootPart.Position
end

local function createVisuals()
    if _G.DesyncScript.Instances.desyncVisual then 
        _G.DesyncScript.Instances.desyncVisual:Destroy() 
    end
    
    if _G.DesyncScript.Instances.imageGui then
        _G.DesyncScript.Instances.imageGui:Destroy()
    end
    
    if _G.DesyncScript.Drawings.line then
        _G.DesyncScript.Drawings.line:Remove()
    end
    
    if _G.DesyncScript.Drawings.lineOutline then
        _G.DesyncScript.Drawings.lineOutline:Remove()
    end

    if not _G.DesyncScript.Enabled then return end

    local randomNum = math.random(222, 4444)
    local visualType = _G.DesyncScript.Config.Visuals.VisualType
    
    local desyncVisual = nil
    
    if visualType == "Mesh" or visualType == "Both" then
        desyncVisual = Instance.new("Part")
        desyncVisual.Name = "DesyVis_Mesh_" .. randomNum
        desyncVisual.Size = Vector3.new(0.1, 0.1, 0.1)
        desyncVisual.Color = _G.DesyncScript.Config.Visuals.DesyncColor
        desyncVisual.Material = Enum.Material.Neon
        desyncVisual.Transparency = _G.DesyncScript.Config.Visuals.Transparency
        desyncVisual.Anchored = true
        desyncVisual.CanCollide = false
        desyncVisual.CastShadow = false
        
        local specialMesh = Instance.new("SpecialMesh")
        specialMesh.MeshId = _G.DesyncScript.Config.Visuals.MeshId
        specialMesh.TextureId = "rbxassetid://14123716537"
        specialMesh.Scale = _G.DesyncScript.Config.Visuals.MeshScale
        specialMesh.Offset = _G.DesyncScript.Config.Visuals.MeshOffset
        specialMesh.MeshType = Enum.MeshType.FileMesh
        specialMesh.Parent = desyncVisual
        
        if _G.DesyncScript.Config.Visuals.Highlight.Enabled then
            local highlight = Instance.new("Highlight")
            highlight.Name = "DesyncHighlight"
            highlight.FillColor = _G.DesyncScript.Config.Visuals.Highlight.FillColor
            highlight.OutlineColor = _G.DesyncScript.Config.Visuals.Highlight.OutlineColor
            highlight.FillTransparency = _G.DesyncScript.Config.Visuals.Highlight.FillTransparency
            highlight.OutlineTransparency = _G.DesyncScript.Config.Visuals.Highlight.OutlineTransparency
            
            if _G.DesyncScript.Config.Visuals.Highlight.DepthMode == "AlwaysOnTop" then
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            end
            
            highlight.Parent = desyncVisual
            _G.DesyncScript.Instances.highlight = highlight
        end

        desyncVisual.Parent = workspace
        _G.DesyncScript.Instances.desyncVisual = desyncVisual
        _G.DesyncScript.Instances.specialMesh = specialMesh
    end
    
    if visualType == "Image" or visualType == "Both" then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DesVisUI_" .. randomNum
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Name = "ImageContainer"
        frame.Size = UDim2.new(0, 100 * _G.DesyncScript.Config.Visuals.ImageScale, 
                                0, 100 * _G.DesyncScript.Config.Visuals.ImageScale)
        frame.BackgroundTransparency = 1
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Parent = screenGui
        
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "DesyncImage"
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = _G.DesyncScript.Config.Visuals.ImageId
        imageLabel.ScaleType = Enum.ScaleType.Fit
        imageLabel.Parent = frame
        
        screenGui.Parent = CoreGui
        
        _G.DesyncScript.Instances.imageGui = screenGui
        _G.DesyncScript.Instances.imageFrame = frame
        _G.DesyncScript.Instances.imageLabel = imageLabel
    end

    if _G.DesyncScript.Config.Visuals.ShowLine then
        local lineOutline = Drawing.new("Line")
        lineOutline.Thickness = _G.DesyncScript.Config.Visuals.Line.OutlineThickness
        lineOutline.Color = _G.DesyncScript.Config.Visuals.Line.OutlineColor
        lineOutline.Transparency = _G.DesyncScript.Config.Visuals.Line.OutlineTransparency
        lineOutline.Visible = true
        
        local line = Drawing.new("Line")
        line.Thickness = _G.DesyncScript.Config.Visuals.Line.MainThickness
        line.Color = _G.DesyncScript.Config.Visuals.Line.MainColor
        line.Transparency = _G.DesyncScript.Config.Visuals.Line.MainTransparency
        line.Visible = true
        
        _G.DesyncScript.Drawings.lineOutline = lineOutline
        _G.DesyncScript.Drawings.line = line
    end
    
    return true
end

local function updateLines()
    if not _G.DesyncScript.Config.Visuals.ShowLine then 
        if _G.DesyncScript.Drawings.line then
            _G.DesyncScript.Drawings.line.Visible = false
        end
        if _G.DesyncScript.Drawings.lineOutline then
            _G.DesyncScript.Drawings.lineOutline.Visible = false
        end
        return 
    end
    
    if not _G.DesyncScript.Drawings.line or not _G.DesyncScript.Drawings.lineOutline then return end
    
    local line = _G.DesyncScript.Drawings.line
    local lineOutline = _G.DesyncScript.Drawings.lineOutline
    
    local visualExists = false
    local visualPosition = nil
    
    if _G.DesyncScript.Instances.desyncVisual then
        visualExists = true
        visualPosition = _G.DesyncScript.Instances.desyncVisual.Position
    end
    
    if _G.DesyncScript.Enabled and playerHumanoidRootPart and visualExists then
        local realPos = playerHumanoidRootPart.Position  -- Changed back to local position
        
        local realScreenPos, realVisible = Camera:WorldToViewportPoint(realPos)
        local desyncScreenPos, desyncVisible = Camera:WorldToViewportPoint(visualPosition)
        
        if realVisible and desyncVisible then
            local fromPos = Vector2.new(realScreenPos.X, realScreenPos.Y)
            local toPos = Vector2.new(desyncScreenPos.X, desyncScreenPos.Y)
            
            local direction = (toPos - fromPos)
            local length = direction.Magnitude
            
            if length > 0 then
                local normalizedDir = direction / length
                local extension = _G.DesyncScript.Config.Visuals.Line.Extension
                local outlineFrom = fromPos - (normalizedDir * extension)
                local outlineTo = toPos + (normalizedDir * extension)
                
                lineOutline.From = outlineFrom
                lineOutline.To = outlineTo
                lineOutline.Visible = true
                
                line.From = fromPos
                line.To = toPos
                line.Visible = true
            else
                lineOutline.Visible = false
                line.Visible = false
            end
        else
            lineOutline.Visible = false
            line.Visible = false
        end
    else
        lineOutline.Visible = false
        line.Visible = false
    end
end

local function updateImagePosition()
    if not _G.DesyncScript.Enabled then return end
    if not _G.DesyncScript.Instances.imageGui then return end
    if not _G.DesyncScript.Instances.desyncVisual then return end
    
    local desyncPos = _G.DesyncScript.Instances.desyncVisual.Position
    local screenPoint = Camera:WorldToScreenPoint(desyncPos)
    
    _G.DesyncScript.Instances.imageFrame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y)
end

_G.DesyncScript.Connections.characterAdded = player.CharacterAdded:Connect(function(NewCharacter)
    playerCharacter = NewCharacter
    playerHumanoid = playerCharacter:WaitForChild("Humanoid")
    playerHumanoidRootPart = playerCharacter:WaitForChild("HumanoidRootPart")
    
    if _G.DesyncScript.Enabled then
        createVisuals()
    end
end)

_G.DesyncScript.Connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.V then
        _G.DesyncScript.Enabled = not _G.DesyncScript.Enabled
        
        if _G.DesyncScript.Enabled then
            createVisuals()
        else
            if _G.DesyncScript.Instances.desyncVisual then
                _G.DesyncScript.Instances.desyncVisual:Destroy()
                _G.DesyncScript.Instances.desyncVisual = nil
            end
            if _G.DesyncScript.Instances.imageGui then
                _G.DesyncScript.Instances.imageGui:Destroy()
                _G.DesyncScript.Instances.imageGui = nil
            end
            if _G.DesyncScript.Drawings.line then
                _G.DesyncScript.Drawings.line:Remove()
                _G.DesyncScript.Drawings.line = nil
            end
            if _G.DesyncScript.Drawings.lineOutline then
                _G.DesyncScript.Drawings.lineOutline:Remove()
                _G.DesyncScript.Drawings.lineOutline = nil
            end
        end
    end
end)

_G.DesyncScript.Connections.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
    if playerCharacter and playerHumanoidRootPart then
        playerHumanoidRootPartCFrame = playerHumanoidRootPart.CFrame
        
        local basePosition = getPredictedServerPosition()  -- Still use prediction for desync calculation
        
        local currentX = _G.DesyncScript.Enabled and _G.DesyncScript.Config.Position.X or 0
        local currentY = _G.DesyncScript.Enabled and _G.DesyncScript.Config.Position.Y or 0
        local currentZ = _G.DesyncScript.Enabled and _G.DesyncScript.Config.Position.Z or 0
        
        local desyncedPosition = basePosition + Vector3.new(
            currentX,
            currentY,
            currentZ
        )
        
        if _G.DesyncScript.Instances.desyncVisual then
            _G.DesyncScript.Instances.desyncVisual.CFrame = CFrame.new(desyncedPosition) * playerHumanoidRootPart.CFrame.Rotation
        end
        
        playerHumanoidRootPart.CFrame = CFrame.new(desyncedPosition) * playerHumanoidRootPart.CFrame.Rotation
        RunService.RenderStepped:Wait()
        playerHumanoidRootPart.CFrame = playerHumanoidRootPartCFrame
        playerHumanoidRootPartCFrame = playerHumanoidRootPart.CFrame
    end
end)

_G.DesyncScript.Connections.renderStepped = RunService.RenderStepped:Connect(function()
    updateLines()
    updateImagePosition()
end)

_G.DesyncScript.OriginalCFrameIndex = hookmetamethod(game, "__index", function(Instance, Property)
    if playerCharacter and playerHumanoidRootPart and Instance == playerHumanoidRootPart and Property == "CFrame" then
        if not checkcaller() then
            return playerHumanoidRootPartCFrame
        end
    end
    return _G.DesyncScript.OriginalCFrameIndex(Instance, Property)
end)
