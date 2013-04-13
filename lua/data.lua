require 'torch'
require 'utils'

--- functions to deal with trajectory data on disk.

--- read the output of aruco_tracker.
-- understands both the old format and the new format (auto-detected)
-- @param dataset (string) name of the dataset
--                         the data dump should be at DATA_DIR/dataset.txt or DATA_DIR/dataset_out.txt
-- @return X (tensor FxNx4x4) the trajectory matrix (F frames and N tracked features)
-- @return idxs (numeric array) frame indices that were kept in X (any frames with <N features are dropped)
function read(dataset)
    local logf = try(io.open, {string.format('%s/%s.txt', DATA_DIR, dataset),
                               string.format('%s/%s_out.txt', DATA_DIR, dataset)},
                     'find data dump file')
    local line = logf:read('*line')
    local data = {}
    if string.find(line, '|') then
        -- new format
        function process(chunk)
            local nums = FL.map(tonumber, string.split(chunk)) -- feature record = <feature number> <Tx> <Ty> <Tz> <Rx> <Ry> <Rz>
            local i = nums[1]
            local t = {nums[2], nums[3], nums[4]}
            local r = {nums[5], nums[6], nums[7]}
            return i, t, r
        end
        while line do -- the new format has one line per frame
            local id, features = unpack(string.split(line, ':')) -- frame header is before colon
            local frame, time = unpack(FL.map(tonumber, string.split(id))) -- frame header consists of frame index and unix timestamp
            print(frame)
            data[frame] = {}
            for i,feature in ipairs(string.split(features, '|')) do -- feature records separated by |
                if string.strip(feature) ~= '' then
                    local _, t, r = process(feature)
                    print(i, t, r)
                    data[frame][i] = SE:new(3):R_axis(r):T(t) -- recover rigid motion from T/R
                end
            end

            line = logf:read('*line')
            while line and line == '' do -- skip blank lines
                line = logf:read('*line')
            end
        end
    else
        -- old format
        function process(line)
            local nums = FL.map(tonumber, string.split(line)) -- line = <frame index> <feature number> <Tx> <Ty> <Tz> <Rx> <Ry> <Rz>
            local f = nums[1]
            local i = nums[2]
            local t = {nums[3], nums[4], nums[5]}
            local r = {nums[6], nums[7], nums[8]}
            return f, i, t, r
        end
        local i = 1
        while line do -- the old format has frames spread over up to N lines
            local f, _, t, r = process(line)
            print(f, i, t, r)
            if not data[f] then -- start a new frame
                data[f] = {}
                i = 1
            end
            data[f][i] = SE:new(3):R_axis(r):T(t) -- recover rigid motion from T/R
            i = i + 1

            line = logf:read('*line')
            while line and line == '' do -- skip blank lines
                line = logf:read('*line')
            end
        end
    end
    logf:close()

    -- now delete frames with missing features
    local n = math.max(unpack(FL.map(OP.len, data))) -- N comes from the frames with the most features present
    data = FL.filter(function (f,_) return #f == n end, data, table.fromiter(math.range(#data))) -- kill frames with <N features, but also record the original indices of the frames that are kept
    local idxs = FL.map(function (t) return t[2] end, data) -- extract the indices
    data = FL.map(function (t) return t[1] end, data) -- extract the frames

    -- transcribe data table into tensor
    local X = torch.Tensor(#data, n, 4, 4)
    for i,objects in ipairs(data) do
        for j,x in ipairs(objects) do
            X[{ i,j, {},{} }] = x.m
        end
    end
    
    return X, idxs
end

