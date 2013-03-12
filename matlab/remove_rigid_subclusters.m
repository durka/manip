function S = remove_rigid_subclusters(S, dbg)

    while true
        % remove one rigid joint at a time
        % by modifying every joint that begins or ends at the beginning of
        % the rigid one
        
        % find first rigid joint
        i = find(strcmp({S.joint}, 'rigid'), 1);
        if isempty(i)
            break;
        end
        
        dbg('\teliminating rigid joint %d-%d\n', S(i).a, S(i).b);
        
        % joints that end at the beginning of the rigid one
        for j = find([S.b] == S(i).a)
            dbg('\t\tadding transform after joint %d-%d\n', S(j).a, S(j).b);
            S(j).b = S(i).b;
            S(j).params = feval(['move_' S(j).joint], S(j).params, 'b', S(i).params{1});
        end
        
        % joints that begin at the beginning of the rigid one
        for j = find([S.a] == S(i).a)
            if j ~= i
                dbg('\t\tadding transform before joint %d-%d\n', S(j).a, S(j).b);
                S(j).a = S(i).b;
                S(j).params = feval(['move_' S(j).joint], S(j).params, 'a', S(i).params{1});
            end
        end
        
        S(i) = []; % nuke it from space (it's the only way to be sure)
    end
    
end


% TEST CASES
% 
% >> remove_rigid_subclusters(struct('a', {1 2 3}, 'b', {2 3 4}, 'joint', {'prismatic', 'rigid', 'revolute'}, 'params', { {eye(4) eye(1,3)} {eye(4)} {eye(4) eye(4)} }), @fprintf)
% 	adding transform after joint 1-2
% 
% ans = 
% 
% 1x2 struct array with fields:
%     a
%     b
%     joint
%     params
% 
% >> [ans.a; ans.b]
% 
% ans =
% 
%      1     3
%      3     4
% 
% >> remove_rigid_subclusters(struct('a', {1 7 2 9 3}, 'b', {7 2 9 3 12}, 'joint', {'prismatic', 'rigid', 'rigid', 'rigid', 'revolute'}, 'params', { {eye(4) eye(1,3)} {eye(4)} {eye(4)} {eye(4)} {eye(4) eye(4)} }), @fprintf)
% 	adding transform after joint 1-7
% 	adding transform after joint 1-2
% 	adding transform after joint 1-9
% 
% ans = 
% 
% 1x2 struct array with fields:
%     a
%     b
%     joint
%     params
% 
% >> [ans.a; ans.b]
% 
% ans =
% 
%      1     3
%      3    12
% 
% 
% >> remove_rigid_subclusters(struct('a', {1 2 3 4 4 6 6 6 10}, 'b', {4 4 4 5 6 7 8 9 6}, 'joint', {'prismatic' 'prismatic' 'prismatic' 'prismatic' 'rigid' 'revolute' 'revolute' 'revolute' 'revolute'}, 'params', { {eye(4) eye(1,3)} {eye(4) eye(1,3)} {eye(4) eye(1,3)} {eye(4) eye(1,3)} {eye(4)} {eye(4) eye(4)} {eye(4) eye(4)} {eye(4) eye(4)} {eye(4) eye(4)} }), @fprintf)
% 	adding transform after joint 1-4
% 	adding transform after joint 2-4
% 	adding transform after joint 3-4
% 	adding transform before joint 4-5
% 
% ans = 
% 
% 1x8 struct array with fields:
%     a
%     b
%     joint
%     params
% 
% >> [ans.a; ans.b]
% 
% ans =
% 
%      1     2     3     6     6     6     6    10
%      6     6     6     5     7     8     9     6
