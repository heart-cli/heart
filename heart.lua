-- heart.lua
-- a command-line toolkit for creating LÖVE games
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

_HEART_VERSION = '1.0-dev10'
_DEBUG = false
_WIN32_ANSI_ESCAPE_SUPPORT = true

-- Checks if we call the script as debugging mode and configure require paths
for _, arg_v in ipairs(arg) do
    if arg_v == '--debug' then
        local base_path = string.match(arg[0], '^(.*[\\/])')

        if base_path then
            package.path = string.format('%s?.lua;%s', base_path, package.path)
        end

        local lua_version = _VERSION:match('%d+%.%d+')

        package.path = string.format('%srocks/share/lua/%s/?.lua;%s', base_path or '', lua_version, package.path)
        package.path = string.format('%srocks/share/lua/%s/?/init.lua;%s', base_path or '', lua_version, package.path)
        package.cpath = string.format('%srocks/lib/lua/%s/?.so;%s', base_path or '', lua_version, package.cpath)
        package.cpath = string.format('%srocks/lib/lua/%s/?.dylib;%s', base_path or '', lua_version, package.cpath)
        package.cpath = string.format('%srocks/lib/lua/%s/?.dll;%s', base_path or '', lua_version, package.cpath)

        break
    end
end

local logger = require 'heart.logger'
local utils = require 'heart.utils'
local new_project = require 'heart.commands.new_project'
local show_version = require 'heart.commands.show_version'

local commands = {
    new_project, show_version
}

local function print_usage()
    local max_width = 0
    local widths = {}
    for _, command in ipairs(commands) do
        widths[command.name] = string.len(command.name)
        if max_width < widths[command.name] then
            max_width = widths[command.name]
        end
    end

    local commands_str = ''
    for _, command in ipairs(commands) do
        commands_str = string.format('%s    %s%s%s\n', commands_str, command.name, string.rep(' ', max_width + 2 - widths[command.name]), command.summary)
    end

    logger.printf("HEART v%s", _HEART_VERSION)
    logger.printf([[Usage: heart [command] [command-options] [arguments]

    A command-line toolkit for creating, running and packing LOVE games

  Commands:
%s
Typing "heart [command] help" print information about a command]], commands_str)
end

table.insert(commands, {
    name = 'help',
    summary = 'Prints this message',
    command = print_usage
})

--- Prints all given arguments as error
local function print_error_args(args)
    utils.argserror(args)
    print_usage()
    os.exit(-1)
end

local function heart_main(args)
    local n_arg = #args

    if n_arg == 0 then
        print_usage()
    elseif args[1] then
        local executed = false
        for _, command in ipairs(commands) do
            if command.name == args[1] then
                command.command(unpack(args, 2))
                executed = true
            end
        end

        if not executed then
            print_error_args(args)
        end
    end
end

for _, arg_v in ipairs(arg) do
    if arg_v == '--debug' then
        heart_main({ unpack(arg, 2) })
        os.exit(0)
    end
end

heart_main(arg)