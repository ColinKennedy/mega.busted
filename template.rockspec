rockspec_format = "3.0"
package = "mega.busted"
version = "scm-1"

local user = "ColinKennedy"

description = {
    homepage = "https://github.com/" .. user .. "/" .. package,
    labels = { "neovim", "neovim-plugin", "busted" },
    license = "MIT",
    summary = 'Neovim busted unittest extensions',
}

dependencies = { "busted >= 2.0, < 3.0" }

test_dependencies = { "lua >= 5.1, < 6.0", "nlua >= 0.2, < 1.0" }

-- Reference: https://github.com/luarocks/luarocks/wiki/test#test-types
test = { type = "busted" }

source = {
    url = "git://github.com/" .. user .. "/" .. package,
}

build = {
    type = "builtin",
}
