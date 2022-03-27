require 'conf-dev'

_HEART_VERSION = '1.0-alpha'

local new_project = require 'commands.new_project'

local releases = new_project.releases()
local _, love = assert(new_project.download("tests/temp", releases))
assert(love ~= nil)
assert(type(love) == 'table')

for k, v in pairs(love) do
    print(k, v)
end