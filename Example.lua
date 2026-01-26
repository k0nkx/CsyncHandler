local CsyncHandler = loadstring(game:HttpGet("https://raw.githubusercontent.com/k0nkx/CsyncHandler/refs/heads/main/Handler.lua"))()

-- Example Usage Documentation:
---------------------------------------------------------------------------------------------------
-- BASIC USAGE
---------------------------------------------------------------------------------------------------

-- Turn desync ON/OFF (V key also toggles)
Csync(true)  -- Enable desync
Csync(false) -- Disable desync (position becomes 0,0,0 but desync mechanism stays active)

-- Set desync position offset
CsyncPos(5, 10, -3)  -- X=5 studs right, Y=10 studs up, Z=3 studs back

-- Cleanup and reinitialize if needed
CsyncHandler:Cleanup()  -- Remove all visuals and disconnect
CsyncHandler:Initialize()  -- Re-initialize the handler

---------------------------------------------------------------------------------------------------
-- SERVER PREDICTION
---------------------------------------------------------------------------------------------------

-- Toggle server position prediction (accounts for ping delay)
CsyncServPred(true)  -- Enable prediction (more accurate)
CsyncServPred(false) -- Disable prediction (use local position)

---------------------------------------------------------------------------------------------------
-- CONNECTION LINE SETTINGS
---------------------------------------------------------------------------------------------------

-- Show/hide the connecting line
CsyncLine(true)  -- Show line
CsyncLine(false) -- Hide line

-- Line color (RGB values 0-255)
CsyncLineColorSet(255, 255, 0)    -- Yellow line
CsyncLineColorSet(0, 255, 0)      -- Green line
CsyncLineColorSet(255, 0, 255)    -- Magenta line

-- Line outline color
CsyncOutLineColorSet(0, 0, 0)     -- Black outline
CsyncOutLineColorSet(255, 255, 255) -- White outline

-- Line transparency (0 = invisible, 1 = fully visible)
CsyncLineTrans(0.7)      -- 70% visible
CsyncOutLineTrans(0.3)   -- 30% visible outline

---------------------------------------------------------------------------------------------------
-- VISUAL TYPE SELECTION
---------------------------------------------------------------------------------------------------

-- Choose what visual to show
CsyncVisualType("Both")   -- Show both mesh and image
CsyncVisualType("Mesh")   -- Show only 3D mesh
CsyncVisualType("Image")  -- Show only 2D image

---------------------------------------------------------------------------------------------------
-- MESH VISUAL SETTINGS
---------------------------------------------------------------------------------------------------

-- Set custom mesh (use Roblox asset IDs)
CsyncMesh("rbxassetid://1234567890")  -- Your mesh ID

-- Mesh scale
CsyncMeshScale(0.2, 0.2, 0.2)  -- Make mesh larger (0.1 default)
CsyncMeshScale(0.05, 0.05, 0.05)  -- Make mesh smaller

-- Mesh position offset
CsyncMeshOffset(0, -1, 0)  -- Move mesh down 1 stud
CsyncMeshOffset(0, 0.5, 0)  -- Move mesh up 0.5 studs

---------------------------------------------------------------------------------------------------
-- IMAGE VISUAL SETTINGS
---------------------------------------------------------------------------------------------------

-- Set custom image/texture
CsyncMeshId("rbxassetid://9876543210")  -- Your image ID

-- Image scale (size on screen)
CsyncImageScaleSet(0.5)  -- 50% size
CsyncImageScaleSet(1.0)  -- Full size
CsyncImageScaleSet(0.2)  -- 20% size

---------------------------------------------------------------------------------------------------
-- HIGHLIGHT SETTINGS
---------------------------------------------------------------------------------------------------

-- Toggle highlight effect on mesh
CsyncHighlight(true)   -- Enable highlight
CsyncHighlight(false)  -- Disable highlight

-- Highlight fill color
CsyncHighlightFill(255, 105, 180)  -- Hot pink
CsyncHighlightFill(0, 191, 255)    -- Deep sky blue
CsyncHighlightFill(50, 205, 50)    -- Lime green

-- Highlight outline color
CsyncHighlightOutLine(255, 255, 255)  -- White outline
CsyncHighlightOutLine(0, 0, 0)        -- Black outline

-- Highlight transparency
CsyncHighlightFillTrans(0.5)     -- 50% transparent fill
CsyncHighlightOutLineTrans(0.2)  -- 20% transparent outline
