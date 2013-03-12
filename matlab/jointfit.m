function [err, grad] = jointfit(deltas, p, forward, inverse, Dq, Dr, check)
    %dbstop if infnan

    err = 0;
    grad = 0;
    
    % accumulate error at each frame
    for frame = 1:length(deltas)
        % perform IK to get the observed params
        [state, Dki] = inverse(deltas{frame}, p);
        
        % get error between real SE pose and observed-modeled SE pose
        [estimate, Dkr, Dkt] = forward(p, state);
        [e, Dd] = SE_dist(estimate, deltas{frame}, Dkr, Dkt, Dki, Dq, Dr);
        err = err + e;
        grad = grad + Dd;
        
        % check gradient
        if nargin == 8 && check
            gradcheck = jacobianest(@(p) SE_dist(forward(p, inverse(deltas{frame}, p)), deltas{frame}), p);
            if any(abs(gradcheck - Dd) > 1e-3)
                disp('GRADIENT FAULT');
                keyboard;
            end
        end
    end
    
    
    if imag(err) || any(imag(grad)) || any(isinf(grad)) || any(isnan(grad))
        fprintf('%s => %s, %s\n', mat2str(p, 3), mat2str(err, 3), mat2str(grad, 3));
    end
    
    grad(isnan(grad)) = 0; % HACK HACK HACK COUGH
    grad(isinf(grad)) = 0;
    grad = real(grad);
    err = real(err);
    
    %fprintf('JOINTFIT %s => %g, %s\n', mat2str(p, 3), err, mat2str(grad, 3));
    %assignin('base', 'p', p);
    
    %dbclear if infnan
end
