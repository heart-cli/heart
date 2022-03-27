-- commands/show_version.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local logger = require 'loved.logger'

local show_version = {
    name = 'version',
    summary = 'Prints the Loved package version',
    command = function ()
        logger.log(_LOVED_VERSION)
    end
}

return show_version