require 'conf-dev'

local new_project = require 'commands.new_project'

local releases = new_project.releases()

assert(releases ~= nil)
assert(type(releases) == 'table')
assert(#releases > 0)

for _, release in ipairs(releases) do
    for k, v in pairs(release) do
        print(k, v)
    end
end