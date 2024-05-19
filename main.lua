fennel = require("fennel")
debug.traceback = fennel.traceback

table.insert(package.loaders, fennel.make_searcher({correlate=true}))
pp = function(x) print(fennel.view(x)) end
local make_love_searcher = function(env)
   return function(path)
      if love.filesystem.getInfo(path) then
         return function(...)
            local code = love.filesystem.read(path)
            return fennel.eval(code, {env=env, filename=path}, ...)
         end, path
      end
   end
end

table.insert(package.loaders, make_love_searcher(_G))
table.insert(fennel["macro-searchers"], make_love_searcher("_COMPILER"))

lume = require("lume")
inspect = require("inspect")
require("wrap.fnl")
