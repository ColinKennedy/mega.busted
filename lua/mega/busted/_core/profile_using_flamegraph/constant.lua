--- Useful symbols to re-use in other Lua files.

local M = {}

---@enum _ProfileCategory
M.Category = {
    describe = "describe",
    file = "file",
    start = "start",
    test = "test",
    ["function"] = "function",

    error = "error",
    failure = "failure",
}

return M
