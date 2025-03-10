--- A modified `busted` unittest suite runner.
---
--- It runs tests multiple times and, each time, records profiler and timing results.
---

local _CURRENT_DIRECTORY =
    vim.fs.dirname(vim.fs.joinpath(vim.fn.getcwd(), debug.getinfo(1, "S").source:match("@(.*)$")))
local _ROOT = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(_CURRENT_DIRECTORY)))
package.path = string.format(
    "%s;%s;%s",
    vim.fs.joinpath(_ROOT, "lua", "?.lua"), -- Append this plugin's lua/ folder
    vim.fs.joinpath(_ROOT, ".dependencies", "profile.nvim", "lua", "?.lua"), -- The profiler dependency
    package.path -- The original paths
)

local helper = require("mega.busted._core.profile_using_flamegraph.helper")
local instrument = require("mega.busted._vendors.profile.instrument")
local logging = require("mega.logging")
local profile = require("mega.busted._vendors.profile")
local profile_extended = require("mega.busted._core.profile_using_flamegraph.profile_extended")

local _LOGGER = logging.get_logger("mega.busted.make_busted_profile")

local M = {}
local _P = {}

--- Add arguments that this file needs in order to time / profile the unittest suite.
function _P.append_profiler_arg_values()
    local index = #arg + 1

    if not vim.tbl_contains(arg or {}, "--ignore-lua") then
        arg[index] = "--ignore-lua"
        index = index + 1
    end

    arg[index] = "--output=mega.busted._core.profile_using_flamegraph"
end

--- Replace parts of the user's arguments with our own.
---
--- Try to keep as much of the user's data as possible.
---
function _P.bootstrap_arg()
    _P.strip_arg()
    _P.append_profiler_arg_values()
    _P.fix_arg()
end

--- Remove all positional arguments from the user's input.
function _P.clear_arg()
    for key, _ in pairs(arg or {}) do
        if key ~= 0 then
            arg[key] = nil
        end
    end
end

--- Make sure Lua `arg` is formatted correctly.
---
--- A number of edits from other functions may leave `arg` in a state where
--- some of its indices are `nil`. Busted doesn't parse that correctly so we
--- need to do some clean-up here.
---
function _P.fix_arg()
    local values = {}

    for index = 1, #arg do
        if arg[index] then
            table.insert(values, arg[index])
        end
    end

    _P.clear_arg()

    for index, value in ipairs(values) do
        arg[index] = value
    end
end

--- Delete any Lua terminal-provided arguments that we must change.
---
--- These arguments are needed by this file in order to run the unittests.
---
function _P.strip_arg()
    local count = #arg or {}
    local key = 1

    while key < count do
        local value = arg[key]

        if value:match("^--helper=") then
            arg[key] = nil
            key = key + 1
        elseif value == "--helper" then
            arg[key] = nil
            arg[key + 1] = nil
            key = key + 2
        elseif value:match("^%-o=") or value:match("^--output=") then
            arg[key] = nil
            key = key + 1
        elseif value == "-o" or value == "--output" then
            arg[key] = nil
            arg[key + 1] = nil
            key = key + 2
        else
            -- NOTE: No match was found. We'll just keep searching
            key = key + 1
        end
    end
end

--- Remember Lua's user arguments and restore them later.
---
---@param caller fun(): nil Any function to call in the middle.
---
function _P.keep_arg(caller)
    local original = vim.deepcopy(arg or {})

    caller()

    for key, value in pairs(original) do
        arg[key] = value
    end
end

--- Run the tests, once, and gather profile / timing data while we do it.
---
---@param profiler profile.Profiler The object used to record function call times.
---@param runner busted.MultiRunner A unittest suite runner to call.
---@param options busted.MultiRunnerOptions? The settings to apply to the runner.
---
function _P.profile_and_run(profiler, runner, options)
    local before = vim.uv.hrtime()
    profiler.start()
    _P.run_busted_suite(runner, options)
    profiler.stop()

    return vim.uv.hrtime() - before
end

--- Remove any caches that would prevent us from running busted multiple times.
---
--- In truth we don't know why busted was written / designed to be called only
--- once. But we can get around it by calling this function.
---
function _P.reset_busted_packages()
    package.loaded["busted"] = nil
end

--- Run the tests, once.
---
---@param runner busted.MultiRunner A unittest suite runner to call.
---@param options busted.MultiRunnerOptions? The settings to apply to the runner.
---
function _P.run_busted_suite(runner, options)
    _P.keep_arg(function()
        _P.bootstrap_arg()

        runner(vim.tbl_deep_extend("force", options or {}, { standalone = false }))
    end)
end

---@private
---@class CommonProfilerOptions
---    Basic options that can be used by most / any profiler runner.
---@field root string
---    An absolute path to the directory on-disk where files are written.
---@field allow_event fun(event: profile.Event): boolean
---    If this function returns `true` then the event will be considered for
---    summarizing timing information. If `false` then it may still be used for
---    other parts or profiling but it will not contribute to "timing.txt", for
---    example.

