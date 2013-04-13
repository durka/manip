require 'torch'
require 'utils'

function read(dataset)
    local logf = try(io.open, {string.format('%s/%s.txt', DATA_DIR, dataset),
                               string.format('%s/%s_out.txt', DATA_DIR, dataset)},
                     'find data dump file')
    local line = logf:read('*line')
    local data = {}
    if string.find(line, '|') then
        -- new format
        function process(chunk)
            local nums = FL.map(tonumber, string.split(chunk))
            local i = nums[1]
            local t = {nums[2], nums[3], nums[4]}
            local r = {nums[5], nums[6], nums[7]}
            return i, t, r
        end
        while line do
            local id, features = unpack(string.split(line, ':'))
            local frame, time = unpack(FL.map(tonumber, string.split(id)))
            print(frame)
            data[frame] = {}
            for i,feature in ipairs(string.split(features, '|')) do
                if string.strip(feature) ~= '' then
                    local _, t, r = process(feature)
                    print(i, t, r)
                    data[frame][i] = SE:new(3):R_axis(r):T(t)
                end
            end

            line = logf:read('*line')
            while line and line == '' do
                line = logf:read('*line')
            end
        end
    else
        -- old format
        function process(line)
            local nums = FL.map(tonumber, string.split(line))
            local f = nums[1]
            local i = nums[2]
            local t = {nums[3], nums[4], nums[5]}
            local r = {nums[6], nums[7], nums[8]}
            return f, i, t, r
        end
        local i = 1
        while line do
            local f, _, t, r = process(line)
            print(f, i, t, r)
            if not data[f] then
                data[f] = {}
                i = 1
            end
            data[f][i] = SE:new(3):R_axis(r):T(t)
            i = i + 1

            line = logf:read('*line')
            while line and line == '' do
                line = logf:read('*line')
            end
        end
    end
    logf:close()

    local n = math.max(unpack(FL.map(OP.len, data)))
    data = FL.filter(function (f,_) return #f == n end, data, table.fromiter(math.range(#data)))
    idxs = FL.map(function (t) return t[2] end, data)
    data = FL.map(function (t) return t[1] end, data)
    local X = torch.Tensor(#data, n, 4, 4)
    for i,objects in ipairs(data) do
        for j,x in ipairs(objects) do
            X[{ i,j, {},{} }] = x.m
        end
    end
    
    return X, idxs
end

