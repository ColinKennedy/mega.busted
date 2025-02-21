--- Make sure environment variables validation works as expected.

local make_busted_profile = require("mega.busted.make_busted_profile")
local make_standalone_profile = require("mega.busted.make_standalone_profile")

local _ORIGINAL_BUSTED_PROFILE_MAIN_FUNCTION = make_busted_profile._main
local _ORIGINAL_STANDALONE_PROFILE_MAIN_FUNCTION = make_standalone_profile._main

local _P = {}

local _ENVIRONMENT_VARIABLE_NAMES = {
    "MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY",
    "MEGA_BUSTED_PROFILER_MAXIMUM_TRIES",
    "MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES",
    "MEGA_BUSTED_PROFILER_TIMING_THRESHOLD",
    "MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES",
}

--- Set any variable that will not affect tests but is required by mega.busted.
function _P.add_minimal_environment_variables()
    _P.setenv("MEGA_BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH", "foo")
end

--- Run the busted profiler and make sure it fails.
---
---@param message string The expected message or sub-message to find in the error.
---
function _P.assert_busted_test_failure(message)
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
function _P.assert_standalone_test_failure(message)
    assert.has_error(function()
        make_standalone_profile.main({ "print('Hello, World!')" })
    end, message)
end

--- Run the standalone & busted profiler and make sure both fais.
---
---@param message string The expected message or sub-message to find in the error.
---
function _P.assert_test_failure(message)
    _P.assert_busted_test_failure(message)
    _P.assert_standalone_test_failure(message)
end

--- Disable busted & standalone runners for unittests.
function _P.mock_main()
    ---@diagnostic disable-next-line: duplicate-set-field
    make_busted_profile._main = function() end
    ---@diagnostic disable-next-line: duplicate-set-field
    make_standalone_profile._main = function() end
end

--- Delete all environment variables and restore the old, saved variables from before.
function _P.reset_environment_variables()
    for _, key in ipairs(_ENVIRONMENT_VARIABLE_NAMES) do
        _P.unsetenv(key)
    end
end

--- Get the original functions back, in case we need them for other unittests.
function _P.restore_main()
    make_busted_profile._main = _ORIGINAL_BUSTED_PROFILE_MAIN_FUNCTION
    make_standalone_profile._main = _ORIGINAL_STANDALONE_PROFILE_MAIN_FUNCTION
end

--- Set the `key` environment variable to `value`.
---
--- Ideally we shouldn't need this function. Only until Neovim fixes its API.
--- See the reference for details.
---
--- Reference:
---     https://github.com/neovim/neovim/issues/32550
---
---@param key string The environment variable to set. e.g. `"FOO"`.
---@param value string The new value pair. e.g. `"bar"`.
---
function _P.setenv(key, value)
    vim.cmd(string.format('let $%s = "%s"', key, value))
end

--- Remove the value for environment variable `key`.
---
--- Ideally we shouldn't need this function. Only until Neovim fixes its API.
--- See the reference for details.
---
--- Reference:
---     https://github.com/neovim/neovim/issues/32550
---
---@param key string The environment variable to set. e.g. `"FOO"`.
---
function _P.unsetenv(key)
    vim.cmd(string.format("unlet $%s", key))
end

before_each(_P.mock_main)

after_each(function()
    _P.reset_environment_variables()
    _P.restore_main()
end)

describe("environment variable validation", function()
    before_each(_P.add_minimal_environment_variables)

    describe("MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY", function()
        it("errors if not 0 or 1", function()
            _P.setenv("MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY", "3")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY must be 0 or 1. Got "3" number.')

            _P.setenv("MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY", "ttt")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_ALLOW_NIGHTLY must be 0 or 1. Got "ttt" unknown value.')
        end)
    end)

    describe("MEGA_BUSTED_PROFILER_MAXIMUM_TRIES", function()
        it("errors if not 1-or-more", function()
            _P.setenv("MEGA_BUSTED_PROFILER_MAXIMUM_TRIES", "0")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_MAXIMUM_TRIES must be 1-or-more. Got "0" value.')

            _P.setenv("MEGA_BUSTED_PROFILER_MAXIMUM_TRIES", "ttt")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_MAXIMUM_TRIES must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES", function()
        it("errors if not 1-or-more", function()
            _P.setenv("MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES", "0")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES must be 1-or-more. Got "0" value.')

            _P.setenv("MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES", "ttt")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_MINIMUM_SAMPLES must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("MEGA_BUSTED_PROFILER_TIMING_THRESHOLD", function()
        it("errors if not 1-or-more", function()
            _P.setenv("MEGA_BUSTED_PROFILER_TIMING_THRESHOLD", "0")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_TIMING_THRESHOLD must be 1-or-more. Got "0" value.')

            _P.setenv("MEGA_BUSTED_PROFILER_TIMING_THRESHOLD", "ttt")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_TIMING_THRESHOLD must be 1-or-more. Got "ttt" unknown value.')
        end)
    end)

    describe("MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES", function()
        it("errors if not 0 or 1", function()
            _P.setenv("MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "2")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "2" number.')

            _P.setenv("MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "-1")
            _P.assert_test_failure('$MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "-1" number.')

            _P.setenv("MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES", "ttt")
            _P.assert_test_failure(
                '$MEGA_BUSTED_PROFILER_KEEP_TEMPORARY_FILES must be 0 or 1. Got "ttt" unknown value.'
            )
        end)
    end)
end)
