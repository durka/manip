function draw_tree(h, S)
    nodes = zeros([1 max([S.a S.b])]);
    for i=1:length(S)
        nodes(S(i).b) = S(i).a;
    end
    
    axes(h);
    treeplot(nodes);
    xlabel('');
    set(gca, 'xticklabel', '');
    set(gca, 'yticklabel', '');
end