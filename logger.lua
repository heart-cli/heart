-- logger.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local app = require 'pl.app'

-- These codes are for set printing styles in the output text
-- This must be concatenate as '^ESC[*code*m
local codes = {
    -- Reset all style and colour text
    reset = 0,
    -- text styles
    styles = {
      Bold      = 1,
      Underline = 4,
      Inverse   = 7
    },
    -- foreground colours
    -- background colours are code+10
    colors = {
      Black       = 30,
      DarkRed     = 31,
      DarkGreen   = 32,
      DarkYellow  = 33,
      DarkBlue    = 34,
      DarkMagenta = 35,
      DarkCyan    = 36,
      DarkGray    = 90,
      Red         = 91,
      Green       = 92,
      Yellow      = 93,
      Blue        = 94,
      Magenta     = 95,
      Cyan        = 96,
      Gray        = 37,
      White       = 97
    }
}

local logger = {}

function logger.print_unix_text(str, params)
    local formats = ''

    if params.fg or params.bg or params.style then
        formats = formats .. '\27['

        if params.style and codes.style[params.style] then
            formats = formats .. tostring(codes.style[params.style])
        end

        if params.fg and codes.colors[params.fg] then
            if params.style then formats = formats .. ';' end

            formats = formats .. tostring(codes.colors[params.fg])
        end

        if params.bg and codes.colors[params.bg] then
            if params.style or params.fg then formats = formats .. ';' end

            formats = formats .. tostring(codes.colors[params.bg] + 10)
        end

        formats = formats .. 'm'
    end

    io.write(formats .. str)

    if params.fg or params.bg or params.style then
        io.write('\27[' .. tostring(codes.reset) .. 'm')
    end

    if params.endline then
        io.write('\n')
    end
end

function logger.print_win32_text(str, params)
    if _WIN32_ANSI_ESCAPE_SUPPORT then
        logger.print_unix_text(str, params)
    else
        io.write(str)
        if params.endline then io.write('\n') end
    end
end

function logger.resetline()
    if string.lower(app.platform()) == 'windows' then
        if _WIN32_ANSI_ESCAPE_SUPPORT then
            io.write('\r\27[K')
        else
            io.write('\n')
        end
    else
        io.write('\r\27[K')
    end
end

function logger.echo(str, params)
    if params == nil then params = {} end
    if params.endline == nil then params.endline = true end
    if str == nil then str = '' end

    if app.platform() == 'Windows' then
        logger.print_win32_text(str, params)
    else
        logger.print_unix_text(str, params)
    end
end

function logger.printf(msg, ...)
    local args = {...}
    local n_args = #args
    local params = {}

    if n_args > 0 and type(args[1]) == 'table' then
        params = args[1]
        args = {unpack(args, 2)}
        n_args = n_args - 1
    end

    if n_args > 0 then msg = string.format(msg, unpack(args)) end

    logger.echo(msg, params)
end

function logger.datemark()
    if _DEBUG then
        logger.echo(os.date('!%a %d %b %Y %X'), {fg = 'DarkYellow', endline = false})
        logger.echo(' - ', {endline = false})
    end
end

function logger.log(msg, ...)
    local args = {...}
    local n_args = #args
    if n_args > 0 then msg = string.format(msg, unpack(args)) end

    logger.datemark()

    if _DEBUG then logger.echo('info - ', {endline = false}) end
    logger.printf(msg, ...)
end

function logger.debug(msg, ...)
    if _DEBUG then
        local args = {...}
        local n_args = #args
        if n_args > 0 then msg = string.format(msg, unpack(args)) end

        logger.datemark()

        logger.printf('debug - %s', {fg = 'DarkGray'}, msg)
    end
end

function logger.warning(msg, ...)
    local args = {...}
    local n_args = #args
    if n_args > 0 then msg = string.format(msg, unpack(args)) end

    logger.datemark()

    local token = ':'

    if _DEBUG then token = ' -' end

    logger.printf('warning%s %s', {fg = 'DarkYellow'}, token, msg)
end

function logger.error(msg, ...)
    local args = {...}
    local n_args = #args
    local exit = false
    local show_traceback = false

    if n_args > 0 then
      if type(args[1]) == 'table' then
        exit = args[1].exit or exit
        show_traceback = args[1].show_traceback or show_traceback
        msg = string.format(msg, unpack(args, 2))
      else
        msg = string.format(msg, unpack(args))
      end
    end

    logger.datemark()

    local token = ':'
    if _DEBUG then token = ' -' end
    logger.printf('error%s %s', {fg = 'DarkRed'}, token, msg)

    if exit then
        if show_traceback then print(debug.traceback()) end
        os.exit(exit)
    end
end

return logger
