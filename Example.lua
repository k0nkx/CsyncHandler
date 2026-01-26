-- Load the script
local CsyncHandler = loadstring(game:HttpGet("https://raw.githubusercontent.com/k0nkx/CsyncHandler/refs/heads/main/Handler.lua"))()

-- Basic usage
Csync(true)  -- Turn on desync
CsyncPos(10, 0, 0)  -- Set desync position to 10 studs right

-- Or use the handler directly
_G.CsyncHandler.Enabled = true
_G.CsyncPos(0, 10, 0)  -- 10 studs up

-- Change visuals
CsyncLine(false)  -- Hide the line
CsyncLineColorSet(255, 0, 0)  -- Red line
CsyncVisualType("Mesh")  -- Show only mesh
CsyncHighlight(false)  -- Disable highlight

-- Lock position for 5 seconds
CsyncSetLockPos(0, 20, 0, 5)

-- Change keybind
CsyncKeybindSet("B")  -- Now B toggles instead of V

-- Clean up when done
CsyncHandler:Cleanup()
