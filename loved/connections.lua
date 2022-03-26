-- connections.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local pl_app = require 'pl.app'
local pl_pretty = require 'pl.pretty'
local socket = require 'socket'
local socket_url = require 'socket.url'
local ssl = require 'ssl'

local logger = require 'loved.logger'
local utils = require 'loved.utils'

-- Configuration of SSL Socket
local ssl_params = {
    mode = 'client',
    protocol = 'any',
    options = 'all',
    verify = 'none'
}

local function get_min_width(downloaded, length, title)
    local msg = '||'

    if length ~= nil then
        msg = string.format('%s %i%%', msg, downloaded / length * 100)
    end

    msg = string.format('%s %s', msg, pl_pretty.number(downloaded, 'M', 2))

    if length ~= nil then
        msg = string.format('%s / %s ', msg, pl_pretty.number(length, 'M', 2))
    end

    msg = string.format('%s - Downloading %s', msg, title)

    return string.len(msg) + 10
end

--- Print a progress information
--  @param int downloaded Current downloaded size
--  @param int length Size of file to download
--  @param int title Name of download
local function progress_info(downloaded, length, title)
    local min_width = get_min_width(downloaded, length, title)
    local width = math.max(utils.gettermwidth() - min_width, 20)

    local progress_bar = ''
    local progress_msg = ''

    if length ~= nil then
        local pos = math.modf(downloaded / length * width)

        progress_bar = '|'

        for i = 0, width do
            if i <= pos then
                progress_bar = progress_bar .. '#'
            else
                progress_bar = progress_bar .. ' '
            end
        end
        progress_bar = progress_bar .. '|'

        progress_bar = string.format('%s %i%%', progress_bar, downloaded / length * 100)
        progress_msg = ' - '
    end

    progress_msg = string.format('%s%s ', progress_msg, pl_pretty.number(downloaded, 'M', 2))

    if length ~= nil then
        progress_msg = string.format('%s/ %s ', progress_msg, pl_pretty.number(length, 'M', 2))
    end

    progress_msg = string.format('%s- Downloading %s', progress_msg, title)

    logger.echo(string.format('\r%s', progress_bar), { fg = "Green", endline = false })
    logger.echo(string.format('%s\r', progress_msg), { endline = false })
end

local function parse_response(response)
    local version, status, reason = string.match(response, '(HTTP/%d%.%d) (%d%d%d) (.*)')

    return {
        version = version,
        status = status,
        reason = reason
    }
end

local function get_response(conn)
    local response, status = conn:receive('*l')

    if response == nil then
        if status == 'closed' then
            return nil, 'cannot get response (closed connection)'
        elseif status == 'timeout' then
            return nil, 'cannot get response (timeout)'
        else
            return nil, status
        end
    end

    return parse_response(response)
end

local function parse_headers(headers)
    local headers_obj = {}

    logger.debug('Headers:')
    for _, header in pairs(headers) do
        key, value = string.match(header, "^([%w%-]+): (.+)")
        logger.debug('%s: %s', key, value)
        headers_obj[key] = value
    end

    return headers_obj
end

local function get_headers(conn)
    local headers = {}
    while true do
        local response, status = conn:receive('*l')

        if response then
            if response == '' then break end
            table.insert(headers, response)
        else
            if status == 'closed' then
                return nil, 'cannot get headers (closed connection)'
            elseif status == 'timeout' then
                return nil, 'cannot get headers (timeout)'
            else
                return nil, status
            end
        end
    end

    return parse_headers(headers)
end

--- Routine that download the file
--  @param conn Current connection socket
--  @return Downloaded file size if the file is downloading now, and result and status of connection otherwise
local function async_receive(conn, headers)
    -- Sets 1 second to get timeout
    conn:settimeout(1000, 't')

    local buffer = ''
    local total = 0
    local status = nil
    local timeout = 0
    local content_length = tonumber(headers['Content-Length'])
    local content_reminder = 1024

    while true do
        -- If exists 'Content-Length' header, checks the reminded size
        if content_length then content_reminder = content_length - total end

        -- Downloading 8 KB by default
        local bytes, msg, partial_bytes = conn:receive(math.min(8192, content_reminder))

        if bytes ~= nil then
            buffer = buffer .. bytes
            total = total + #bytes
            
            -- If not exists 'Content-Length' header, adds the partial results if exists
            if not content_length and partial_bytes then buffer = buffer .. partial_bytes end
            if timeout > 0 then timeout = 0 end
        else
            if msg == 'timeout' then
                -- If the server use HTTP/1.1 or above and doesn't pay attetion to our petition
                if content_length and content_length == total then
                    status = 'closed'
                    break
                end
                
                timeout = timeout + 1
                
                -- 1 minute of timeout
                if timeout == 60 then
                    status = 'timeout'
                    break
                end
            else
                status = msg
                break
            end
        end

        coroutine.yield(total)
    end

    return buffer, status
