#!/usr/bin/env torch

local utils = require 'utils'
utils.import 'params'
utils.import 'data'
utils.import 'kinematics'

-- parse args
if #arg ~= 1 then
    error 'One argument: dataset name'
end
dataset = arg[1]

-- load data
local X, idxs = data.read(dataset)

-- learn joints
print(kinematics.learn(X))

