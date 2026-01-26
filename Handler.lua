local CsyncHandler = {
    Connections = {},
    Instances = {},
    Drawings = {},
    Enabled = false,
    PositionHistory = {},
    
    Config = {
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
}

function CsyncHandler:Initialize()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    self.Camera = workspace.CurrentCamera
    self.CoreGui = game:GetService("CoreGui")
    self.Stats = game:GetService("Stats")
    
    self.player = Players.LocalPlayer
    self.playerCharacter = self.player.Character or self.player.CharacterAdded:Wait()
    self.playerHumanoid = self.playerCharacter:WaitForChild("Humanoid")
    self.playerHumanoidRootPart = self.playerCharacter:WaitForChild("HumanoidRootPart")
    self.playerHumanoidRootPartCFrame = nil
    
    self:SetupConnections()
end

function CsyncHandler:Cleanup()
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

function CsyncHandler:getPing()
    local networkPing = self.player:GetNetworkPing() * 1000
    
    local dataPing = 0
    local item = self.Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
    if item then
        local ok, v = pcall(function()
            return item:GetValueString()
        end)
        if ok and v then
            dataPing = tonumber(v:match("%d+")) or 0
        end
    end
    
    local totalPing = networkPing + dataPing
    
    if totalPing > self.Config.ServerPrediction.HighPingThreshold then
        networkPing = networkPing * self.Config.ServerPrediction.HighPingReduction
        totalPing = networkPing + dataPing
    end
    
    return math.min(totalPing, self.Config.ServerPrediction.MaxPing)
end

function CsyncHandler:getPredictedServerPosition()
    if not self.Config.UseServerPrediction then
        return self.playerHumanoidRootPart.Position
    end
    
    local currentTime = tick()
    self.PositionHistory[currentTime] = {
        Position = self.playerHumanoidRootPart.Position,
        Rotation = self.playerHumanoidRootPart.Rotation
    }
    
    for time in pairs(self.PositionHistory) do
        if currentTime - time > self.Config.ServerPrediction.HistoryDuration then
            self.PositionHistory[time] = nil
        end
    end
    
    local ping = self:getPing()
    local backtrackTime = currentTime - (ping / 1000)
    
    local closestTime = nil
    local smallestDiff = math.huge
    
    for time, data in pairs(self.PositionHistory) do
        local diff = math.abs(time - backtrackTime)
        if diff < smallestDiff then
            smallestDiff = diff
            closestTime = time
        end
    end
    
    if closestTime and self.PositionHistory[closestTime] then
        return self.PositionHistory[closestTime].Position
    end
    
    return self.playerHumanoidRootPart.Position
end

function CsyncHandler:refreshVisuals()
    if self.Enabled then
        self:createVisuals()
    end
end

function CsyncHandler:createVisuals()
    if self.Instances.desyncVisual then 
        self.Instances.desyncVisual:Destroy() 
    end
    
    if self.Instances.imageGui then
        self.Instances.imageGui:Destroy()
    end
    
    if self.Drawings.line then
        self.Drawings.line:Remove()
    end
    
    if self.Drawings.lineOutline then
        self.Drawings.lineOutline:Remove()
    end

    if not self.Enabled then return end

    local randomNum = math.random(222, 4444)
    local visualType = self.Config.Visuals.VisualType
    
    local desyncVisual = nil
    
    if visualType == "Mesh" or visualType == "Both" then
        desyncVisual = Instance.new("Part")
        desyncVisual.Name = "DesyVis_Mesh_" .. randomNum
        desyncVisual.Size = Vector3.new(0.1, 0.1, 0.1)
        desyncVisual.Color = self.Config.Visuals.DesyncColor
        desyncVisual.Material = Enum.Material.Neon
        desyncVisual.Transparency = self.Config.Visuals.Transparency
        desyncVisual.Anchored = true
        desyncVisual.CanCollide = false
        desyncVisual.CastShadow = false
        
        local specialMesh = Instance.new("SpecialMesh")
        specialMesh.MeshId = self.Config.Visuals.MeshId
        specialMesh.TextureId = "rbxassetid://14123716537"
        specialMesh.Scale = self.Config.Visuals.MeshScale
        specialMesh.Offset = self.Config.Visuals.MeshOffset
        specialMesh.MeshType = Enum.MeshType.FileMesh
        specialMesh.Parent = desyncVisual
        
        if self.Config.Visuals.Highlight.Enabled then
            local highlight = Instance.new("Highlight")
            highlight.Name = "DesyncHighlight"
            highlight.FillColor = self.Config.Visuals.Highlight.FillColor
            highlight.OutlineColor = self.Config.Visuals.Highlight.OutlineColor
            highlight.FillTransparency = self.Config.Visuals.Highlight.FillTransparency
            highlight.OutlineTransparency = self.Config.Visuals.Highlight.OutlineTransparency
            
            if self.Config.Visuals.Highlight.DepthMode == "AlwaysOnTop" then
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            end
            
            highlight.Parent = desyncVisual
            self.Instances.highlight = highlight
        end

        desyncVisual.Parent = workspace
        self.Instances.desyncVisual = desyncVisual
        self.Instances.specialMesh = specialMesh
    end
    
    if visualType == "Image" or visualType == "Both" then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DesVisUI_" .. randomNum
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Name = "ImageContainer"
        frame.Size = UDim2.new(0, 100 * self.Config.Visuals.ImageScale, 
                                0, 100 * self.Config.Visuals.ImageScale)
        frame.BackgroundTransparency = 1
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Parent = screenGui
        
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "DesyncImage"
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = self.Config.Visuals.ImageId
        imageLabel.ScaleType = Enum.ScaleType.Fit
        imageLabel.Parent = frame
        
        screenGui.Parent = self.CoreGui
        
        self.Instances.imageGui = screenGui
        self.Instances.imageFrame = frame
        self.Instances.imageLabel = imageLabel
    end

    if self.Config.Visuals.ShowLine then
        local lineOutline = Drawing.new("Line")
        lineOutline.Thickness = self.Config.Visuals.Line.OutlineThickness
        lineOutline.Color = self.Config.Visuals.Line.OutlineColor
        lineOutline.Transparency = self.Config.Visuals.Line.OutlineTransparency
        lineOutline.Visible = true
        
        local line = Drawing.new("Line")
        line.Thickness = self.Config.Visuals.Line.MainThickness
        line.Color = self.Config.Visuals.Line.MainColor
        line.Transparency = self.Config.Visuals.Line.MainTransparency
        line.Visible = true
        
        self.Drawings.lineOutline = lineOutline
        self.Drawings.line = line
    end
end

function CsyncHandler:updateLines()
    if not self.Config.Visuals.ShowLine then 
        if self.Drawings.line then
            self.Drawings.line.Visible = false
        end
        if self.Drawings.lineOutline then
            self.Drawings.lineOutline.Visible = false
        end
        return 
    end
    
    if not self.Drawings.line or not self.Drawings.lineOutline then return end
    
    local line = self.Drawings.line
    local lineOutline = self.Drawings.lineOutline
    
    local visualExists = false
    local visualPosition = nil
    
    if self.Instances.desyncVisual then
        visualExists = true
        visualPosition = self.Instances.desyncVisual.Position
    end
    
    if self.Enabled and self.playerHumanoidRootPart and visualExists then
        local realPos = self.playerHumanoidRootPart.Position
        
        local realScreenPos, realVisible = self.Camera:WorldToViewportPoint(realPos)
        local desyncScreenPos, desyncVisible = self.Camera:WorldToViewportPoint(visualPosition)
        
        if realVisible and desyncVisible then
            local fromPos = Vector2.new(realScreenPos.X, realScreenPos.Y)
            local toPos = Vector2.new(desyncScreenPos.X, desyncScreenPos.Y)
            
            local direction = (toPos - fromPos)
            local length = direction.Magnitude
            
            if length > 0 then
                local normalizedDir = direction / length
                local extension = self.Config.Visuals.Line.Extension
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

function CsyncHandler:updateImagePosition()
    if not self.Enabled then return end
    if not self.Instances.imageGui then return end
    if not self.Instances.desyncVisual then return end
    
    local desyncPos = self.Instances.desyncVisual.Position
    local screenPoint = self.Camera:WorldToScreenPoint(desyncPos)
    
    self.Instances.imageFrame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y)
