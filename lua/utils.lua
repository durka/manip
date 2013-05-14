--- various utility function and monkey patches.
-- intentionally pollutes the global namespace and monkey-patches various classes
-- require as: local utils = require 'utils'
-- after that use utils.import to require things
-- require 'yaml' and 'torch' first if you want those to be monkey-patched
-- @class module
-- @name utils

FL = require 'functional.list'
OP = require 'functional.operators'

--- identity function (for map, filter, etc).
-- @param whatever
-- @return whatever
FL.id = function (...) return ... end

if package.loaded.table then
    --- monkey-patch to convert an iterator into a table.
    -- @param iter (not an infinite one!)
    -- @return table containing all the values from the iterator
    function table.fromiter(iter)
        local t = {}
        for i in iter do
            table.insert(t, i)
        end
        return t
    end

    --- monkey-patch to get the keys out of a table.
    -- @param t table
    -- @return table of keys
    function table.keys(t)
        local keys = {}
        for k,v in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end

    --- monkey-patch to get the values out of a table.
    -- @param t table
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

    --- monkey-patch for string interpolation.
    -- @param s (string) format string with interpolations like ${var}
    -- @param tab (table) values to fill in the interpolations
    -- @return interpolated string
    -- @see string.format
    function string.interp(s, tab)
        return (string.gsub(s, '($%b{})', function(w) return tab[string.sub(w, 3, -2)] or w end))
    end

    --- monkey-patch for reverse string searching.
    -- @param s (string) haystack
    -- @param pat (string) needle
    -- @param ... just like string.find (except starting from the end)
    -- @return start and end positions of last occurrence of needle in haystack, or nil if none
    -- @see string.find
    function string.rfind(s, pat, ...)
        local a, b = string.find(string.reverse(s), string.reverse(pat), ...)
        if a then
            a = #s - a + 1
            b = #s - b + 1
        end
        return b, a
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

if package.loaded.math then
    -- add an eps constant (floating point epsilon) to the math package
    local eps = 1
    repeat eps = eps / 2 until (eps / 2) == 0
    math.eps = eps;

    --- monkey-patch to make a range iterator.
    -- range(start)             returns an iterator from 1 to a (step = 1)
    -- range(start, stop)       returns an iterator from a to b (step = 1)
    -- range(start, stop, inc) returns an iterator from a to b, counting by inc.
    -- @param i (int) start (or end, with start=1, if no other parameters)
    -- @param to (int) end (inclusive)
    -- @param inc (int, default 1) iteration step
    -- @return iterator
    -- @see table.fromiter
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

    --- monkey-patch to put torch.inverse() as an instance method.
    -- @return inverse of the tensor
    -- @see torch.inverse
    function torch.Tensor:i()
        return torch.inverse(self)
    end

    --- monkey-patch to put torch.svd() as an instance method.
    -- @return SVD of the tensor
    -- @see torch.svd
    function torch.Tensor:svd()
        return torch.svd(self)
    end

    --- monkey-patch to calculate covariance of tensors.
    -- translated from Matlab's implementation
    -- @return sample covariance matrix of the tensor
    function torch.Tensor:cov()
        if self:dim() == 2 then
            local m = self:size(1) local n = self:size(2)
            if m == 1 then
                -- cov not really defined for only one observation
                return torch.zeros(n)
            else
                local xc = self - self:mean(1):repeatTensor(m,1) -- remove the mean
                return xc:t() * xc / (m-1)
            end
        else
            error('cov only works on 2D tensors')
        end
    end

    --- monkey-patch to permute the rows.
    -- if self is MxN, order must have M elements
    -- @param order (tensor) the new order for rows
    -- @return self with rows permuted
    function torch.Tensor:rows(order)
        if order:size(1) == self:size(1) then
            local m = torch.zeros(self:size(1), self:size(1))
            for i=1,self:size(1) do
                m[{i,order[i]}] = 1
            end
            return m * self
        else
            error('size mismatch')
        end
    end
    --- monkey-patch to permute the columns.
    -- if self is MxN, order must have N elements
    -- @param order (tensor) the new order for columns
    -- @return self with columns permuted
    function torch.Tensor:cols(order)
        if order:size(1) == self:size(2) then
            local m = torch.zeros(self:size(2), self:size(2))
            for i=1,self:size(2) do
                m[{i,order[i]}] = 1
            end
            return self * m
        else
            error('size mismatch')
        end
    end
