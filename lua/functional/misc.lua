
-- Copyright (c) 2010 by James Graves <ansible@xnet.com>


local L = require "functional.list"
local unpack = unpack or table.unpack -- for Lua 5.2

local _M = {}
 

--[[
    argument_pack() and argument_unpack()

    The normal way to deal with passing around multiple arguments
    is to create a table of them using 'foo = {...}' and later
    expanding that table with 'unpack(foo)'.

    However, unpack() in Lua will not work as expected if there were
    nil values in the original argument list.

    This is due, in part, to the definition of list length in Lua. Please
    refer to the reference manual, but basically the first nil
    encountered _sometimes_ ends the list.

    So here we just explicitly stash the length as part of the table.

]]--

--[[
    argument_pack(...)

    Returns a table of arguments much like {...} except that it also explicitly
    saves the length as entry 'n'.

    Designed to work with argument_unpack() below.
]]--

function _M.argument_pack(...)
    local new_tbl = {...}

    new_tbl.n = select('#', ...)
    return new_tbl
end

--[[
    argument_unpack(tbl)

    Returns multiple values based on the table passed in.  It expects a field 'n' which
    contains the number of arguments in the list.

    Designed to work with argument_pack() above.

    Any additional args get tacked on the end.  This is very handy as you'll see later.
]]--


function _M.argument_unpack(t, ...)
    local n = t.n
    local args = {}

    if not n or n < 0 then
        error "Invalid argument list to argument_unpack()"
    end

    -- copy table
    for i = 1, n do args[i] = t[i] end

    local add_args_count = select('#', ...)
    if add_args_count > 0 then
        for i = 1, add_args_count do
            args[i + n] = (select(i, ...))
        end
        n = n + add_args_count
    end

    return unpack(args, 1, n)
end


--[[
    call_with()

    This is not a true curry function that converts the given function
    to a series of one-argument functions.  While mathmatically
    cool, this isn't so useful in practice.

    More often, we need to specify one or more parameters, while
    still needing multiple arguments later.

    Usage:
        add3_4 = call_with(add_up, 3, 4)
        
        add3_4(5, 90)  --> returns 102

        add1000 = call_with(add_up, 1000)

        add1000(78)  --> returns 1078

    Notes:
        This implementation isn't badly inefficient, but it does
        end up reconstructing the argument list every time.
        We definitely don't want to modify given_args (which
        would be much easier) because we want to be fully re-entrant.

        We need to unpack and repack the arguments because we
        can't just append them at call time.  Multiple return
        values are only done when it is the last function of the
        comma-separated list.
]]--

function _M.call_with(myfunc, ...)
    local num_given_args = select('#', ...)
    local given_args = {...}
    return function (...)
        local args = {}
        for i = 1, num_given_args do
            args[i] = given_args[i]
        end

        local num_adl_args = select('#', ...)
        if num_adl_args > 0 then
            for i = 1, num_adl_args do
                args[num_given_args + i] = (select(i, ...))
            end
        end
        return myfunc(unpack(args, 1, num_given_args + num_adl_args))
    end
end


--[[
    reverse_args()

    Reverses the argument list passed to it.
    Handles nil arguments correctly.
]]--
function _M.reverse_args(...)
    local n = select('#', ...)
    return unpack(L.reverse({...}, n), 1, n)
end


--- Append a single argument to the end of a variable number of arguments.
-- <br />
-- Suppose there is a function like this:
-- function f(...) that is being called from some other function g(...) like this:
--
-- function g(...)
--     local x = 3
--     return f(...)
-- end
--
-- where g() passes its variable number of arguments to f().  Putting additional
-- arguments at the beginning of the list is easy: 
--
-- function g(...)
--     local x = 3
--     return f(x, ...)
-- end
-- 
-- However, appending and argument to the end won't work properly, the variable
-- number of arguments will be truncated.
--
-- function g(...)
--     local x = 3
--     return f(..., x)  -- FIXME: will not work as expected
-- end
-- 
-- Using append_arg() will work, however:
--
-- function g(...)
--     local x = 3
--     return f(append_arg(x, ...))
-- end
-- 
-- @name append_arg
-- @param val The value to put at the end of the argument list
-- @param ... A variable number of arguments.
-- @return The argument list with val appended to the end of it.

function _M.append_arg(val, ...)
    local c = select("#", ...) + 1
    return unpack({[c] = val, ...}, 1, c)
end                                                       

return _M