end

function CsyncHandler:SetupConnections()
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    self.Connections.characterAdded = self.player.CharacterAdded:Connect(function(NewCharacter)
        self.playerCharacter = NewCharacter
        self.playerHumanoid = self.playerCharacter:WaitForChild("Humanoid")
        self.playerHumanoidRootPart = self.playerCharacter:WaitForChild("HumanoidRootPart")
        
        if self.Enabled then
            self:createVisuals()
        end
    end)
    
    self.Connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.V then
            self.Enabled = not self.Enabled
            
            if self.Enabled then
                self:createVisuals()
            else
                if self.Instances.desyncVisual then
                    self.Instances.desyncVisual:Destroy()
                    self.Instances.desyncVisual = nil
                end
                if self.Instances.imageGui then
                    self.Instances.imageGui:Destroy()
                    self.Instances.imageGui = nil
                end
                if self.Drawings.line then
                    self.Drawings.line:Remove()
                    self.Drawings.line = nil
                end
                if self.Drawings.lineOutline then
                    self.Drawings.lineOutline:Remove()
                    self.Drawings.lineOutline = nil
                end
            end
        end
    end)
    
    self.Connections.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        if self.playerCharacter and self.playerHumanoidRootPart then
            self.playerHumanoidRootPartCFrame = self.playerHumanoidRootPart.CFrame
            
            local basePosition = self:getPredictedServerPosition()
            
            local currentX = self.Enabled and self.Config.Position.X or 0
            local currentY = self.Enabled and self.Config.Position.Y or 0
            local currentZ = self.Enabled and self.Config.Position.Z or 0
            
            local desyncedPosition = basePosition + Vector3.new(
                currentX,
                currentY,
                currentZ
            )
            
            if self.Instances.desyncVisual then
                self.Instances.desyncVisual.CFrame = CFrame.new(desyncedPosition) * self.playerHumanoidRootPart.CFrame.Rotation
            end
            
            self.playerHumanoidRootPart.CFrame = CFrame.new(desyncedPosition) * self.playerHumanoidRootPart.CFrame.Rotation
            RunService.RenderStepped:Wait()
            self.playerHumanoidRootPart.CFrame = self.playerHumanoidRootPartCFrame
            self.playerHumanoidRootPartCFrame = self.playerHumanoidRootPart.CFrame
        end
    end)
    
    self.Connections.renderStepped = RunService.RenderStepped:Connect(function()
        self:updateLines()
        self:updateImagePosition()
    end)
    
    self.OriginalCFrameIndex = hookmetamethod(game, "__index", function(Instance, Property)
        if self.playerCharacter and self.playerHumanoidRootPart and Instance == self.playerHumanoidRootPart and Property == "CFrame" then
            if not checkcaller() then
                return self.playerHumanoidRootPartCFrame
            end
        end
        return self.OriginalCFrameIndex(Instance, Property)
    end)
