function draw_tree(h, S)
    nodes = zeros([1 max([S.a S.b])]);
    for i=1:length(S)
        nodes(S(i).b) = S(i).a;
    end
    
    axes(h);
    [x,y] = treelayout(nodes);
    treeplot(nodes);
    text(x, y, cellstr(num2str([1:length(nodes)]')), ...
         'VerticalAlignment','middle', ...
         'HorizontalAlignment','right');
    xlabel('');
    set(gca, 'xticklabel', '');
    set(gca, 'yticklabel', '');
end