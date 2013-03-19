function S = fixup_indices(S, dbg)

    for i = 1:max([S.a S.b])
        j = i;
        
        if j > [S.a S.b]
            break
        end
        
        while j ~= [S.a S.b]
            j = j + 1;
        end
        
        if j ~= i
            dbg('\t%d >= %d\n', j, i);
            dbg('\t\t%s\n\t\t%s\n', mat2str([S.a]), mat2str([S.b]));
            for k = find([S.a] == j)
                S(k).a = i;
            end
            for k = find([S.b] == j)
                S(k).b = i;
            end
            dbg('\t\t%s\n\t\t%s\n', mat2str([S.a]), mat2str([S.b]));
        end
    end

end