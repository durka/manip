--- Infinite Lists.
-- <br />
-- Various ways to construct infinite lists.
-- @class module
-- @name infinite_list

--[[ The module line is needed for luadoc to consider this a module.
module "infinite_list"
]]--

local M = {}  -- List of exported functions.

--- Returns an infinite list of repeated applications of function 'func' to value 'start_val'.
-- For example: <br />
-- <code> { x, f(x), f(f(x)), f(f(f(x))), ... }</code><br />
-- Haskell type signature: <br />
-- <code> iterate :: (a -> a) -> a -> [a] </code> <br />
-- @name iterate
-- @param func Function that takes a value, and returns a value of the same type.
-- @param start_val Starting value, which is also the first value on the list.
-- @return Infinite list of values of the same type as a.

function M.iterate(func, start_val)
    return setmetatable({start_val}, {__index = 
        function (tbl, idx)
            local curr_len = #tbl
            if idx < 1 then
                return nil
            end
            for i = curr_len + 1, idx do
                tbl[i] = func(tbl[i - 1])
            end
            return tbl[idx]
        end
        })
end


--- Returns an infinite list where every value is a.
--  <br />repeated :: a -> [a]
--  <br /> 'repeat' is a keyword in Lua, so we decided to have a
-- slightly different name than in the Haskell library.
-- @name repeated
-- @param start_val Starting value, which is also the first value on the list.
-- @return Infinite list of values of a.

function M.repeated(start_val)
    return setmetatable({}, {__index = function () return start_val end })
end



--- Create a finite list of length n with x for each item.
-- For example: replicate(3, "a")  --> {"a", "a", "a"}
-- @name replicate
-- @param n Length of resulting list.
-- @param x The value for each item on the list.
-- @return List of 'n' items.

function M.replicate(n, x)
    local new_tbl = {}
    for i = 1, n do
        new_tbl[i] = x
    end
    return new_tbl
end


--- Create an infinite list from a finite one.
-- If the list is length n, then at postion n+1 is the same as the beginning
-- of the list at postion 1.
-- @name cycle
-- @param tbl The starting list.
-- @return Infinite repetition of the original list.
function M.cycle(tbl)
    local new_tbl = {}
    for i, v in ipairs(tbl) do new_tbl[i] = v end
    return setmetatable(new_tbl, {__index = 
        function (tab, idx)
            local tbl_len = #tab
            local new_idx = math.fmod(idx, tbl_len)
            if new_idx < 1 then new_idx = new_idx + tbl_len end
            return tab[new_idx]
        end
        })
end

return M
