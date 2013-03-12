%% setup

fudges = 1:5;
noises = [0 0; 0.025 0.05];
for i=3:5; noises(i,:) = noises(i-1,:)*2; end
runs = 5;

% make sure to define H and load the correct model in the GUI

%% automation

S = cell(length(fudges), length(noises), runs);
X = cell(length(fudges), length(noises), runs);

for f=1:length(fudges)
    fprintf('fudge=%d', fudges(f));
    for n=1:length(noises)
        fprintf('\n\tnoise=[%g %g]: run ', noises(n,1), noises(n,2));
        
        %enter new noise factor
        jmouseemu(H.noise, [], 'open');
        inputemu('key_normal', sprintf('[%g, %g]', noises(n,1), noises(n,2)));
        pause(0.5);
        
        for r=1:runs
            fprintf('%d... ', r);

            clear SS

            %unfudge
            jmouseemu(H.unfudge, [], 'normal');
            pause(0.5);

            %enter new fudge factor and fudge
            jmouseemu(H.fudge_factor, [], 'open');
            inputemu('key_normal', sprintf('%d', fudges(f)));
            jmouseemu(H.fudge, [], 'normal');
            pause(0.5);

            %simulate and learn
            jmouseemu(H.simulate, [], 'normal');
            jmouseemu(H.learn, [], 'normal');

            %store results
            X{f,n,r} = DATA;
            S{f,n,r} = SS;
        end
    end
    fprintf('done!\n');
end
