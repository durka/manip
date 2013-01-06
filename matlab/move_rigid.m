% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center
function params = move_rigid(params, aorb, rigid)
    switch aorb
        case 'a'
            params{1} = params{1}*rigid;
        case 'b'
            params{1} = rigid*params{1};
    end
end