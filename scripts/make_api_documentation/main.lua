--- The file that auto-creates documentation for `mega.busted`.

local vimdoc = require("mega.vimdoc")

---@return string # Get the directory on-disk where this Lua file is running from.
local function _get_script_directory()
    local path = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' at the start

    return path:match("(.*/)")
end

--- Convert the files in this plug-in from Lua docstrings to Vimdoc documentation.
local function main()
    local current_directory = _get_script_directory()
    local root = vim.fs.normalize(vim.fs.joinpath(current_directory, "..", ".."))

    vimdoc.make_documentation_files({
        {
            source = vim.fs.joinpath(root, "lua", "mega", "busted", "make_busted_profile.lua"),
            destination = vim.fs.joinpath(root, "doc", "mega_busted_make_busted_profile.txt"),
        },
        {
            source = vim.fs.joinpath(root, "lua", "mega", "busted", "make_standalone_profile.lua"),
            destination = vim.fs.joinpath(root, "doc", "mega_busted_make_standalone_profile.txt"),
        },
        {
            -- NOTE: Once profile.nvim has Vimdocs, this can be removed
            --
            -- Reference: https://github.com/stevearc/profile.nvim
            --
            source = vim.fs.joinpath(root, "lua", "mega", "busted", "_vendors", "profile_stub.lua"),
            destination = vim.fs.joinpath(root, "doc", "profile_api.txt"),
        },
    })
end

main()
