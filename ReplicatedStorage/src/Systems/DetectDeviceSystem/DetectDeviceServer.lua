local ServerScriptService = game:GetService("ServerScriptService")

local RELOCATED_MODULES = ServerScriptService:FindFirstChild("RELOCATED_MODULES")
assert(RELOCATED_MODULES, "ServerScriptService missing 'RELOCATE_MODULES' folder")

local child = RELOCATED_MODULES:FindFirstChild(script.Name)
assert(child, `RELOCATED_MODULES folder missing module '{script.Name}'`)

local module = require(child)
return module