end

--- Execute the async task and print status information
--  @param conn Current connection socket
--  @param table headers HTTP headers
--  @param title The download name 
local function receive_file(conn, headers, title)
    local content = nil

    local async_routine = coroutine.create(async_receive)

    while true do
        local ok, result, status = coroutine.resume(async_routine, conn, headers)
        if not ok then error(result) end

        if status == nil then
            progress_info(result, tonumber(headers['Content-Length']), title or headers['Host'] or 'file')
            --logger.resetline()
        else
            logger.echo('')

            if status == 'closed' then
                content = result
                break
            elseif status == 'timeout' then
                conn:close()
                return false, 'cannot download file (timeout)'
            end
        end
    end
    conn:close()

    return true, content
end

local function send_headers(conn, host, path, query)
    local petition_url = path or '/'
    if query then petition_url = petition_url .. '?' .. query end

    local petition = string.format('GET %s HTTP/1.0', petition_url)
    local host_header = string.format('Host: %s', host)
    local user_agent_header = string.format('User-Agent: Mozilla/5.0 (%s %s) Loved/%s Lua/%s', pl_app.platform(), utils.getarchitecture(), _LOVED_VERSION, utils.getluaversion())

    logger.debug(petition)
    conn:send(petition .. '\r\n')
    logger.debug(host_header)
    conn:send(host_header .. '\r\n')
    logger.debug(user_agent_header)
    conn:send(user_agent_header .. '\r\n\r\n')
end

local connections = {}

--- Do a get http petition as intent
-- @param string url_addr The url to get the petition
-- @param string title The name of download
function connections.get(url_addr, title)
    local redirects = {}
    local moved = false

    local function intent()
        local parsed_url = socket_url.parse(url_addr)

        if not parsed_url.host then
            parsed_url.host = parsed_url.path
            parsed_url.path = nil
        end

        for k, v in pairs(parsed_url) do
            logger.debug('%s\t%s', k, v)
        end

        if not moved then
            logger.log('Connecting to ' .. (parsed_url.host or 'nil'))
        else
            logger.debug('Moved to ' .. (parsed_url.host or 'nil'))
        end

        local conn = socket.tcp()
        conn:settimeout(60000, 't')

        if not parsed_url.scheme or parsed_url.scheme == 'http' then
            conn:connect(parsed_url.host, 80)
         elseif parsed_url.scheme == 'https' then
            conn:connect(parsed_url.host, 443)
            local msg = ''
            conn, msg = ssl.wrap(conn, ssl_params)
            if not conn then utils.err('cannot configure ssl (%s)', msg) end
            conn:dohandshake()
        else
            return false, string.format('cannot download %s (scheme not supported)', url_addr)
        end

        if conn then
            logger.debug('Downloading ' .. (parsed_url.path or '/'))
            logger.debug('Sending headers...')
            send_headers(conn, parsed_url.host, parsed_url.path, parsed_url.query)

            logger.debug('Getting headers...')
            local response, msg_response = get_response(conn)
            if response == nil then
                conn:close()
                return false, msg_response
            end

            local headers, msg_headers = get_headers(conn)
            if headers == nil then
                conn:close()
                return false, msg_headers
            end

            if response.status ~= '200' then
                while true do
                    local _, status = conn:receive()
                    if status ~= nil and status == 'closed' then break end
                end

                conn:close()
                if response.status == '301' or response.status == '302' then
                    if headers['Location'] == url_addr or redirects[headers['Location']] then
                        return false, 'cannot download file (location already visited)'
                    end

                    moved = true
                    redirects[headers['Location']] = true
                    url_addr = headers['Location']
                    return intent()
                else
                    return false, string.format('cannot download file (%s %s)', response.status, response.reason)
                end
            end

            logger.debug('Getting content...')
            return receive_file(conn, headers, title)
        end

        return false, 'cannot connect to ' .. (parsed_url.host or 'nil')
    end

    return intent
end

--- Dispatch a intent and return the result
--  @param function intent
function connections.await(intent)
    return function (callbacks)
        local result = {intent()}

        if result[1] == true then
            if callbacks.ok then return callbacks.ok(unpack(result, 2)) end
        elseif result[1] == false then
            if callbacks.err then return callbacks.err(unpack(result, 2)) end
        end
    end
end

function connections.awaitall(intents)
    local return_values = {}

    return function (callbacks)
        for name, intent in pairs(intents) do
            return_values[name] = connections.await(intent) {
                ok = function(...)
                    if callbacks.ok then return callbacks.ok(name, ...) end
                end,

                err = function(...)
                    if callbacks.err then return callbacks.err(name, ...) end
                end
            }
        end

        return return_values
    end
end

return connections