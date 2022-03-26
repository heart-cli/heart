package = "loved"
version = "1.0-1"
source = {
   url = "git+https://github.com/NEKERAFA/loved.git"
}
description = {
   summary = "A command-line (CLI) tool for creating LÖVE games",
   detailed = [[
      Love Distributor is a command-line interface (CLI) toolchain for
      creating, building and running LÖVE games.
   ]],
   maintainer = "Rafael Alcalde Azpiazu <nekerafa@gmail.com>",
   license = "GPL-3"
}
dependencies = {
   "lua 5.1",
   "luafilesystem >= 1.8.0-1",
   "luasocket >= 3.0rc1-2",
   "luasec >= 1.0.2-1",
   "penlight >= 1.12.0-2"
}
build = {
   type = "builtin",
   modules = {
      ["libraries.json.json"] = "libraries/json/json.lua",
      ["loved.commands.new_project"] = "loved/commands/new_project.lua",
      ["loved.connections"] = "loved/connections.lua",
      ["loved.logger"] = "loved/logger.lua",
      ["loved.utils"] = "loved/utils.lua"
   },
   install = {
      bin = {
         loved = "loved.lua"
      }
   }
}
