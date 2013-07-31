function replay(X, cam, fpat)

    show(X, cam, fpat, 1);
    drawnow;
    a = axis;
    [az, el] = view;

    for f=1:size(X,1)
        show(X, cam, fpat, f);
        axis(a);
        view(az, el);
        drawnow;
        pause(0.001);
    end

endfunction

function show(X, cam, fpat, f)

    %clf;
    hold on;
    imshow(sprintf(fpat, f));
    x = [];
    for i = 1:size(X,2)
        y = cam' * eye(3,4) * squeeze(X(f,i,:,:)) * [10   0     0   1
                                                      5   0     0   1
                                                      2.5 0     0   1
                                                      1   0     0   1
                                                      0   10    0   1
                                                      0    5    0   1
                                                      0    2.5  0   1
                                                      0    1    0   1
                                                      0    0   10   1
                                                      0    0    5   1
                                                      0    0    2.5 1
                                                      0    0    1   1
                                                      0    0    0   1]';
        x = [x  y];
    end
    bsxfun(@rdivide, x(1:2,:), x(3,:))'
    plot(x(1,:)./x(3,:), x(2,:)./x(3,:), 'g.', 'MarkerSize',10);
    title(sprintf('frame %d', f));
    hold off;

endfunction

