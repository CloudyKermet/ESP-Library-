


_G.Skeleton.Enabled   = false
_G.HeadCircle.Enabled = false
_G.Chams.Enabled      = false

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gustaslaoq/ui-library/refs/heads/main/library.lua"))()

local ui = Lib.new({
    AppName     = "ESP Controller",
    AppSubtitle = "v1",
    AppVersion  = "1.0",
    Pages = {
        { Name = "Visuals" },
    },
})

-- Add a toggle to page 1 (Main)
ui:AddToggle(1, "Skeleton", false, function(value)
_G.Skeleton.Enabled = value
end)

ui:AddToggle(1, "Head Dot", false, function(value)
_G.HeadCircle.Enabled = value
end)

ui:AddToggle(1, "Chams", false, function(value)
_G.Chams.Enabled = value
end)
