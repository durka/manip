require 'torch'
require 'yaml'

-- Lua utilities
function reload(pkg)
    package.loaded[pkg] = nil
    require(pkg)
end

-- function programming
FL = require 'functional.list'
OP = require 'functional.operators'

FL.id = function (...) return ... end

-- monkey-patches!
function table.fromiter(iter)
    local t = {}
    for i in iter do
        table.insert(t, i)
    end
    return t
end

function string.split(s, delim)
    local delim = delim or '%s'
    return table.fromiter(string.gmatch(s, string.format('[^%s]+', delim)))
end

function yaml.loadfile(file)
    local f = io.open(file)
    local s = f:read('*all')
    f:close()

    if string.sub(s, 1, 1) == '%' then
        s = string.sub(s, (string.find(s, '\n')))
    end

    return yaml.load(s)
end

function torch.crossm(m)
    if m:dim() > 1 or m:size(1) ~= 3 then error('You can only get the cross product matrix of a 3-vector') end
    return torch.Tensor{{    0, -m[3],  m[2]},
                        { m[3],     0, -m[1]},
                        {-m[2],  m[1],  0}}
end

local eps = 1
repeat eps = eps / 2 until (eps / 2) == 0
math.eps = eps;


-- range(start)             returns an iterator from 1 to a (step = 1)
-- range(start, stop)       returns an iterator from a to b (step = 1)
-- range(start, stop, step) returns an iterator from a to b, counting by step.
function math.range (i, to, inc)
    if i == nil then return end -- range(--[[ no args ]]) -> return "nothing" to fail the loop in the caller

    if not to then
        to = i 
        i  = to == 0 and 0 or (to > 0 and 1 or -1) 
    end 

    -- we don't have to do the to == 0 check
    -- 0 -> 0 with any inc would never iterate
    inc = inc or (i < to and 1 or -1) 

    -- step back (once) before we start
    i = i - inc 

    return function () if i == to then return nil end i = i + inc return i, i end 
end 

-- little function to pause execution, and request user input
function pause()
    local answer = nil
    while answer ~= '' and answer ~= 'y' and answer ~= 'Y' and neverstall ~= true do
        io.write("continue ([y]/n/!)? ")
        io.flush()
        answer=io.read()
        if answer == '!' then
            neverstall = true
        end
        if answer == 'n' then
            print('exiting...')
            os.exit()
        end
    end
    print ''
end

function try(action, alternatives, giveup)
    for i, alt in ipairs(alternatives) do
        local result = action(alt)
        if result then return result end
    end
    local s = string.format('Unable to %s. Tried:\n', giveup)
    for i,alt in ipairs(alternatives) do s = string.format('%s\t%s\n', s, alt) end
    error(s)
end

