%% setup

fudges = 1:4;
noises = [0.025 0.05];
for i=2:4; noises(i,:) = noises(i-1,:)*2; end
runs = 4;

% make sure to define H and load the correct model in the GUI

%% automation

S = cell(length(fudges), length(noises), runs);
X = cell(length(fudges), length(noises), runs);

for f=1:length(fudges)
    fprintf('fudge=%d', fudges(f));
    
    %unfudge
    jmouseemu(H.unfudge, [], 'normal');
    pause(0.5);

    %enter new fudge factor and fudge
    jmouseemu(H.fudge_factor, [], 'open');
    inputemu('key_normal', sprintf('%d', fudges(f)));
    jmouseemu(H.fudge, [], 'normal');
    pause(0.5);

    for n=1:length(noises)
        fprintf('\n\tnoise=[%g %g]: run ', noises(n,1), noises(n,2));
        
        %enter new noise factor
        jmouseemu(H.noise, [], 'normal');
        jmouseemu(H.noise, [], 'open');
        inputemu('key_normal', sprintf('[%g, %g]', noises(n,1), noises(n,2)));
        pause(0.5);
        
        for r=1:runs
            fprintf('%d... ', r);

            %simulate and learn
            jmouseemu(H.simulate, [], 'normal');
            pause(0.5);
            jmouseemu(H.learn, [], 'normal');
            pause(0.5);

            %store results
            X{f,n,r} = DATA;
            S{f,n,r} = SS;
            save progress.mat S X
        end
    end
    fprintf('done!\n');
end

%% EEEEEVALUATION

%%    - reconstruct
Sf = cellfun(@(s,x) manip_fillout(s,x), S, X, 'UniformOutput',false);
Xr = cell(size(X));
for f=1:size(Xr,1)
    for n=1:size(Xr,2)
        for r=1:size(Xr,3)
            Xr{f,n,r} = manip_simulate(3, size(X{f,n,r},2), size(X{f,n,r},1), Sf{f,n,r}, [0 0], X{f,n,r}(1,1,:,:), false);
        end
    end
end

%%    - measure deltas

deltas = cellfun(@(s,x) arrayfun(@(a,b) calc_deltas(x,a,b), [s.a], [s.b], 'UniformOutput',false), S, X, 'UniformOutput',false);
deltasr = cellfun(@(s,x) arrayfun(@(a,b) calc_deltas(x,a,b), [s.a], [s.b], 'UniformOutput',false), Sf, Xr, 'UniformOutput',false);

%%    - compare

diffs = zeros(size(X));
for f=1:size(Xr,1)
    for n=1:size(Xr,2)
        for r=1:size(Xr,3)
            if length(deltas{f,n,r}) == length(deltasr{f,n,r})
                diffs(f,n,r) = sqrt(sum(arrayfun(@(i) sum(cellfun(@SE_dist, deltas{f,n,r}{i}, deltasr{f,n,r}{i})), 1:length(deltas{f,n,r}))));
            else
                diffs(f,n,r) = nan;
            end
        end
    end
end

%%    - plot

clf
Is = [1 4];
for i=1:length(Is)
    
    % draw theoretical trees
    subplot(3,2,i);
    draw_tree(gca, manip_fudge(rmfield(S{1,1,1}, 'cost'), 3, fudges(Is(i))), 0, 'joints');
    
    if Is(i)==1
        title('No inflation', 'FontSize',18);
    else
        title(sprintf('Inflate x%d', Is(i)), 'FontSize',18);
    end
    
    % plot objective
    subplot(3,2,2+i);
    errorbar(median(squeeze(diffs(Is(i),:,:)), 2), std(squeeze(diffs(Is(i),:,:)), [], 2));%, 'b.', 'MarkerSize', 15);
    a = axis;
    axis([0.5 4.5 0 a(4)]);
    
    % draw learned trees
    subplot(3,2,4+i);
    draw_tree(gca, S{Is(i),1,1}, 0, 'joints');
end
[~,h] = suplabel('Noise multiplier', 'x', [.08 .1 .84 .84]);
set(h, 'FontSize',18);
[~,h] = suplabel('Total error', 'y', [.1 .08 .84 .84]);
set(h, 'FontSize',18);