---@private
---@class VersionedProfilerOptions : CommonProfilerOptions
---    A profile result that is named / has extra metadata.
---@field release string?
---    A version / release tag. e.g. `"v1.2.3"`.
---@field timing_threshold integer
---    The number of (slowest function) entries to write in the output.

---@private
---@class SimpleProfilerOptions : VersionedProfilerOptions
---    Settings that profile-runners typically need. This is a base class that
---    is meant to be extended for specific use-cases.
---@field allow_nightly boolean
---    If `true`, profiler results will be returned even if Neovim nightly is
---    found. Otherwise only "stable" Neovim versions will be considered for
---    profiling and summaries.
---@field keep_temporary_files boolean
---    If `true`, don't delete any intermediary, generated files. Useful for
---    debugging. 99% of the time you want this to be `false` though.
---@field maximum_tries integer
---    This controls the number of times that tests can run before we determine
---    that we've found a "fastest" test run. The higher the value, the longer
---    but more accurate this function becomes.
---@field minimum_samples integer
---    If `false` then .png files are only written if there is enough data to
---    form a line / meaningful visual output. If `true` then the .png files
---    are always written, even if they'd produce blank graphs. Most of the
---    time you want this to be `false`, `true` is meant for debugging.
---@field table_style _TableStyle
---    Profiler summary data will be displayed as a table in this style.

---@class mega.busted.BustedProfilerOptions : SimpleProfilerOptions
---    All options used to visualize profiler results as line graph data.
---@field allowed_tags string[]
---    Get the allowes tags that may write to disk. e.g. `{"foo.*bar", "thing"}`.
---@field event_summary_filter (fun(event: profile.Event): boolean)?
---    If `true`, the given event is included during profiler summaries. If
---    `false`, it is excluded. This is useful when you want to summarize only
---    one type of profiler event when many possible types exist.
---@field keep_old_tag_directories boolean
---    If the user's busted unittests previously defined a tag, e.g. a tag called `asdf`
---    and now that tag is gone and this option is `true` then all previous profile
---    results for that tag are deleted. This is just to keep the folders as clean and
---    up-to-date as possible.

---@class mega.busted.StandaloneProfilerOptions : SimpleProfilerOptions
---    All settings needed to control a generic, terminal profile session (non-busted).

--- Run the unittest multiple times until a "fastest time" is found.
---
--- The logic works like this:
---
--- - Run tests
--- - Get the total test elapsed time
--- - Set our "number of tries" time to `options.maximum_tries`
--- - If the elapsed time is equal to or took longer compared to the previous best
---     - Decrement our "number of tries" counter
--- - If the elapsed time is less than the previous best...
---     - Record this elapsed time as the previous best
---     - Reset the "number of tries" counter back to `options.maximum_tries`.
--- - If "number of tries" hits zero, then we've found the fastest time.
---
--- Raises:
---     If `options.maximum_tries` is invalid.
---
---@param profiler profile.Profiler
---    The object used to record function call times.
---@param options mega.busted.BustedProfilerOptions
---    All options used to visualize profiler results as line graph data.
---@private
---
function M._main(profiler, options)
    local release = options.release
    local root = options.root
    local counter = options.maximum_tries
    local fastest_time = 2 ^ 1023
    local fastest_events = nil

    while true do
        _P.reset_busted_packages()
        local runner = require("mega.busted._core.multi_runner")
        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast runner busted.MultiRunner

        local duration = _P.profile_and_run(profiler, runner, { release = release, output_handler_root = root })

        if duration < fastest_time then
            _LOGGER:fmt_debug('Faster time found. New: "%s". Old: "%s".', duration, fastest_time)

            counter = options.maximum_tries
            fastest_time = duration
            fastest_events = vim.deepcopy(instrument.get_events())
        else
            counter = counter - 1
        end

        if counter == 0 then
            _LOGGER:debug("Reached end of the profiler tests.")

            break
        end
    end

    if not fastest_events then
        error("Something went wrong. We didn't find any profiler events to record.", 0)
    end

    local benchmarks = vim.fs.joinpath(root, "benchmarks")
    helper.write_busted_summary_directory(
        profile,
        fastest_events,
        nil,
        vim.tbl_deep_extend("force", options, { root = vim.fs.joinpath(benchmarks, "all") })
    )
    helper.write_tags_directory(
        profile,
        fastest_events,
        nil,
        vim.tbl_deep_extend("force", options, { root = vim.fs.joinpath(benchmarks, "tags") })
    )
    _LOGGER:fmt_info('Finished writing all of "%s" directory.', benchmarks)
end

--- Run these tests.
function M.main()
    local options = helper.get_busted_environment_variable_data()

    helper.validate_gnuplot()

    local profiler = profile_extended.initialize_profiler()

    M._main(profiler, options)
end

return M
