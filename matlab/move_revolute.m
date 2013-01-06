% in 2D and 3D
%   params{1} SE(n) is the center of rotation (WRT from-object center)
%   params{2} SE(n) is the offset from the center to the moving part at theta=0
function params = move_revolute(params, aorb, rigid)
    switch aorb
        case 'a'
            params{1} = params{1}*rigid;
        case 'b'
            params{2} = rigid*params{2};
    end
end
