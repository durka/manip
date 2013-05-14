--- Functional List Library for Lua
-- <br />
-- Advanced operations on lists.
-- <br />
-- This library assumes that tables are used like arrays / lists.
-- So for any table, the keys are integers starting with 1.
-- <br />
-- Function names are taken from Data.List of Haskell.  Semantics
-- are as close as possible to their Haskell counterparts.  However,
-- the functions map(), filter(), zip() and unzip() are n-ary, meaning
-- that they can take one or more lists as arguments.
-- <br />
-- So Haskell functions like zipWith(), zipWith3(), zip4(), unzip5(), 
-- etc. are not defined.
-- @class module
-- @name functional.list

--[[ Needed for luadoc.  Leave commented out.
module "list"
]]--

--[[
  Copyright (c) 2009 - 2011, James Graves <ansible@xnet.com>
  Distributed under MIT license, see COPYING.txt for license details.
]]--


local OP    = require "functional.operators"
local unpack = unpack or table.unpack  -- for Lua 5.2

local _M = {} -- Stores exported objects.

--[[

]]--


--[[--
    zip_with_helper ()

    This is a generalized version of Haskell's zipWith, but instead
    of running a function and appending that result to the list of results
    returned, we call a helper function instead.

    So this function does most of the work for map(), filter(), and zip().

    result_helper may do a variety of things with the function to
    be called and the arguments.  The results, if any, are appended
    to the resutls_l table.
]]--
local function zip_with_helper(result_helper, rh_arg, ...)
     local results_l= {}
     local args = {...}     -- a table of the argument lists
     local args_pos = 1     -- position on each of the individual argument lists
     local have_args = true

     while have_args do
        local arg_list = {}
        for i, v in ipairs(args) do
            local a = nil
            a = v[args_pos]
            if a then
                arg_list[i] = a
            else
                have_args = false
                break
            end
        end
        if have_args then
            result_helper(rh_arg, arg_list, results_l)
        end
        args_pos = args_pos + 1
    end
                    
     return results_l
end


--[[--
    zip([one or more tables])

    For the given tables, create a table that contains the first element
    of table1, table2, table3, etc.  The same for the second element of
    table1, table2, etc.

    The length of the output list is the length of the shortest of
    the input lists.  

    zip({1,2,3}, {4, 5, 6})   ->  {{1, 4}, {2, 5}, {3, 6}}
        
]]--
local function zip_helper (_, arg_list, results_l)
    table.insert(results_l, arg_list)
end

function _M.zip(...)
    return zip_with_helper(zip_helper, nil, ...)
end


local function map_helper (func, arg_list, results_l)
    table.insert(results_l, func(unpack(arg_list)))
end

 --[[--
    map(function, [one or more tables])

    Repeatedly apply the function to the arguments composed from the
    elements of the lists provided.

    Examples:
        function double(x) return x * 2 end
        function add(x,y) return x + y end

        map(double, {1,2,3})                -> {2,4,6}
        map(add, {1,2,3}, {10, 20, 30})     -> {11, 22, 33}

    This also implements the functionality of 
        zipWith, zipWith3, zipWith4, etc. 
    in Haskell.

    func() should be a function that takes as many
    arguments as tables provided.  map() returns a list of just the
    first return values from each call to func().
 ]]--
function _M.map(func, ...)
    return zip_with_helper(map_helper, func, ...)
end


local function filter_helper (func, arg_list, results_l)
    local result = func(unpack(arg_list))
    if result then
        if #arg_list == 1 then
            table.insert(results_l, arg_list[1])
        else
            table.insert(results_l, arg_list)
        end
    end
end

 --[[--
    filter(func, [one or more tables])

    Selects the items from the argument list(s), calls
    func() on that, and if the result is true, the arguments
    are appended to the results list.

    Note that if func() takes only one argument and one
    list of arguments is given, the result will be a table
    that contains the values from the argument list directly.

    If there are two or more argument lists, then the 
    result table will contain a list of lists of arguments that matched
    the condition implemented by func().

    Examples:
        function is_equal (x, y) return x == y end
        function is_even (x) return x % 2 == 0 end
        function is_less (x, y) return x < y end


        filter(is_even, {1,2,3,4}) -> {2,4}

        filter(is_equal, {10, 22, 30, 44, 40}, {10, 20, 30, 40})   --> {{10,10}, {30, 30}}

        filter(is_less, {10, 20, 30, 40}, {10, 22, 33, 40})        --> {{20,22}, {30, 33}}

 ]]--
