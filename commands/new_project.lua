-- commands/new_project.lua
--
-- Under GPLv3 License
-- Copyright (c) 2020 - Rafael Alcalde Azpiazu (NEKERAFA)

local pl_path = require 'pl.path'
local pl_dir = require 'pl.dir'
local pl_app = require 'pl.app'
local pl_utils = require 'pl.utils'
local pl_pretty = require 'pl.pretty'
local https = require 'ssl.https'

local json = require 'libraries.json.json'

local logger = require 'logger'
local utils = require 'utils'
local http = require 'connections'

local new_project = {}

local function print_new_project_usage()
    utils.printversion()
    logger.echo()
    logger.echo([[Usage: loved new [options] <project_name>
    Creates a new Love2D project, downloading the lasted version of Love2D and Git and installing locally
  
  Options:
    --love <path>        Sets Love2D installation path. If no path added, uses a system call to invocate Love2D
    --version <version>  Sets the Love2D version to download
  
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

    local body, status_code = https.request('https://api.github.com/repos/love2d/love/releases')

    if not body then
        logger.error(status_code)
        os.exit(-1)
    end

    if status_code == 200 then
        local response = json.decode(body)
        local releases = {}

        for _, release in ipairs(response) do
            logger.debug(release['tag_name'])
            local release_data = { version = release['tag_name'] }

            for _, asset in ipairs(release['assets']) do
                if string.lower(pl_app.platform()) == 'linux' then
                    if string.match(asset['name'], string.format('%s.AppImage$', utils.getarchitecture())) then
                        logger.debug(asset['name'])
                        release_data.name = asset['name']
                        release_data.url = asset['browser_download_url']
                    end
                elseif string.lower(pl_app.platform()) == 'windows' then
                    if utils.getarchitecture() == utils.WIN64 and string.match(asset['name'], 'win64.zip$') then
                        logger.debug(asset['name'])
                        release_data.name = asset['name']
                        release_data.url = asset['browser_download_url']
                    end

                    if utils.getarchitecture() == utils.WIN32 and string.match(asset['name'], 'win32.zip$') then
                        release_data.name = asset['name']
                        release_data.url = asset['browser_download_url']
                    end
                end
            end

            if release_data.url then
                table.insert(releases, release_data)
            end
        end

        logger.log('Retrieved %i releases', #releases)
        return releases
    else
        logger.error('fetching love2d info: %s', { exit = -1 }, status_code)
    end
end

-- Debugging
new_project.releases = get_love_releases

local function download_love(path_temp, releases, love_version)
    local release = nil
    if love_version then
        for _, release_data in ipairs(releases) do
            if release_data.version == love_version then
                release = release_data
            end
        end

        if release == nil then
            logger.error("sorry, %s version is not supported", { exit = -1 }, love_version)
        end
    else
        release = releases[1]
    end

    return http.await(http.get(release.url, 'Love2D ' .. release.version)) {
        ok = function(content)
            local file = io.open(pl_path.join(path_temp, release.name), 'wb+')
            file:write(content)
            file:flush()
            file:close()
            return true, { version = release.version, file = release.name }
        end,
        err = function(msg)
            return false, msg
        end
    }
end

-- Debugging
new_project.download = download_love

local function extract_love(path_temp, filename, path_loved)
    local path_zipped = pl_path.join(path_temp, filename)
    local path_unzipped = pl_path.splitext(path_zipped)
    local command = string.format('%s x -o"%s" "%s"', pl_path.join('win32', '7za.exe'), path_unzipped, path_zipped)

    logger.log('Extracting %s', path_zipped)
    logger.debug(command)
    local ok, code, msg = pl_utils.execute(command)
    if not ok then
        logger.error('cannot extract %s (%s %s)', { exit = -1 }, path_zipped, tostring(code), tostring(msg))
    end

    logger.log('Installing %s', path_unzipped)
    local folder_love = pl_path.splitext(filename)
    local path_love = pl_path.join(path_loved, 'love')
    ok, msg = os.rename(pl_path.join(path_unzipped, folder_love), path_love)

    if not ok then
        logger.error('cannot copy %s to %s (%s)', { exit = -1 }, path_unzipped, path_love, msg)
    end
end

local function move_love(path_temp, filename, path_loved)
    local path_exe_temp = pl_path.join(path_temp, filename)
    local path_love = pl_path.join(path_loved, filename)

    mkdir(path_loved)

    local ok, msg = os.rename(path_exe_temp, path_love)

    if not ok then
        logger.error('cannot copy %s to %s (%s)', { exit = -1 }, path_exe_temp, path_love, msg)
    end
end

local function install_love(path_temp, filename, path_loved)
    if string.lower(pl_app.platform()) == 'windows' then
        extract_love(path_temp, filename, path_loved)
    else
        move_love(path_temp, filename, path_loved)
    end
end

local function check_love()
    local exists, _, version = pl_utils.executeex('love --version')
    version = string.gsub(version, '\n', '')
    return exists, version
end

local function loved_mkconf(love, love_version, git, path_loved)
    local configuration = { version = _LOVED_VERSION }

    if type(love) == 'boolean' then
        local _, version = check_love()
        configuration.love = { on_system = true, version = version }
    elseif type(love) == 'string' then
        configuration.love = { path = love }
        if love_version then
            configuration.love.version = love_version
        end
    end

    local conf_path = pl_path.join(path_loved, 'project.lua')
    pl_pretty.dump(configuration, conf_path)
end

local function love_mkconf(path_game)
    local conf, msg_file = io.open(pl_path.join(path_game, 'conf.lua'), 'w+')
    if not conf then utils.err(msg_file) end

    conf:write([[package.path = ']] .. string.gsub(pl_path.join('libraries', '?.lua'), '\\', '\\\\') .. [[;]] .. string.gsub(pl_path.join('libraries', '?', '?.lua'), '\\', '\\\\') .. [[;' .. package.path

function love.conf(t)
    t.window.width = 640
    t.window.height = 480
end
]])
    conf:flush()
    conf:close()
end
  
local function love_make_main_script(path_game)
    local main, msg_file = io.open(pl_path.join(path_game, 'main.lua'), 'w+')
    if not main then utils.err(msg_file) end

    main:write([[function love.draw()
    love.graphics.print("Hello world", 10, 10)
end
]])
    main:flush()
    main:close()
end

function print_new_project_usage()
    utils.print_version()
    logger.echo()
    logger.echo([[Usage: loved new [options] <project_name>
  Creates a new Love2D project, downloading the lasted version of Love2D and Git and installing locally

  Options:
    --love <path>  Sets Love2D installation path. If no path added, uses a system call to invocate Love2D

Typing "loved help" print information about all commands]])

    os.exit(0)
end

function new_project.command(...)
    local args = {...}
    local n_args = #args
    local path_game = 'love2d-game'

    if n_args == 1 and args[1] == 'help' then
        print_new_project_usage()
    elseif n_args >= 1 then
        args = utils.getargs(args, { ['love'] = '?', ['version'] = '?' })
        path_game = args[1] or path_game
        path_game = string.gsub(pl_path.normpath(path_game), '/', '\\')
    end

    mkdir(path_game)

    local path_loved = pl_path.join(path_game, '.loved')
    mkdir(path_loved)

    local love_version = false
    if not args['love'] then
        logger.log()
        logger.log('Checking Love2D...')

        local love, version = check_love()

        if love then
            logger.log('Detected %s', version)
            args['love'] = true
        else
            local releases = get_love_releases()
            if #releases == 0 then
                logger.error("sorry, %s %s platform is not supported yet", { exit = -1 }, pl_app.platform(), utils.getarchitecture())
            end

            local path_temp = pl_path.join(path_loved, 'tmp')
            mkdir(path_temp)
            logger.log('No Love2D installation detected, installing Love2D %s', args['version'] or releases[1].version)
            local ok, data = download_love(path_temp, releases, args['version'])

            if not ok then
                logger.error(data)
            end

            install_love(path_temp, data.file, path_loved)
            pl_dir.rmtree(path_temp)

            if string.lower(pl_app.platform()) == 'windows' then
                args['love'] = pl_path.join('.loved', 'love', 'love.exe')
            else
                args['love'] = pl_path.join('.loved', 'love', data.file)
            end

            love_version = data.version
        end
    end

    loved_mkconf(args['love'], love_version, args['git'], path_loved)

    mkdir(path_game, 'libraries')
    mkdir(path_game, 'assets', 'sprites')
    mkdir(path_game, 'assets', 'sounds')
    love_mkconf(path_game)
    love_make_main_script(path_game)

    return path_game
end

return new_project