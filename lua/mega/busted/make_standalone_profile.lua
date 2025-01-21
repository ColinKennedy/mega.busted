--- Runs the given command(s) and profiles the result.
---
--- Example:
---     make_standalone_profile 'require("some.important.module").main()'
---
---@module 'mega.busted.make_busted_profile'
---

local helper = require("mega.busted._core.profile_using_flamegraph.helper")
local instrument = require("mega.busted._vendors.profile.instrument")
local logging = require("mega.logging")
local profile = require("mega.busted._vendors.profile")

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
local function main(input)
    input = input or arg

    if not input then
        error("Please provide at least one Lua command to execute.", 0)
    end

    local options = helper.get_standalone_environment_variable_data()

    -- NOTE: Don't profile the unittest framework
    local profiler = profile
    profiler.ignore("mega.busted*")

    instrument("*")

    profiler.start()
    _run_lua_commands(arg)
    profiler.stop()

    local events = instrument.get_events()

    local root = options.root
    local benchmarks = vim.fs.joinpath(root, "benchmarks")

    local all_options = vim.tbl_deep_extend("force", options, { root = vim.fs.joinpath(benchmarks, "all") })
    ---@cast all_options CommonProfilerOptions

    helper.write_standalone_summary_directory(profile, events, nil, all_options)
    _LOGGER:fmt_info('Finished writing all of "%s" directory.', benchmarks)
end


main()
