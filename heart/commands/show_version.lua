-- commands/show_version.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local logger = require 'heart.logger'

local show_version = {
    name = 'version',
    summary = 'Prints the HEART package version',
    command = function ()
        logger.log(_HEART_VERSION)
    end
}

return show_version