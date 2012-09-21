function plot_points(X, T)
    colors = 'bgrk';

    % plot the first frame
    h = zeros(1, length(T));
    clf;
    hold on;
        for j = 1:length(T)
            fprintf('%d(%g, %g) - %d(%g, %g)\n', T(j).a, X(1,T(j).a,1), X(1,T(j).a,2), T(j).b, X(1,T(j).b,1), X(1,T(j).b,2));
            h(j) = plot([X(1,T(j).a,1), X(1,T(j).b,1)], ...
                        [X(1,T(j).a,2), X(1,T(j).b,2)], ...
                        [colors(j) '.-']);
        end
    hold off;
    axis([-5 5 -5 5]);
    
    for f = 2:size(X, 1)
        % update the data
        for j = 1:length(T)
            set(h(j)', 'XData',[X(f,T(j).a,1), X(f,T(j).b,1)], ...
                       'YData',[X(f,T(j).a,2), X(f,T(j).b,2)]);
        end
        pause(0.1);
        drawnow;
    end
end
