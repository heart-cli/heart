_DEBUG = true
_WIN32_ANSI_ESCAPE_SUPPORT = true

local lua_version = _VERSION:match("%d+%.%d+")

package.path = 'rocks/share/lua/' .. lua_version .. '/?.lua;' .. package.path
package.path = 'rocks/share/lua/' .. lua_version .. '/?/init.lua;' .. package.path
package.cpath = 'rocks/lib/lua/' .. lua_version .. '/?.so;' .. package.cpath
package.cpath = 'rocks/lib/lua/' .. lua_version .. '/?.so;' .. package.cpath
package.cpath = 'rocks/lib/lua/' .. lua_version .. '/?.dylib;' .. package.cpath
package.cpath = 'rocks/lib/lua/' .. lua_version .. '/?.dll;' .. package.cpath
