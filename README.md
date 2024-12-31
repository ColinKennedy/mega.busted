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
