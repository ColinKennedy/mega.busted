--- Make sure environment variables validation works as expected.

local make_busted_profile = require("mega.busted.make_busted_profile")
local make_standalone_profile = require("mega.busted.make_standalone_profile")

---@type table<string, string>
local _ENVIRONMENT_VARIABLES = {}

local _ORIGINAL_BUSTED_PROFILE_MAIN_FUNCTION = make_busted_profile._main
local _ORIGINAL_STANDALONE_PROFILE_MAIN_FUNCTION = make_standalone_profile._main

--- Reference:
---     https://github.com/neovim/neovim/issues/32550
---
local function _setenv(key, value)
    vim.cmd(string.format('let $%s = "%s"', key, value))
end

local function _add_minimal_environment_variables()
    _setenv("BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH", "foo")
end

--- Run the busted profiler and make sure it fails.
---
---@param message string The expected message or sub-message to find in the error.
---
local function _assert_busted_test_failure(message)
    local success, _ = pcall(function()
        make_busted_profile.main()
    end)

    if success then
        error(string.format('Test did not fail. We did not see a "%s" error message.', message))
    end
end

--- Run the standalone profiler and make sure it fails.
---
---@param message string The expected message or sub-message to find in the error.
---
local function _assert_standalone_test_failure(message)
    assert.has_error(function()
        make_standalone_profile.main({ "print('Hello, World!')" })
    end, message)
end

--- Run the standalone & busted profiler and make sure both fais.
---
---@param message string The expected message or sub-message to find in the error.
---
local function _assert_test_failure(message)
    _assert_busted_test_failure(message)
    _assert_standalone_test_failure(message)
end

--- Disable busted & standalone runners for unittests.
local function _mock_main()
    ---@diagnostic disable-next-line: duplicate-set-field
    make_busted_profile._main = function() end
    ---@diagnostic disable-next-line: duplicate-set-field
    make_standalone_profile._main = function() end
end

--- Delete all environment variables and restore the old, saved variables from before.
local function _restore_environment_variables()
    -- NOTE: Clear all environment variables so we can restore them
    for key, _ in pairs(vim.fn.environ()) do
        vim.uv.os_unsetenv(key)
    end

    for key, value in pairs(_ENVIRONMENT_VARIABLES) do
        _setenv(key, value)
    end
end

--- Get the original functions back, in case we need them for other unittests.
local function _restore_main()
    make_busted_profile._main = _ORIGINAL_BUSTED_PROFILE_MAIN_FUNCTION
    make_standalone_profile._main = _ORIGINAL_STANDALONE_PROFILE_MAIN_FUNCTION
end

--- Keep track of all environment variables so we can replace during unittests, safely.
local function _save_environment_variables()
    _ENVIRONMENT_VARIABLES = {}

    for key, value in pairs(vim.fn.environ()) do
        _ENVIRONMENT_VARIABLES[key] = value
    end
end

before_each(function()
    _save_environment_variables()
    _mock_main()
end)
after_each(function()
    _restore_environment_variables()
    _restore_main()
end)

describe("environment variable validation", function()
    before_each(_add_minimal_environment_variables)

    describe("BUSTED_PROFILER_ALLOW_NIGHTLY", function()
        it("errors if not 0 or 1", function()
            _setenv("BUSTED_PROFILER_ALLOW_NIGHTLY", "3")
            _assert_test_failure('$BUSTED_PROFILER_ALLOW_NIGHTLY must be 0 or 1. Got "3" number.')

            _setenv("BUSTED_PROFILER_ALLOW_NIGHTLY", "ttt")
            _assert_test_failure('$BUSTED_PROFILER_ALLOW_NIGHTLY must be 0 or 1. Got "ttt" unknown value.')
        end)
    end)

    describe("BUSTED_PROFILER_MAXIMUM_TRIES", function()
        it("errors if not 1-or-more", function()
            _setenv("BUSTED_PROFILER_MAXIMUM_TRIES", "0")
            _assert_test_failure('$BUSTED_PROFILER_MAXIMUM_TRIES must be 1-or-more. Got "0" value.')

            _setenv("BUSTED_PROFILER_MAXIMUM_TRIES", "ttt")
            _assert_test_failure('$BUSTED_PROFILER_MAXIMUM_TRIES must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("BUSTED_PROFILER_MINIMUM_SAMPLES", function()
        it("errors if not 1-or-more", function()
            _setenv("BUSTED_PROFILER_MINIMUM_SAMPLES", "0")
            _assert_test_failure('$BUSTED_PROFILER_MINIMUM_SAMPLES must be 1-or-more. Got "0" value.')

            _setenv("BUSTED_PROFILER_MINIMUM_SAMPLES", "ttt")
            _assert_test_failure('$BUSTED_PROFILER_MINIMUM_SAMPLES must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("BUSTED_PROFILER_TIMING_THRESHOLD", function()
        it("errors if not 1-or-more", function()
            _setenv("BUSTED_PROFILER_TIMING_THRESHOLD", "0")
            _assert_test_failure('$BUSTED_PROFILER_TIMING_THRESHOLD must be 1-or-more. Got "0" value.')

            _setenv("BUSTED_PROFILER_TIMING_THRESHOLD", "ttt")
            _assert_test_failure('$BUSTED_PROFILER_TIMING_THRESHOLD must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("BUSTED_PROFILER_KEEP_TEMPORARY_FILES", function()
        it("errors if not 0 or 1", function()
            _setenv("BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "2")
            _assert_test_failure('$BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "2" number.')

            _setenv("BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "-1")
            _assert_test_failure('$BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "-1" number.')

            _setenv("BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "ttt")
            _assert_test_failure('$BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "ttt" unknown value.')
        end)
    end)
end)
