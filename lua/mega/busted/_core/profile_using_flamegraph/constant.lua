-- TODO: Docsrting

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
