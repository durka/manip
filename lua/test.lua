#!/usr/bin/env torch

local utils = require 'utils'

utils.import 'testmod'

print(table.keys(testmod))
print('false false true', joints ~= nil, testmod.joints ~= nil, testmod.J ~= nil)

