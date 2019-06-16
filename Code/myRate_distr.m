% David Eriksson, 2019

clear variables; % Such that debugging can be done as if the script was called as a new octave instance
close all;

warning('off');

try
    OCTAVE_VERSION
    disp('octave is running');
    matlab1_octave0 = 0;
catch
    disp('matlab is running');
    version;
    matlab1_octave0 = 1;
end

try 
    debugging = 1;

    fid = fopen('myRateMainPath.txt','r');
    resultsPath = char(fread(fid)');
    fclose(fid);

    resultsTODOPath = [resultsPath 'TODO\'];

    fid = fopen(['parallelControlPath.txt'],'r');
    parallelControlPath = char(fread(fid)');
    fclose(fid);
    
    rand('state',time*10000000000);  %cputime is relative to the start of the instance: useless
    thisJobNr = round(time*10000000000);
    fid = fopen([resultsPath 'Running\' num2str(thisJobNr) '.txt'],'w'); fclose(fid);

    finishedJobs = 0;
    while ~finishedJobs

        found = 0;
        while found == 0  
            try
                [st, str] = matlabOctaveLs(resultsTODOPath, matlab1_octave0);
                found = 1;
            catch
                found = 0;
                disp('dir error');
                pause(1);
            end
        end

        disp('directory extraction');

        stopInds = strfind(str,'.txt');
        if isempty(stopInds)
            finishedJobs = 1;
            continue;
        end

        startInds = [1 stopInds(1:(end-1))+5];
        st = [];
        for i=1:length(startInds)
            st(i).name = str(startInds(i):(stopInds(i)+3));
        end

        disp('directory extracted');

        i=1;
        currentDirFile = [resultsTODOPath st(i).name];
        while (~exist(currentDirFile)) && (i < length(st))
            i=i+1;
            currentDirFile = [resultsTODOPath st(i).name];
        end
        delete(currentDirFile);
        fid = fopen([resultsPath 'DONE\' st(i).name],'w'); fclose(fid);

        currentDirFile

        sessionName = st(i).name(1:(end-4));
        currentFile = [resultsPath sessionName];

        trainingDataDir = sessionName;

        g_opts.loadTemporalResolution = 10;
        LoadTrainingAndTestData;

        uc = unique(g_trainingAndTestData{1}(:,1));

        maxBin = max(g_trainingAndTestData{1}(:,2))+1;
        summedBins = zeros(1, maxBin,'double');

        frs = [];
        spikeCount = zeros(max(uc), 1);
        for ui=1:max(uc)

            inds = find(g_trainingAndTestData{1}(:,1) == ui);

            frs = [frs length(inds)/(max(g_trainingAndTestData{1}(:,2))/100)];
            ts = g_trainingAndTestData{1}(inds,2);
            summedBins(ts+1) = summedBins(ts+1) + 1;

            spikeCount(ui) = length(inds);
        end

        edges = (-1000):1000;
        myRate = zeros(max(uc),1);
        for ui=1:max(uc)
            %if debugging; fid = fopen([debugPath resultFolderName '.txt'],'w'); fprintf(fid,'%d: 1',ui); fclose(fid);  end;
            inds = find(g_trainingAndTestData{1}(:,1) == ui);
            if isempty(inds)
                continue;
            end
            
            if ui==472
                ui =ui;
            end

            ts = g_trainingAndTestData{1}(inds,2);
            onlyUi = summedBins*0;
            onlyUi(ts+1) = onlyUi(ts+1) + 1;
            sumWithout = summedBins - onlyUi;
            ts = ts((ts + min(edges)) > 0);
            ts = ts((ts + max(edges)) <= maxBin);

            tbins = sumWithout';
            % Divide with a for loop to decrease memory consumption
            Skip = 100;
            summedCC = [];
            for ei=0:Skip:(length(edges)-1)
                edgeInds = ei+(1:Skip);
                edgeInds = edgeInds(edgeInds <= length(edges));
                inds = repmat(ts',length(edgeInds),1)+repmat(edges(edgeInds)',1,length(ts));
                if length(edgeInds)>1
                    summedCC = [summedCC sum(tbins(inds),2)'/spikeCount(ui)*100];
                else
                    summedCC = [summedCC sum(tbins(inds))'/spikeCount(ui)*100];
                end
            end
            myRate(ui) = min(summedCC);
            fprintf('folderName: %s, %d, myRate: %d\n',sessionName, ui,myRate(ui));
            pause(0.1); % necessary for avoiding display output hanging in the MATLB command window



            save([resultsPath sessionName '_myRate.mat'],'myRate','frs','spikeCount');

        end

        if exist(parallelControlPath)
            return;
        end
    end
    
    delete([resultsPath 'Running\' num2str(thisJobNr) '.txt']);
catch
    displayLastError();
    
    pause
end