end

-- Helper Functions
function CsyncPos(x, y, z)
    CsyncHandler.Config.Position.X = x
    CsyncHandler.Config.Position.Y = y
    CsyncHandler.Config.Position.Z = z
end

function Csync(state)
    CsyncHandler.Enabled = state
    if state then
        CsyncHandler:createVisuals()
    else
        if CsyncHandler.Instances.desyncVisual then
            CsyncHandler.Instances.desyncVisual:Destroy()
            CsyncHandler.Instances.desyncVisual = nil
        end
        if CsyncHandler.Instances.imageGui then
            CsyncHandler.Instances.imageGui:Destroy()
            CsyncHandler.Instances.imageGui = nil
        end
        if CsyncHandler.Drawings.line then
            CsyncHandler.Drawings.line:Remove()
            CsyncHandler.Drawings.line = nil
        end
        if CsyncHandler.Drawings.lineOutline then
            CsyncHandler.Drawings.lineOutline:Remove()
            CsyncHandler.Drawings.lineOutline = nil
        end
    end
end

function CsyncServPred(state)
    CsyncHandler.Config.UseServerPrediction = state
end

function CsyncLine(state)
    CsyncHandler.Config.Visuals.ShowLine = state
    CsyncHandler:refreshVisuals()
end

function CsyncLineColorSet(r, g, b)
    CsyncHandler.Config.Visuals.Line.MainColor = Color3.fromRGB(r, g, b)
    if CsyncHandler.Drawings.line then
        CsyncHandler.Drawings.line.Color = Color3.fromRGB(r, g, b)
    end
