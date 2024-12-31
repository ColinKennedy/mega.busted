--- Any core-ish function that is meant to wrap / extend profile.nvim.
---
--- Reference:
---     [profile.nvim](https://github.com/stevearc/profile.nvim)
---

local instrument = require("mega.busted._vendors.profile.instrument")
local profile = require("mega.busted._vendors.profile")

local M = {}

---@return profile.Profiler # Create an instance that can be used by mega.busted.
function M.initialize_profiler()
    -- NOTE: Don't profile the unittest framework or its dependencies
    local profiler = profile
    profiler.ignore("busted*")
    profiler.ignore("mega.busted.*")
    profiler.ignore("mega.logging.*")

    instrument("*")

    return profiler
end

return M
