function manip_splat(S, state, scale)

    colors = 'bgrk';

    if length(state) == 1
        state = repmat(state, [1 length(S)]);
    end
    for j=1:length(S)
        S(j).state = state(j);
    end
    
    X = manip_simulate(3, max([S.a S.b]), 1, S, [0 0], eye(4), false);
    
    cla
    hold on
    plotted = zeros(1, max([S.a S.b]));
    for j=1:length(S)
        plot3(squeeze(X(1,[S(j).a S(j).b], 1,4)), ...
              squeeze(X(1,[S(j).a S(j).b], 2,4)), ...
              squeeze(X(1,[S(j).a S(j).b], 3,4)), ...
              '.');
        if ~plotted(S(j).a)
            plotted(S(j).a) = 1;
            plot_se(squeeze(X(1,S(j).a,:,:)), scale, 2);
        end
        if ~plotted(S(j).b)
            plotted(S(j).b) = 1;
            plot_se(squeeze(X(1,S(j).b,:,:)), scale, 2);
        end
    end
    for j=2:max([S.a S.b])
        plot3(squeeze(X(1,[j-1 j], 1,4)), ...
              squeeze(X(1,[j-1 j], 2,4)), ...
              squeeze(X(1,[j-1 j], 3,4)), ...
              colors(j-1), 'LineWidth', 2);
    end
    hold off
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
    
end
