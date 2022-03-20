local pl_path = require 'pl.path'
local pl_dir = require 'pl.dir'
local pl_app = require 'pl.app'
local https = require 'ssl.https'

local json = require 'libraries.json.json'

local logger = require 'logger'
local utils = require 'utils'
local http = require 'connection'

local new_project = {}

local function print_new_project_usage()
    utils.printversion()
    logger.echo()
    logger.echo([[Usage: loved new [options] <project_name>
    Creates a new Love2D project, downloading the lasted version of Love2D and Git and installing locally
  
  Options:
    --love <path> Sets Love2D installation path. If no path added, uses a system call to invocate Love2D
    --git <path>  Sets Git installation path. If no path added, uses a system call to invocate Git
    --no-scm      Not uses SCM software
  
Typing "loved help" print information about all commands]])

    os.exit(0)
end

local function mkdir(...)
    local args = {...}
    local path_folder = ''

    for _, item in ipairs(args) do
        path_folder = pl_path.join(path_folder, item)
    end

    logger.log('Create folder %s', path_folder)
    local ok, msg = pl_dir.makepath(path_folder)
    if not ok then utils.err(msg) end
end

local function get_love_releases()
    logger.log('Getting love2d info...')

    local body, status_code = https.request('https://api.github.com/repos/love2d/love/releases?per_page=5')

    if not body then
        logger.error(status_code)
        os.exit(-1)
    end

    if status_code == '200' then
        local response = json.decode(body)
        local releases = {}

        for _, release in ipairs(response) do
            
        end

        return releases
    else
        logger.error('fetching love2d info', status_code)
        os.exit(-1)
    end
end

local function download_love(love_version, path_temp, path_loved)
    local system = pl_app.platform()
    local arch = utils.getarchitecture()
    local url = ''
    local filename = ''

    if string.find(arch, '64') then
        if system == 'Linux' then
            filename = 'love-' .. love_version .. '-linux-x86_64.AppImage'
            url = 'https://github.com/love2d/love/downloads/love-' .. love_version .. '-linux-x86_64.AppImage'
            arch = 'AppImage (Linux i686)'
        elseif system == 'Windows' then
            filename = 'love-' .. love_version .. '-win64.zip'
            url = 'https://github.com/love2d/love/downloads/love-' .. love_version .. '-win64.zip'
            arch = 'Win32'
        end
    end

    if arch == '' then
        utils.error('sorry, %s platform is not supported yet', system .. ' ' .. arch)
        os.exit(-1)
    end

    return http.dispatch(http.get(url, 'Love2D ' .. love_version .. ' ' .. arch)) {
        ok = function(content)
            local file = io.open(pl_path.join(path_temp, filename), 'wb+')
            file:write(content)
            file:flush()
            file:close()
            return true, filename
        end,
        err = function(msg)
            return false, msg
        end
    }
end

function new_project.command(...)
end

return new_project