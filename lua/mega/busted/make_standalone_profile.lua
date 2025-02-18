--- Runs the given command(s) and profiles the result.
---
--- Example:
---     nvim -l make_standalone_profile.lua 'require("some.important.module").main()'
---

local helper = require("mega.busted._core.profile_using_flamegraph.helper")
local instrument = require("mega.busted._vendors.profile.instrument")
local logging = require("mega.logging")
local profile = require("mega.busted._vendors.profile")

local M = {}

local _LOGGER = logging.get_logger("mega.busted.make_standalone_profile")

--- Parse and run Lua `text` source code.
---
--- Raises:
---     If `text` cannot be executed as Lua code.
---
---@param text string[] All of the Lua commands to run.
---
local function _run_lua_commands(text)
    local commands = vim.fn.join(text, "\n")
    _LOGGER:fmt_debug('Got "%s" commands.', commands)

    local caller = loadstring(commands)

    if not caller then
        error(string.format('Commands "%s" could not be loaded as Lua code.', commands), 0)
    end

    caller()
end

--- Collect all lua commands, profile them, and then write the profiler results to-disk.
---
--- Raises:
---     If the user does not provide at least one Lua command to run.
---
---@param input string[] All of the Lua command(s) to execute.
---
function M.main(input)
    if not input or vim.tbl_isempty(input) then
        error("Please provide at least one Lua command to execute.", 0)
    end

    local options = helper.get_standalone_environment_variable_data()

    -- NOTE: Don't profile the unittest framework or its dependencies
    -- TODO: Make common function for this later
    local profiler = profile
    profiler.ignore("busted*")
    profiler.ignore("mega.busted.*")
    profiler.ignore("mega.logging.*")

    instrument("*")

    profiler.start()
    _run_lua_commands(input)
    profiler.stop()

    local events = instrument.get_events()

    local root = options.root
    local name = "standalone"
    local benchmarks = vim.fs.joinpath(root, "benchmarks", name)

    if vim.fn.isdirectory(benchmarks) ~= 1 then
        vim.fn.mkdir(benchmarks, "p")
    end

    local all_options = vim.tbl_deep_extend("force", options, {
        release = name,
        root = benchmarks,
        timing_threshold = 20,
    })
    ---@cast all_options VersionedProfilerOptions

    helper.write_standalone_summary_directory(events, nil, all_options)
    helper.write_flamegraph(profiler, events, vim.fs.joinpath(benchmarks, helper.FileName.flamegraph))
    helper.write_profile_summary(
        all_options.release,
        events,
        vim.fs.joinpath(benchmarks, helper.FileName.profile),
        all_options.allow_event
    )

    _LOGGER:fmt_info('Finished writing all of "%s" directory.', benchmarks)
end

return M
