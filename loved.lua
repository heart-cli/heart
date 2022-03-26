-- loved.lua
-- A CLI tool to create and publish LÖVE games
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

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

local n_arg = #arg

if n_arg == 0 or arg[1] == 'help' then
    print_usage()
elseif arg[1] == 'new' then
    local path_game = new_project.command(unpack(arg, 2))
    logger.log('Project created in %s', path_game)
--[[    utils.logger('Running project')
    run_project(path_game)
elseif arg[1] == 'play' then
    run_project(pl_path.normcase(pl_path.normpath(arg[2])))
]]
elseif arg[1] == 'version' then
    utils.printversion()
else
    print_error_args(arg)
end
