function [x,y] = draw_tree(h, S, sel)
    nodes = zeros([1 max([S.a S.b])]);
    for i=1:length(S)
        nodes(S(i).b) = S(i).a;
    end
    
    save_callback = get(h, 'ButtonDownFcn');
    
    axes(h);
    [x,y] = treelayout(nodes);
    
    if sel > 0
        treeplot(nodes);
        hold on
        plot(x([S(sel).a S(sel).b]), y([S(sel).a S(sel).b]), 'LineWidth',2);
        hold off
        text(x, y, cellstr(num2str([1:length(nodes)]')), ...
             'VerticalAlignment','middle', ...
             'HorizontalAlignment','right');
        xlabel('');
        set(gca, 'xticklabel', '');
        set(gca, 'yticklabel', '');
    end
    
    set(h, 'ButtonDownFcn', save_callback);
    arrayfun(@(c) set(c, 'ButtonDownFcn', save_callback), get(h, 'Children'));
end