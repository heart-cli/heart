-- utils.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local pl_app = require 'pl.app'

local logger = require 'logger'

local utils = {}

function utils.printversion()
    logger.printf("Love2D Distribuitor v%s", _LOVED_VERSION)
end

-- Gets the architecture of the machine
function utils.getarchitecture()
    local arch = ''

    if pl_app.platform() == 'Windows' then
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
    local lua_version = _VERSION:match("%d+%.%d+")
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

return utils