function _M.filter(func, ...)
    return zip_with_helper(filter_helper, func, ...)
end


 --[[--
    tail(table)

    Return the list starting at the second list item.

    Note that this makes a shallow copy of the list,
    and does not modify the original list itself.
    If the original list is length 1 or less, this returns an empty
    table instead of nil because that seemed more useful.

    Example:
        tail({1,2,3})  ->  {2,3}
 ]]--
function _M.tail(list)
    local newlist = {}
    for i = 2, #list do
        newlist[i - 1] = list[i]
    end
    return newlist
end


 --[[--
    foldr() - list fold right, with initial value

    foldr(function, default_value, table)

    Example:
        function mul(x, y) return x * y end
        function div(x, y) return x / y end

        foldr(mul, 1, {1,2,3,4,5})  ->  120
        foldr(div, 2, {35, 15, 6})  ->  7
 ]]--
function _M.foldr(func, val, tbl)
    for i = #tbl, 1, -1 do
        val = func(tbl[i], val)
    end
    return val
end


--[[--
    foldr1() - list fold right

    foldr(function, list)

    Example:
        function add(x, y) return x + y end

        foldr1(add, {1,2,3,4})  ->  10
]]--
function _M.foldr1(func, tbl)
    return _M.foldr(func, tbl[1], _M.tail(tbl))
end


--[[--
    foldl() - list fold left with initial value

    Example:
        foldl(div, 120, {2, 3, 5})  ->  4
]]--
function _M.foldl(func, val, tbl)
    for i, v in ipairs(tbl) do
        val = func(val, v)
    end
    return val
end


--[[--
    foldl1() - list fold left

    Example:
        foldl1(div, {120, 2, 3, 5})  ->  4
]]--
function _M.foldl1(func, tbl)
    return _M.foldl(func, tbl[1], _M.tail(tbl))
end


--[[--
    unzip()

    For example:

        If given a single table of tables, it unzips
        then and returns a single table of tables:

        unzip({{10, 20, 30}, {40, 50, 60}})  -> {{10, 40}, {20, 50}, {30, 60}}

    Other uses:

        This is an n-ary function, so if given multiple tables as
        arguments, these are unzipped and returned as multiple tables
        (and not a single table of tables):

        two tables of three items:      return three tables of two:
        unzip({1, 2, 3}, {4, 5, 6})  -> {1, 4}, {2, 5}, {3, 6}

    Notes:
        This also implements the Data.List function transpose when
        given just one list of lists.

]]--
function _M.unzip(...)
    local tables = {...}
    local result_tables = {}
    local multi_return = #tables > 1

    if not multi_return then
        tables = tables[1]  -- Given a table of tables, so unzip that.
    end

    for rowidx, row_val in ipairs(tables) do
    	for colidx, col_val in ipairs(row_val) do
            if rowidx == 1 then
                result_tables[colidx] = {}
            end
            result_tables[colidx][rowidx] = col_val
        end
    end

    if multi_return then
        return unpack(result_tables)
    else
        return result_tables
    end
end
_M.transpose = _M.unzip


--[[--
    reverse()

    Returns a shallow copy of the items in the list, in 
    reverse order.

    Has an optional argument to force the list to be a given length.
    This is useful if the list has nil values you want to retain.

    Example:
        reverse({1, 2, 3, 4})      ->  {4, 3, 2, 1}
        reverse({1, 2, 3, 4}, 6)   ->  {nil, nil, 4, 3, 2, 1}
        reverse({1, 2, nil, 4})    ->  {2, 1}  (usually, depends on how table was created)
        reverse({1, 2, nil, 4}, 4) ->  {4, nil, 2, 1}
]]--
function _M.reverse(tbl, force_length)
    local new_tbl = {}
    local tbl_len = force_length or #tbl

    if not tbl then return nil end

    for i = 1, tbl_len do
        new_tbl[tbl_len + 1 - i] = tbl[i]
    end
    return new_tbl
end


--[[--
    intersperse()

    Inserts an item in between each previously existing item of a list.

    Example:
        intersperse(9, {1, 2, 3, 4})   ->  {1, 9, 2, 9, 3, 9, 4}
]]--
function _M.intersperse(item, tbl)
    local new_tbl = {}
    for i, v in ipairs(tbl) do
        table.insert(new_tbl, v)
        if i ~= #tbl then
            table.insert(new_tbl, item)
        end
    end
    return new_tbl
