#!/usr/bin/env torch

require 'image'
require 'yaml'

local utils = require 'utils'
utils.import 'params'
utils.import 'data'

-- parse args
if #arg ~= 2 then
    error('Two arguments: dataset name and tag scale')
end
dataset = arg[1]
s = tonumber(arg[2])

camdata = utils.try(yaml.loadfile, {string.format('%s/../macbook_air_webcam.yml', params.DATA_DIR)}, 'find camera data YAML')
camdata.camera_matrix = torch.reshape(torch.Tensor(camdata.camera_matrix.data), 3, 3)

-- load data
X, idxs = data.read(dataset)

-- show images
for f = 1,X:size(1) do
    I = utils.try(image.load, {string.format('%s/%s_dirty_%d.jpg', params.DATA_DIR, dataset, idxs[f]),
                               string.format('%s/%s_dirty_%d.png', params.DATA_DIR, dataset, idxs[f])},
            'find the images')
    for i = 1,X:size(2) do
        print(torch.squeeze(X[{ f,i, {},{} }]))
        p = camdata.camera_matrix
            * torch.eye(3,4)
            * torch.squeeze(X[{ f,i, {},{} }])
            * torch.Tensor{{s*10,  0,     0,     1},
                           {s*5,   0,     0,     1},
                           {s*2.5, 0,     0,     1},
                           {s,     0,     0,     1},
                           {0,     s*10,  0,     1},
                           {0,     s*5,   0,     1},
                           {0,     s*2.5, 0,     1},
                           {0,     s,     0,     1},
                           {0,     0,     s*10,  1},
                           {0,     0,     s*5,   1},
                           {0,     0,     s*2.5, 1},
                           {0,     0,     s,     1},
                           {0,     0,     0,     1}}:t()
        for j = 1,13 do
            p[{ {}, j }]:div(p[{3,j}])
            if p[{1,j}] >= 1 and p[{2,j}] >= 1
               and p[{1,j}] <= I:size(3) and p[{2,j}] <= I:size(2) then
                I[{ {2,3}, {p[{2,j}], p[{2,j}]+5}, {p[{1,j}], p[{1,j}]+5} }] = 0
                I[{ 1,     {p[{2,j}], p[{2,j}]+5}, {p[{1,j}], p[{1,j}]+5} }] = i/500
            end
        end
    end
    w = image.display{image=I, win=w, gui=false}
end

