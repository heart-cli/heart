-- loved.lua
-- A CLI tool to create and publish LÖVE games
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

_DEBUG = false
_WIN32_ANSI_ESCAPE_SUPPORT = true

-- Checks the source directory and configure require paths
local base_path = string.match(arg[0], '^(.*[\\/])')

for _, arg_v in ipairs(arg) do
    if arg_v == '--debug' then
        _DEBUG = true

        local lua_version = _VERSION:match('%d+%.%d+')

        package.path = string.format('%srocks/share/lua/%s/?.lua;%s',base_path or '', lua_version, package.path)
        package.path = string.format('%srocks/share/lua/%s/?/init.lua;%s',base_path or '', lua_version, package.path)
        package.cpath = string.format('%srocks/lib/lua/%s/?.so;%s',base_path or '', lua_version, package.cpath)
        package.cpath = string.format('%srocks/lib/lua/%s/?.dylib;%s',base_path or '', lua_version, package.cpath)
        package.cpath = string.format('%srocks/lib/lua/%s/?.dll;%s',base_path or '', lua_version, package.cpath)

        break
    end
end

if base_path then
    package.path = string.format('%s?.lua;%s', base_path, package.path)
end

local logger = require 'logger'
local utils = require 'utils'
local new_project = require 'commands.new_project'

_LOVED_VERSION = '1.0-beta'

local function print_usage()
    utils.printversion()
    logger.echo()
    logger.echo([[Usage: loved [command] [command-options] [arguments]

  Commands:
    new      Creates new Love2D proyect
    play     Run a Love2D project
    update   Updates Love2D project version
    version  Print the version of Loved
    help     Print this message

Typing "loved [command] help" print information about a command]])

    os.exit(0)
end

--- Prints all given arguments as error
local function print_error_args(args)
    utils.argserror(args)
    print_usage()
    os.exit(-1)
end

local function loved_main(args)
    local n_arg = #args

    if n_arg == 0 or args[1] == 'help' then
        print_usage()
    elseif args[1] == 'new' then
        local path_game = new_project.command(unpack(args, 2))
        logger.log('Project created in %s', path_game)
    --[[    utils.logger('Running project')
        run_project(path_game)
    elseif arg[1] == 'play' then
        run_project(pl_path.normcase(pl_path.normpath(arg[2])))
    ]]
    elseif args[1] == 'version' then
        utils.printversion()
    else
        print_error_args(args)
    end
end

if _DEBUG then
    loved_main({unpack(arg, 2)})
else
    loved_main(arg)
end