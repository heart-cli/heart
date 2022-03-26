-- utils.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local pl_app = require 'pl.app'

local logger = require 'loved.logger'

local utils = {
    WIN64 = 'AMD64', WIN32 = 'x86'
}

function utils.printversion()
    logger.printf("Love2D Distributor v%s", _LOVED_VERSION)
end

-- Gets the architecture of the machine
function utils.getarchitecture()
    local arch = ''

    if string.lower(pl_app.platform()) == 'windows' then
        arch = os.getenv('PROCESSOR_ARCHITECTURE')
    else
        local uname_out = io.popen('uname -m')
        arch = uname_out:read('*l')
        uname_out:close()
    end

    return arch
end

-- Gets the width of the terminal
function utils.gettermwidth()
    local width = 60

    if pl_app.platform() == 'Windows' then
    else
        local tput_out = io.popen('tput cols')
        width = tonumber(tput_out:read('*n'))
        tput_out:close()
    end

    return width
end

-- Gets the version of the lua interpreter
function utils.getluaversion()
    local lua_version = string.match(_VERSION, '%d+%.%d+')
    return lua_version
end

--- Prints all given arguments as error
function utils.argserror(args)
    local s_args = ''
    local n_args = #args

    for i, arg in ipairs(args) do
        s_args = s_args .. arg
        if i < n_args then
            s_args = s_args .. ' '
        end
    end

    logger.error('%q not recognized\n', s_args)
end

-- Parse the arguments
function utils.getargs(args, options)
    local arg = 1
    local n_args = #args
    local parsed_args = {}

    while arg <= n_args do
        if string.find(args[arg], '^%-%-') then
            local option_name = string.sub(args[arg], 3)
            local n_options = options[option_name] or 0
            if (type(n_options) == 'number') and (n_options < 0) then n_options = 0 end

            if (type(n_options) == 'number') and (n_options == 0) then
                parsed_args[option_name] = true
                arg = arg+1
            elseif (type(n_options) == 'string') and (n_options == '?') then
                if arg+1 <= n_args then
                    if string.find(args[arg + 1], '^%-%-') then
                        parsed_args[option_name] = true
                        arg = arg + 1
                    else
                        parsed_args[option_name] = args[arg+1]
                        arg = arg + 2
                    end
                else
                    parsed_args[option_name] = true
                    arg = arg + 1
                end
            elseif type(n_options) == 'number' then
                parsed_args[option_name] = {}
                local option = 1
                local next_arg = arg + 1
                
                while (next_arg <= n_args) and (option <= n_options) do
                    if string.find(args[next_arg], '^%-%-') then break end
                    
                    table.insert(parsed_args[option_name], args[next_arg])
                    option = option + 1
                    next_arg = next_arg + 1
                end
                
                if (next_arg > n_args + 1) or (option <= n_options) then
                    error(string.format('cannot parse "%s" option (expected %i params, got %i)', option_name, n_options, option-1))
                else
                    arg = next_arg
                end
            else
                error(string.format('bad argument #%i (expected number or string, got %s)', arg, type(n_options)))
            end
        else
            table.insert(parsed_args, args[arg])
            arg = arg+1
        end
    end

    return parsed_args
end

return utils