end


--[[--
    take()

    Returns a shallow copy of the first N items of the given list.

    Example:
        take(3, {1, 2, 3, 4, 5})  -> {1, 2, 3}
]]--
function _M.take(n, tbl)
    local new_tbl = {}
    for i, v in ipairs(tbl) do
        if i <= n then
            new_tbl[i] = v
        else
            break
        end
    end
    return new_tbl
end


--[[--
    drop()

    Returns a shallow copy of the list without the first N items.

    Example:
        drop(3, {1, 2, 3, 4, 5})  -> {4, 5}
]]--
function _M.drop(n, tbl)
    local new_tbl = {}
    for i, v in ipairs(tbl) do
        if i > n then
            table.insert(new_tbl, v)
        end
    end
    return new_tbl
end


--[[--
    concat_single(tbl)

    Helper for n-ary concat() below.
]]--
local function concat_single(tbl)
    local new_tbl = {}
    for i, sublist in ipairs(tbl) do
        for j, item in ipairs(sublist) do
            table.insert(new_tbl, item)
        end
    end
    return new_tbl
        
end


--[[--
    concat()

    Takes a list of lists, and return a single list with all the elements.

    If given multiple lists as arguments, combine each of the list
    contents into a single list.

    Examples (note the different table nesting):
        concat({{1, 2}, {{10, 20}, {30, 40}}})  -> {1, 2, {10, 20}, {30, 40}}
        
        concat({1, 2}, {{10, 20}, {100, 200}})  -> {1, 2, {10, 20}, {100, 200}}
]]--
function _M.concat(...)
    local args = {...}     -- a table of the argument lists
    if #args == 1 then
        return concat_single(args[1])
    else
        return concat_single(args)
    end
end


--[[
    and()

function and(tbl)
    return foldr(operator.and, true, tbl)
end
]]--


--[[--
    all()

    Note that we're not checking explicitly for boolean 'true'
    on the list.  So any value other than 'false' will be
    true.
]]--

function _M.all(func, list)
    for i, v in ipairs(list) do
        if not func(v) then return false end
    end
    return true
end


--[[--
    any()

    Note that we're not checking explicitly for boolean 'true'
    on the list.  So any value other than 'false' or 'nil' will be
    true.
]]--
function _M.any(func, list)
    for i, v in ipairs(list) do
        if func(v) then return true end
    end
    return false
end




local function sum_helper(operator, tbl, ...)
    local args = {...}
    if #args == 0 and type(tbl) == "table" then
        return _M.foldr1(operator, tbl)
    else
        return _M.foldr(operator, tbl, args)
    end
end

--[[--
    sum()

    Sum the list and/or the arguments.

    If there is just one argument, and it is a list, then
    return the sum of the items in that list.
    Otherwise return the sum of all the arguments.
]]--
function _M.sum(...)     return sum_helper(OP.add, ...) end

--[[
    product()

    Multiply the list and/or the arguments.

    If there is just one argument, and it is a list, then
    return the product of the items in that list.
    Otherwise return the product of all the arguments.
]]--
function _M.product(...) return sum_helper(OP.mul, ...) end


--[[
    and()
]]--

function _M.and_list(list) return _M.all(OP.is_true, list) end


--[[
    or()
]]--

function _M.or_list(list)  return _M.any(OP.is_true, list) end



--[[--
    concat_map(func, tbl)

    FIXME: re-analyze this 

]]--
function _M.concat_map(f, tbl)
    return concat(map(f, tbl))
end


--[[--
unfoldr      :: (b -> Maybe (a, b)) -> b -> [a]
unfoldr f b  =
  case f b of
     Just (a,new_b) -> a : unfoldr f new_b
     Nothing        -> []

    FIXME: re-analyze this 
]]--
function _M.unfoldr(f, b)
    local tbl = {}
    local a, new_b = f(b)
    while a do
        table.insert(tbl, a)
        a, new_b = f(new_b)
    end
    return tbl
end


--[[--
unfoldl f x = case f x of
    Nothing     -> []
    Just (u, v) -> unfoldl f v ++ [u]


    FIXME: re-analyze this 
]]--
function _M.unfoldl(f, x)
    return reverse(unfoldr(f, x))
end


return _M
