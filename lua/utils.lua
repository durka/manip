FL = require 'functional.list'
OP = require 'functional.operators'

--- various utility function and monkey patches.
-- intentinally pollutes the global namespace and monkey-patches various classes
-- require 'yaml' and 'torch' first if you want those to be monkey-patched

--- identity function (for map, filter, etc).
-- @param whatever
-- @return whatever
FL.id = function (...) return ... end

if package.loaded.table then
    --- monkey-patch to convert an iterator into a table.
    -- @param iterator (not an infinite one!)
    -- @return table containing all the values from the iterator
    function table.fromiter(iter)
        local t = {}
        for i in iter do
            table.insert(t, i)
        end
        return t
    end

    --- monkey-patch to get the keys out of a table.
    -- @param table
    -- @return table of keys
    function table.keys(t)
        local keys = {}
        for k,v in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end

    --- monkey-patch to get the values out of a table.
    -- @param table
    -- @return table of values
    function table.vals(t)
        local vals = {}
        for k,v in pairs(t) do
            table.insert(vals, v)
        end
        return vals
    end
end

if package.loaded.string then
    --- monkey-patch to split a string.
    -- @param s (string) the string to split
    -- @param delim (regex, default '%s') the things between splits
    -- @return table of splits
    function string.split(s, delim)
        local delim = delim or '%s'
        return table.fromiter(string.gmatch(s, string.format('[^%s]+', delim)))
    end

    function string.interp(s, tab)
        return (string.gsub(s, '($%b{})', function(w) return tab[string.sub(w, 3, -2)] or w end))
    end
end

if package.loaded.yaml then
    --- monkey-patch to load OpenCV YAML.
    -- Removes the first line (with version info) if present
    -- @param file (stirng) filename
    -- @return YAML as table
    -- @see yaml.load
    function yaml.loadfile(file)
        local f = io.open(file)
        local s = f:read('*all')
        f:close()

        if string.sub(s, 1, 1) == '%' then
            s = string.sub(s, (string.find(s, '\n')))
        end

        return yaml.load(s)
    end
end

if package.loaded.torch then
    --- monkey-patch to calculate a cross-product matrix.
    -- @param m (tensor 3) vector
    -- @return (tensor 3x3) [m]_\times
    function torch.crossm(m)
        if m:dim() > 1 or m:size(1) ~= 3 then error('You can only get the cross product matrix of a 3-vector') end
        return torch.Tensor{{    0, -m[3],  m[2]},
                            { m[3],     0, -m[1]},
                            {-m[2],  m[1],  0}}
    end
end

if package.loaded.math then
    -- add an eps constant (floating point epsilon) to the math package
    local eps = 1
    repeat eps = eps / 2 until (eps / 2) == 0
    math.eps = eps;

    --- monkey-patch to make a range iterator.
    -- range(start)             returns an iterator from 1 to a (step = 1)
    -- range(start, stop)       returns an iterator from a to b (step = 1)
    -- range(start, stop, step) returns an iterator from a to b, counting by step.
    -- @param i (int) start (or end, with start=1, if no other parameters)
    -- @param to (int) end (inclusive)
    -- @param step (int, default 1) iteration step
    -- @return iterator
    -- @see table.fromiter if you need a table instead
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
end


local utils = {}

--- like require, with some enhanced features.
-- @param pkg (string) package name (just like require)
-- @param as (optional string) rename the package
-- @param from (optional string) comma-separated list of symbols to import
function utils.import(pkg, as, from)
    package.loaded[pkg] = nil -- always reload (TODO superreload)
    local pack = require(pkg)
    if as then
        if string.sub(as, 1, 2) == 'as' then
            pkg = string.sub(as, 4)
        else
            from = as
        end
    end
    _G[pkg] = pack
    if from then
        for _,symbol in pairs(string.split(from, ',')) do
            a, b = string.find(symbol, ' as ')
            if a then
                _G[string.sub(symbol, b+1)] = _G[pkg][string.sub(symbol, 1, a-1)]
            else
                _G[symbol] = _G[pkg][symbol]
            end
        end
    end
end

--- pause execution and request user input.
function utils.pause()
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

--- try to call a function that might fail, with a few alternatives.
-- @param action (function) the function we are trying. should take one parameter and return nil on failure
-- @param alternatives (table) the choices to try as action's parameter, in order
-- @param giveup (string) complaint to throw if none of the alternatives work ('Unable to ' is prepended)
-- @return the return value of action, when it succeeded
-- @return the alternative that worked
function utils.try(action, alternatives, giveup)
    for i, alt in ipairs(alternatives) do
        local result = action(alt)
        if result then return result, alt end
    end
    local s = string.format('Unable to %s. Tried:\n', giveup)
    for i,alt in ipairs(alternatives) do s = string.format('%s\t%s\n', s, alt) end
    error(s)
end

return utils

