# mega.busted

Build profiler and flamegraph visualizers for Neovim plugins with ease.


# Installation
<!-- TODO: (you) - Adjust and add your dependencies as needed here -->
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/mega.busted",
    dependencies = { "ColinKennedy/mega.logging" },
    version = "v1.*",
}
```


# Configuration
(These are default values)

TODO: Finish this

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
```

## Configuration Options - User
All settings that a user is likely to want to change.

| Name                                   | Default                              | Description                                                                                                    |
|----------------------------------------|--------------------------------------|----------------------------------------------------------------------------------------------------------------|
| BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH | ${{ github.workspace }}              | The directory on-disk where profile results are written to                                                     |
| BUSTED_PROFILER_FLAMEGRAPH_VERSION     | ${{ github.event.release.tag_name }} | The label used for graphing your profiler results. e.g. v1.2.3                                                 |
| BUSTED_PROFILER_TIMING_THRESHOLD       | 30                                   | The "top slowest" functions to display                                                                         |
| BUSTED_PROFILER_TAGGED_DIRECTORIES     | .*                                   | A comma-separated list of busted unittest tags to separately profile. See [About Tags](about-tags) for details |


## Configuration Options - Developer
All settings that a user would rarely change but a developer might change to
debug an issue.

| Name                                     | Default | Description                                                                                                                  |
|------------------------------------------|---------|------------------------------------------------------------------------------------------------------------------------------|
| BUSTED_PROFILER_KEEP_OLD_TAG_DIRECTORIES | 0       | If 0, tagged unittests that are no longer in-use will be auto-deleted. If 1, they are left untouched                         |
| BUSTED_PROFILER_KEEP_TEMPORARY_FILES     | 0       | If 0, any intermediary files during profiling are deleted. Otherwise don't delete them. This is useful for debugging issues. |
| BUSTED_PROFILER_MAXIMUM_TRIES            | 10      | The number of consecutive wins that a test suite must get before it that run is considered "fastest"                         |


# Tests
## Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


## Running
Run all tests
```sh
# Using the package manager
luarocks test --test-type busted
# Or manually
busted .
# Or with Make
make test
```

TODO: Add a simple tag

Run test based on tags
```sh
busted . --tags=simple
```


# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.

You can watch this plugin for changes by adding this URL to your RSS feed:
```
https://github.com/ColinKennedy/mega.busted/commits/main/doc/news.txt.atom
```
