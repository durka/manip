function [err, grad] = jointfit(deltas, p, forward, inverse, unpack, Dq, Dr)
    %dbstop if infnan

    err = 0;
    grad = zeros(size(p));
    
    % accumulate error at each frame
    for frame = 1:length(deltas)
        % perform IK to get the observed params
        [state, Dki] = inverse(deltas{frame}, unpack(p));
        
        % get error between real SE pose and observed-modeled SE pose
        [estimate, Dkr, Dkt] = forward(unpack(p), state);
        [e, Dd] = SE_dist(estimate, deltas{frame}, Dkr, Dkt, Dki, Dq, Dr);
        err = err + e;
        grad = grad + Dd;
    end
    
    
    if imag(err) || any(imag(grad)) || any(isinf(grad)) || any(isnan(grad))
        fprintf('%s => %s, %s\n', mat2str(p, 3), mat2str(err, 3), mat2str(grad, 3));
    end
    
    grad(isnan(grad)) = 0; % HACK HACK HACK COUGH
    grad(isinf(grad)) = 0;
    grad = real(grad);
    err = real(err);
    
    %dbclear if infnan
end
