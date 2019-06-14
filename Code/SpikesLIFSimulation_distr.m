% David Eriksson, 2019

clear variables; % Such that debugging can be done as if the script was called as a new octave instance
close all;

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

    fid = fopen('spikesMainPath.txt','r');
    resultsPath = char(fread(fid)');
    fclose(fid);

    resultsTODOPath = [resultsPath 'TODO\'];

    fid = fopen(['parallelControlPath.txt'],'r');
    parallelControlPath = char(fread(fid)');
    fclose(fid);
    
    rand('state',cputime*100000);    
    %thisJobNr = round(cputime*1000000);
    thisJobNr = round(rand(1)*1000000000);
    fid = fopen([resultsPath 'Running\' num2str(thisJobNr) '.txt'],'w'); fclose(fid);

    finishedJobs = 0;
    while ~finishedJobs

        found = 0;
        while found == 0  
            try
                %[st, str]= system(['ls ' resultsTODOPath]);
                [st, str] = matlabOctaveLs(resultsTODOPath, matlab1_octave0);
                found = 1;
            catch
                found = 0;
                disp('dir error');
                pause(1);
            end
        end
        
        disp('directory extraction');
        
        startInds = strfind(str,'LIF');
        stopInds = strfind(str,'.txt');
        st = [];
        for i=1:length(startInds)
            st(i).name = str(startInds(i):(stopInds(i)+3));
        end
        
        if isempty(st)
            finishedJobs = 1;
            continue;
        end
        
        disp('directory extracted');
      
        i=1;
        currentDirFile = [resultsTODOPath st(i).name];
        while (~exist(currentDirFile)) && (i < length(st))
            i=i+1;
            currentDirFile = [resultsTODOPath st(i).name];
        end
        fid = fopen([resultsPath 'DONE\' st(i).name],'w'); fclose(fid);
        delete(currentDirFile);
        
        currentFilePure = st(i).name(1:(end-4));
        
        % Parameters are stored in the dir-filename
        inds = strfind(currentFilePure,'_');

        powVal = str2num(currentFilePure((inds(1)+3):(inds(2)-1)));
        simTime = str2num(currentFilePure((inds(2)+3):(inds(3)-1)));
        noiseAmp = str2num(currentFilePure((inds(3)+3):(inds(4)-1)));
        connectionStrength = str2num(currentFilePure((inds(4)+3):(inds(5)-1)));
        condCount = str2num(currentFilePure((inds(5)+3):(inds(6)-1)));
        condDur = str2num(currentFilePure((inds(6)+3):(inds(7)-1)));
        N = str2num(currentFilePure((inds(7)+3):(inds(8)-1)));
        embDim = str2num(currentFilePure((inds(8)+3):(inds(9)-1)));
        saveAnalog = str2num(currentFilePure((inds(9)+3):(inds(10)-1)));  
        
        folderName = currentFilePure(1:(inds(10)-1));
        mkdir([resultsPath folderName]);
        
        folderName
        
        more off;
        T = simTime*1000+1;
        TrialRunT = condDur*1000;
        TrialBreakT = 0;

        rand('state',1);
        randn('state',1);
                
        EM = randn(N,embDim);
        input_e4r = exp(-4*rand(embDim,1));
        output_e4r = exp(-4*rand(N,1));
        
        noise = zeros(N,1)+noiseAmp;
        
        rand('state',cputime*1000000);
        randn('state',cputime*1000000);
            
                
        fixedNoise = randn(N,T);

        embedding = VmL23_Move_Noise(embDim,T);

        embedding = embedding.*repmat(input_e4r,1,size(embedding,2));
        conditionInfo = zeros(1,size(embedding,2));

        if ~isinf(condCount)
            ti = 0;
            while ti<=T
                rand('state',cputime*1000000);
                randn('state',cputime*1000000);
        
                ci = randi(condCount);
                ci
                rand('state',ci);
                randn('state',ci);
                
                inds = ti+(1:TrialRunT);
                inds = inds(inds>0);
                inds = inds(inds<=T);
                %preCalcNoise((N_out+1):N,inds) = randn(N_in,length(inds));
                embedding(:,inds) = VmL23_Move_Noise(embDim,length(inds));
                conditionInfo(inds) = ci;
                ti = ti + TrialRunT;
                
                % Do we want a break?
                if TrialBreakT > 0
                    inds = ti+(1:TrialBreakT);
                    inds = inds(inds>0);
                    inds = inds(inds<=T);
                    embedding(:,inds) = 0;
                    ti = ti + TrialBreakT;
                 end
                
            end
        end

        commonInput = EM*embedding;

        commonInput = commonInput.*repmat(output_e4r,1,size(commonInput,2));

        commonInput = commonInput/std(commonInput(:));

        commonInput = commonInput*connectionStrength;
            

        [spk, NetParams, V, SynInputs, SynCurrents] = SimLIFFeedforwardNet(commonInput, 'tstep',0.001, 'simTime',simTime, 'noiseAmplitude',noise,'refractoryTime',noise*0+0.002,'fixedNoise',fixedNoise);

        Hzs = cellfun('length',spk)/simTime;
        mean(Hzs)
        pause(0.1); % necessary for avoiding display output hanging in the MATLB command window
        
        %disp('ready');
        %figure(1); clf; plot(SynInputs(1,:)); pause;
        
        if isempty(spk)
            Hzs = [];
            return;
        end

        

        if saveAnalog    
            Vlast1s = V(1:60,:);
            SynInputs = SynInputs(1:60,:);
            SynCurrents = SynCurrents(1:60,:);
        else
            Vlast1s = [];
            SynInputs = [];
            SynCurrents = [];
        end
            
        disp('saving');
        saveLIFData([resultsPath folderName '\' currentFilePure '.bin'],spk,Vlast1s,SynInputs,SynCurrents,conditionInfo);

        rates = cellfun(@length,spk)'/simTime;
        fid = fopen([resultsPath folderName '\' currentFilePure 'rates.bin'],'w'); fwrite(fid,rates,'single'); fclose(fid);
        
        if exist(parallelControlPath)
            return;
        end
    end
    
    delete([resultsPath 'Running\' num2str(thisJobNr) '.txt']);
catch
    displayLastError();
    
    pause
end