end

function CsyncOutLineColorSet(r, g, b)
    CsyncHandler.Config.Visuals.Line.OutlineColor = Color3.fromRGB(r, g, b)
    if CsyncHandler.Drawings.lineOutline then
        CsyncHandler.Drawings.lineOutline.Color = Color3.fromRGB(r, g, b)
    end
end

function CsyncLineTrans(transparency)
    CsyncHandler.Config.Visuals.Line.MainTransparency = transparency
    if CsyncHandler.Drawings.line then
        CsyncHandler.Drawings.line.Transparency = transparency
    end
end

function CsyncOutLineTrans(transparency)
    CsyncHandler.Config.Visuals.Line.OutlineTransparency = transparency
    if CsyncHandler.Drawings.lineOutline then
        CsyncHandler.Drawings.lineOutline.Transparency = transparency
    end
end

function CsyncVisualType(type)
    if type == "Both" or type == "Mesh" or type == "Image" then
        CsyncHandler.Config.Visuals.VisualType = type
        CsyncHandler:refreshVisuals()
    end
end

function CsyncMesh(meshId)
    CsyncHandler.Config.Visuals.MeshId = meshId
    CsyncHandler:refreshVisuals()
end

function CsyncMeshScale(x, y, z)
    CsyncHandler.Config.Visuals.MeshScale = Vector3.new(x, y, z)
    CsyncHandler:refreshVisuals()
end

function CsyncMeshOffset(x, y, z)
    CsyncHandler.Config.Visuals.MeshOffset = Vector3.new(x, y, z)
    CsyncHandler:refreshVisuals()
end

function CsyncMeshId(imageId)
    CsyncHandler.Config.Visuals.ImageId = imageId
    CsyncHandler:refreshVisuals()
end

function CsyncImageScaleSet(scale)
    CsyncHandler.Config.Visuals.ImageScale = scale
    CsyncHandler:refreshVisuals()
end

function CsyncHighlight(state)
    CsyncHandler.Config.Visuals.Highlight.Enabled = state
    CsyncHandler:refreshVisuals()
end

function CsyncHighlightFill(r, g, b)
    CsyncHandler.Config.Visuals.Highlight.FillColor = Color3.fromRGB(r, g, b)
    CsyncHandler:refreshVisuals()
end

function CsyncHighlightOutLine(r, g, b)
    CsyncHandler.Config.Visuals.Highlight.OutlineColor = Color3.fromRGB(r, g, b)
    CsyncHandler:refreshVisuals()
end

function CsyncHighlightFillTrans(transparency)
    CsyncHandler.Config.Visuals.Highlight.FillTransparency = transparency
    CsyncHandler:refreshVisuals()
end

function CsyncHighlightOutLineTrans(transparency)
    CsyncHandler.Config.Visuals.Highlight.OutlineTransparency = transparency
    CsyncHandler:refreshVisuals()
end

-- Export as a module
if _G.CsyncHandler then
    _G.CsyncHandler:Cleanup()
end

_G.CsyncHandler = CsyncHandler

-- Auto-initialize when loaded
CsyncHandler:Initialize()

return CsyncHandler
