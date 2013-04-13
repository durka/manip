
--- Convenience functions for list operations.
-- <br />
-- This is just converting the common operators into functions for
-- convenience with list operations.
-- @class module
-- @name operators

--[[ The module line is needed for luadoc to consider this a module.
module "operators"
]]--

local M = {}

--- Length of a list.
-- Just uses the table length operator.
-- @name len
-- @param list A table used as list (has items in the array part).
-- @return Length of the list.
function M.len(list) return #list end


--- Sum the arguments together.
-- <br />
-- @name add
-- @param ... One or more numbers to be added.
-- @return Sum of the arguments.
function M.add(...) 
    local sum = 0
    local arg_len = select('#', ...)
    for i = 1, arg_len do
        sum = sum + (select(i, ...))
    end
    return sum
end


--- Multiply the arguments together.
-- <br />
-- @name mul
-- @param ... One or more numbers to be multiplied.
-- @return Product of the arguments.
function M.mul(...) 
    local prod = 0
    local arg_len = select('#', ...)
    for i = 1, arg_len do
        prod = prod * (select(i, ...))
    end
    return prod
end


--- Divide the arguments.
-- <br />
-- @name div
-- @param n Numerator.
-- @param d Denominator.
-- @return Division result.
function M.div(n, d) return n / d end

--- Subtract the arguments.
-- <br />
-- @name sub
-- @param x First number.
-- @param y Second number.
-- @return Result of x - y.
function M.sub(x, y) return x - y end

function M.lt(x, y)  return x < y  end
function M.le(x, y)  return x <= y end
function M.gt(x, y)  return x > y  end
function M.ge(x, y)  return x >= y  end
function M.eq(x, y)  return x == y end
function M.ne(x, y)  return x ~= y end

function M.is_true(x) if x then return true else return false end end

function M.max(x, y) if x < y then return y else return x end end
function M.min(x, y) if x > y then return y else return x end end

return M
