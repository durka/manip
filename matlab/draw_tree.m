% labelmode: none, nodes (default), joints, all
function [x,y] = draw_tree(h, S, sel, labelmode)
    if ~exist('labelmode', 'var')
        labelmode = 'nodes';
    end

    nodes = zeros([1 max([S.a S.b])]);
    for i=1:length(S)
        nodes(S(i).b) = S(i).a;
    end
    
    save_callback = get(h, 'ButtonDownFcn');
    
    axes(h);
    [x,y] = treelayout(nodes);
    
    if sel >= 0
        % do the labels (depending on mode)
        if strcmp(labelmode, 'all') || strcmp(labelmode, 'nodes')
            text(x, y, cellstr(num2str([1:length(nodes)]')), ...
                 'VerticalAlignment','middle', ...
                 'HorizontalAlignment','right');
        end
        if strcmp(labelmode, 'all') || strcmp(labelmode, 'joints')
            treeplot(nodes, 'c.', '');
            
            colors = struct('rigid','c', 'prismatic','r', 'revolute','k--');
            hold on;
            for i=1:length(S)
                plot(x([S(i).a S(i).b]), y([S(i).a S(i).b]), colors.(S(i).joint));
            end
            hold off;
        else
            treeplot(nodes);
        end
        
        % selected joint
        if sel > 0
            hold on
            plot(x([S(sel).a S(sel).b]), y([S(sel).a S(sel).b]), 'LineWidth',2);
            hold off
        end
        
        xlabel('');
        set(gca, 'xticklabel', '');
        set(gca, 'yticklabel', '');
    end
    
    set(h, 'ButtonDownFcn', save_callback);
    arrayfun(@(c) set(c, 'ButtonDownFcn', save_callback), get(h, 'Children'));
end