end

if package.loaded.gnuplot then
    --- monkey-patch to plot quivers.
    -- @param data (tensor Nx6) x, y, z, u, v, w
    -- @param title (optional string) legend entry for this data
    function gnuplot.quiver(data, title)
        title = title or ''
        local s = tostring(data)
        s = string.sub(s, 1, string.rfind(s, '\n', 2))
        s = string.gsub(s, '\n', '\\n')
        s = string.format('splot "<echo \'%s\'" title "%s" with vectors', s, title)
        print(s)
        gnuplot.raw(s)
    end
end


local utils = {}

--- helper function for defining sane modules.
-- module template:
--    local utils = require 'utils'
--    utils.module 'module_name'
--    utils.import 'blah blah blah'
--    function do_awesome_stuff(...) if math.random() > 0.5 then launch_missiles(...) end end
--    return module_name
-- client template:
--    local utils = require 'utils'
--    utils.import 'module_name'
--    module_name.do_awesome_stuff()
-- @param name (string) package name
-- @see utils.import
-- @see utils.reload
-- @see package.loaded
-- @see require
function utils.module(name)
    package.loaded[name] = {}
    package.loaded[name][name] = package.loaded[name] -- "fuck you" said the garbage collector
    setmetatable(package.loaded[name], {__index = getfenv(2)})
    setfenv(2, package.loaded[name])
end

--- cache for arguments to utils.import, also tracks dependencies for utils.reload.
-- @see utils.import
-- @see utils.reload
-- @see package.loaded
_imported  = _imported  or {}
_importing = _importing or {}
_require   = _require   or require
-- this stuff can't be in the utils table because then reloading 'utils' gets weird
function require(pkg)
    if not package.loaded[pkg] then
        print('requiring ' .. pkg)
    end
    if #_importing > 0 then
        local cur = table.last(_importing)
        if _imported[cur] then
            table.insert(_imported[cur].children, pkg)
        else
            _imported[cur] = {children = {pkg}}
        end
    end
    table.insert(_importing, pkg)
    local stuff = {_require(pkg)}
    table.remove(_importing)
    return unpack(stuff)
end

--- like require, with some enhanced features.
-- @param pkg (string) package name (just like require)
-- @param as (optional string, must start with 'as') rename the package, e.g. 'as foo'
-- @param from (optional string, must not start with 'as') comma-separated list of symbols to import (and optionally rename), e.g. 'Foo, Bar as B, Baz as Quux'
-- @see require
-- @see utils.reload
function utils.import(pkg, as, from)
    _imported[pkg] = {as = as, from = from, children = {}}
    local pack = require(pkg)
    if as then
        if string.sub(as, 1, 2) == 'as' then
            pkg = string.sub(as, 4)
        else
            from = as
        end
    end
    local G = getfenv(2)
    G[pkg] = pack
    if from then
        for _,symbol in pairs(string.split(from, ',')) do
            symbol = string.strip(symbol)
            local a, b = string.find(symbol, ' as ')
            if a then
                G[string.sub(symbol, b+1)] = G[pkg][string.sub(symbol, 1, a-1)]
            else
                G[symbol] = G[pkg][symbol]
            end
        end
    end
end

--- reload a package (reusing arguments from the last call to utils.import, if available).
-- @param pkg (string) package name (just like require)
-- @see require
-- @see utils.import
function utils.reload(pkg)
    pkg = pkg or 'utils'
    package.loaded[pkg] = nil
    if _imported[pkg] then
        for _,child in ipairs(_imported[pkg].children) do
            utils.reload(child) -- superreload
        end
        utils.import(pkg, _imported[pkg].as, _imported[pkg].from)
    else
        utils.import(pkg)
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

