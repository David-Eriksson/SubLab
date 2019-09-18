% David Eriksson, 2019
% ZC Danziger, 2015 (modified version of SimLIFNet for the LIF simulation, see SimLIFFeedforwardNet.m)
% Chengxi Ye, 2017, (backprop code was initially written using LightNet)
% Wen-Jie Zhao, Jens Kremkow, James F.A. Poulet, 2016 "Translaminar Cortical Membrane Potential Synchrony in Behaving Mice" was used to extract power spectrum for VmL23_Move_Noise.m

try
    OCTAVE_VERSION
    disp('octave is running');
    matlab1_octave0 = 0;
catch
    disp('matlab is running');
    version;
    matlab1_octave0 = 1;
end

%disp('When running the rest of the neuropixels!!!! Please remove the training "if 0"');
%disp('and remove generateSeedFiles!!!');
%pause

warning('off');

if 0
    publishPath = 'C:\Users\daffs\Documents\David\SubLab_publish\';
    delete([publishPath '*.txt']);
    delete([publishPath '*.m']);
    copyDependencies2Folder('SubLab',publishPath);
    copyfile('VmL23_Move_Spektrum.txt',publishPath);
end

% **************************************************************
%     Start: Defining what spiking data to reconstruct
% **************************************************************
dirStrs = {};
notDirStrs = {''};

intracellularPathFile = [];

if isempty(dirStrs)
   
    %msgStr = ['You are in the manual mode of SubLab. Here you can choose a spike file. ' char(10) 'If you choose CANCEL in the file dialog you will simulate spikes. ' char(10) 'To get in the batch mode of SubLab you have to fill in the variable "dirStrs" in the SubLab.m.' char(10) 'This should be filled in with the directory names (in the spikes directory) you want to process.' char(10) 'For example dirStrs = {''animal1_day1'',''animal2_day1''};' char(10) 'where animal1_day1 and animal2_day1 are folders in the spikes directory.' char(10) 'By running the manual mode one or more "test" directories will be created in the spikes folder. '];
    msgStr = ['You are in the manual mode of SubLab. Here you can choose a spike file. If you choose CANCEL in the file dialog spikes will be simulated. ' char(10) 'To get in the batch mode of SubLab you have to fill in the variable "dirStrs" in the SubLab.m. This should be filled in with the directory names (in the spikes directory) you want to process. For example dirStrs = {''animal1_day1'',''animal2_day1''}; where animal1_day1 and animal2_day1 are folders in the spikes directory. By running the manual mode one or more "test" directories will be created in the spikes folder. '];
    msgbox(msgStr,'SubLab'); 
    
    [fname, fpath, fltidx] = uigetfile('*.bin', 'Select spike file');
    
    if fname(1) ~= 0
        % Check that spiking data is according to format
        % Below: path to spiking data. Binary file consisting of pairs of 'doubles': Spike Identity (Unit number) and Spike time (seconds)
        fid = fopen([fpath fname],'r');
        spikes = fread(fid,'double');
        fclose(fid);
        infoStr = ['Number of units: ' num2str(length(unique(spikes(1:2:end)))) char(10) 'Recording duration (seconds): ' num2str(max(spikes(2:2:end))) char(10) 'Average firing rate (Hz):  ' num2str(length(spikes)/2/length(unique(spikes(1:2:end)))/max(spikes(2:2:end)))];
        
        answer = questdlg(infoStr,'Is this spike information correct?','Yes','No','Yes');
        if strcmp(answer,'No')==1
            return;
        end
      
        spikePath = [fpath fname]; %'D:\Data\Spikes\c42_c42\PlainSpikeData_c42.bin';
        answer = questdlg('Do you have intracellular data?','Intracellular data','Yes','No','Yes');
        if strcmp(answer,'Yes')==1           
        
            [fname, fpath, fltidx] = uigetfile([fpath '*.bin'], 'Select intracellular file');
            if fname(1) ~= 0
                targetNeurons = [1];
                
                intracellularPathFile = [fpath fname];
                fid = fopen([fpath fname],'r');
                intracellularData = fread(fid,'single');
                fclose(fid);
                figure(1); clf; plot(intracellularData(1:10000));
                
                answer = questdlg('Are the intracellular values plotted in figure 1 correct?','Intracellular data','Yes','No','Yes');
                if strcmp(answer,'No')==1
                    return;
                end
            end
        else
            targetNeurons = inputdlg('Type in which units to reconstruct (empty => all units)','Target units',1,{'1'});
            if isempty(targetNeurons) || isempty(targetNeurons{1})
                targetNeurons = unique(spikes(1:2:end));
                answer = questdlg('Do you want to reconstruct all units?','Target units','Yes','No','Yes');
                if strcmp(answer,'No')==1
                    return;
                end
            else
                targetNeurons = str2num(targetNeurons{1});   
            end            
        end
    else    
        spikePath = []; %do simulation
        targetNeurons = [1 11 16 17]; % Just an arbitrary selection of units from the file
    end
    
    
end

% The following values depends on the number of cores and amount of memory of your workstation
% Run it first with 2 on each to see how much memory your data take and how much processing power it requires 
ReconstructionTraining_ProcessCount = 2; % 40 on a Threadripper 2990WX (32 Core, 64Gb)
ReconstructionComplete_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
myRate_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
Simulation_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
fid = fopen(['maxNumberOfEpochs.txt'],'w');
fprintf(fid,'%d',5); % Typically 30 or more
fclose(fid);

fid = fopen(['batchSizeIn10msBins.txt'],'w');
fprintf(fid,'%d',5000); % Typically 5000, means a batch size of 5000*10ms = 50seconds. Reduce this to decrease memory consumption. 
fclose(fid);

% **************************************************************
%     Stop: Defining what spiking data to reconstruct
% **************************************************************

% **************************************************************
%     Start: Path setup
% **************************************************************

if 0
    if matlab1_octave0
        matlabOctavePath = [matlabroot '\'];
        fid = fopen(['matlabPath.txt'],'w');
        fprintf(fid,'%s',matlabOctavePath);
        fclose(fid);
    else
        matlabOctavePath = [matlabroot '\'];
        fid = fopen(['octavePath.txt'],'w');
        fprintf(fid,'%s',matlabOctavePath);
        fclose(fid);        
    end
end

if 1
    if (exist('matlabPath.txt') && (matlab1_octave0==1)) || (exist('octavePath.txt') && (matlab1_octave0==0))
        if matlab1_octave0
            fid = fopen(['matlabPath.txt'],'r');
            matlabOctavePath = char(fread(fid)');
            fclose(fid);
        else
            fid = fopen(['octavePath.txt'],'r');
            %matlabOctavePath = fscanf(fid,'%s');
            matlabOctavePath = char(fread(fid)');
            fclose(fid);
        end
    else
        disp('To find the path to the executable: Right-click on the matlab/octave application icon.');
        if matlab1_octave0
            [fname, fpath, fltidx] = uigetfile('*.exe', 'Select Matlab binary file');
        else
            [fname, fpath, fltidx] = uigetfile('*.vbs', 'Select Octave binary file');
        end
        if fname(1) == 0
            disp('Matlab/Octave executable has to be selected!');
            pause;
        end
        matlabOctavePath = [fpath fname];
        matlabOctavePath = ['"' matlabOctavePath '"']; % Accept spaces in the path

        % Should be something like:
        % matlabOctavePath = 'C:\Octave\Octave-4.4.1\octave.vbs';
        % matlabOctavePath = 'C:\Program Files\MATLAB\R2019a\bin\matlab.exe';
        if matlab1_octave0
            fid = fopen(['matlabPath.txt'],'w');
            fprintf(fid,'%s',matlabOctavePath);
            fclose(fid);
        else
            fid = fopen(['octavePath.txt'],'w');
            fprintf(fid,'%s',matlabOctavePath);
            fclose(fid);        
        end
    end
end


sublabPath = [fileparts(mfilename('fullpath')) '\'];

if exist('mainPath.txt')
    fid = fopen(['mainPath.txt'],'r');
    mainPath = char(fread(fid)');
    fclose(fid);  
else
    mainPath = uigetdir('', 'Select folder where the data will be saved');
    if strcmp(mainPath(end),'\')==0
        mainPath = [mainPath '\'];
    end
    fid = fopen(['mainPath.txt'],'w');
    fprintf(fid,'%s', mainPath);
    fclose(fid);
end

parallelControlPath = [mainPath 'stop.txt'];
fid = fopen(['parallelControlPath.txt'],'w');
fprintf(fid,'%s',parallelControlPath);
fclose(fid);

spikesMainPath = [mainPath 'Spikes\'];
mkdir(spikesMainPath);
mkdir([spikesMainPath 'TODO\']); % Used when spikes are created from simulation
mkdir([spikesMainPath 'DONE\']);
mkdir([spikesMainPath 'Running\']); % Each process puts a file here
fid = fopen(['spikesMainPath.txt'],'w');
fprintf(fid,'%s',spikesMainPath);
fclose(fid); 

resultsMainPath = [mainPath 'ReconstructionTraining\'];
mkdir(resultsMainPath);
mkdir([resultsMainPath 'TODO\']);
mkdir([resultsMainPath 'DONE\']);
mkdir([resultsMainPath 'Running\']);
mkdir([resultsMainPath 'RunningInfo\']);
delete([resultsMainPath 'RunningInfo\*']);
mkdir([resultsMainPath 'Error\']);
delete([resultsMainPath 'Error\*']);
mkdir([resultsMainPath 'LastReadFile']);
delete([resultsMainPath 'LastReadFile\*']);
fid = fopen(['resultsMainPath.txt'],'w');
fprintf(fid,'%s',resultsMainPath);
fclose(fid); 

fullReconstructionMainPath = [mainPath 'ReconstructionComplete\'];
mkdir(fullReconstructionMainPath);
mkdir([fullReconstructionMainPath 'TODO\']);
mkdir([fullReconstructionMainPath 'DONE\']);
mkdir([fullReconstructionMainPath 'Running\']);
mkdir([fullReconstructionMainPath 'Error\']);
delete([fullReconstructionMainPath 'Error\*']);
mkdir([fullReconstructionMainPath 'LastReadFile']);
delete([fullReconstructionMainPath 'LastReadFile\*']);


fid = fopen(['fullReconstructionMainPath.txt'],'w');
fprintf(fid,'%s',fullReconstructionMainPath);
fclose(fid); 

myRateMainPath = [mainPath 'myRate\'];
mkdir(myRateMainPath);
mkdir([myRateMainPath 'TODO\']);
mkdir([myRateMainPath 'DONE\']);
mkdir([myRateMainPath 'Running\']);
fid = fopen(['myRateMainPath.txt'],'w');
fprintf(fid,'%s',myRateMainPath);
fclose(fid); 





% **************************************************************
%     Stop: Path setup
% **************************************************************

% **************************************************************
%     Start: Initialize Processing
% **************************************************************

answer = questdlg('What do you want to do?','Processing','Run from scratch!','Resume','Cancel','Resume');
if strcmp(answer,'Resume (If you have already run it and paused with a stop.txt file)') == 1
    resume1_overwrite0 = 1;
elseif strcmp(answer,'Run from scratch!') == 1
    answer = questdlg('Are you sure? This will delete all reconstructions!','Processing','Yes','No','No');
    if strcmp(answer,'No') == 1
        return;
    end
    resume1_overwrite0 = 0;
else
    return;
end

delete([spikesMainPath 'TODO\' '*.txt']);
delete([spikesMainPath 'DONE\' '*.txt']);

delete([resultsMainPath 'TODO\' '*.txt']);
delete([resultsMainPath 'DONE\' '*.txt']);

delete([fullReconstructionMainPath 'TODO\' '*.txt']);
delete([fullReconstructionMainPath 'DONE\' '*.txt']);

delete([myRateMainPath 'TODO\' '*.txt']);
delete([myRateMainPath 'DONE\' '*.txt']);

% **************************************************************
%     Stop: Initialize Processing
% **************************************************************


if isempty(dirStrs) && isempty(spikePath)
   
    
    %************************************************
    %   Start: Run two different LIF simulations to generate spikes
    %***********************************************

    dirStrs = [];
            
    for si=1:2 % Two simulations
        noiseAmp = 0;
        connectionStrength = 1.78;
        simTime = 20; % Data is saved in chunks of 20 seconds
        repetitions = 50;  % 50*20 = 1000 seconds
        saveAnalog = 1;
        condDur = 4; % 4seconds "trial"
        embDim = 40; % Number of independent inputs
        N = 200; % Number of neurons
        condCount = Inf; % For example 1, 16, 256, or Inf
        
        if si==2
            embDim = 10;
        end
            
        
        preFix = ['LIF'];
        preFix = [preFix '_ex' num2str(4)];
        preFix = [preFix '_sT' num2str(simTime)];
        preFix = [preFix '_nA' num2str(noiseAmp,3)];
        preFix = [preFix '_cA' num2str(connectionStrength,3)];
        preFix = [preFix '_cd' num2str(condCount)];
        preFix = [preFix '_du' num2str(condDur)];
        preFix = [preFix '_nC' num2str(N)];
        preFix = [preFix '_eD' num2str(embDim)];
        sessionName = [preFix '_an' num2str(saveAnalog)];

        for repetition = 1:repetitions
            
            preFix = [sessionName '_rp' num2str(repetition) '.txt'];
            
            % Have to check if already prepared or already done...
            if exist([spikesMainPath 'TODO\' preFix])
                continue;
            end
            
            if exist([spikesMainPath 'DONE\' preFix])
                continue;
            end

            fid = fopen([spikesMainPath 'TODO\' preFix],'w'); fclose(fid);
        end
        
        dirStrs{si} = sessionName;
    end
    
    if 1 % For debugging put to 0 and call SpikesLIFSimulation_distr.m manually
        finished = 1;
        [st, str] = matlabOctaveLs([spikesMainPath 'TODO\'], matlab1_octave0);
        if ~isempty(str)
            finished = 0;
        end
        delete([spikesMainPath 'Running\*']);
        
        newlyCreatedSpikes = 0;
        
        while ~finished
            
            for i=1:Simulation_ProcessCount
                if matlab1_octave0 == 0
                    system([matlabOctavePath ' --no-gui ' sublabPath 'SpikesLIFSimulation_distr.m']);
                else
                    system([matlabOctavePath ' -nodisplay -nosplash -nodesktop -singleCompThread -r "run(''' sublabPath 'SpikesLIFSimulation_distr.m'');exit;"'])
                end
                pause(1); % Important for ensuring unique processes identities since they are defined by time. 
            end
            
            
            
            disp('Running simulation to generate spikes...');
            pause(10); % Waiting for all "Running" files to be written to disk.
            disp('If you want to pause put an empty textfile:');
            disp(parallelControlPath);
            disp('');
            
            while (~exist(parallelControlPath)) && (~finished)
                finished = 1;
                [st, str] = matlabOctaveLs([spikesMainPath 'Running\'], matlab1_octave0);
                if ~isempty(str)
                    finished = 0;
                end
                pause(5);
            end
            
            newlyCreatedSpikes = 1;

            if ~finished            
                disp('Stopped');
                disp('Can now press Ctrl-C or remove the stop-file to resume processing');
                while exist(parallelControlPath) && (~finished)
                    pause(10);
                end
            end
        end
    else
        SpikesLIFSimulation_distr;
    end
    
    disp('Put spikes together');
    
    % Put together simulated spikes, current, and voltage traces
    if newlyCreatedSpikes
        for di=1:length(dirStrs)
            spikeIdAndTime = [];
            intracellularActivity = [];
            
            fi = 1;
            while exist([spikesMainPath dirStrs{di} '\' dirStrs{di} '_rp' num2str(fi) '.bin'])
                filename = [spikesMainPath dirStrs{di} '\' dirStrs{di} '_rp' num2str(fi) '.bin'];
                [N,spk,Vlast1s,SynInputs, SynCurrents] = loadLIFData(filename);
                spk = spk([2 1],:);
                spk(2,:) = spk(2,:)/1000+(fi-1)*simTime;
                spikeIdAndTime = [spikeIdAndTime spk];
                
                intracellularActivity = [intracellularActivity Vlast1s(targetNeurons,:)];
                
                delete([spikesMainPath dirStrs{di} '\' dirStrs{di} '_rp' num2str(fi) '.bin']);
                delete([spikesMainPath dirStrs{di} '\' dirStrs{di} '_rp' num2str(fi) 'rates.bin']);
                
                
                fi = fi + 1;
            end
            
            fid = fopen([spikesMainPath dirStrs{di} '\' dirStrs{di} '.bin'],'w');
            fwrite(fid,spikeIdAndTime(:),'double');
            fclose(fid);
            
            fid = fopen([spikesMainPath dirStrs{di} '\' 'IntracellularActivity.bin'],'w');
            fwrite(fid,intracellularActivity(:),'float');
            fclose(fid);
            
            fid = fopen([spikesMainPath dirStrs{di} '\' 'TargetNeurons.bin'],'w');
            fwrite(fid,targetNeurons(:),'int');
            fclose(fid);
        end    
    end
    %************************************************
    %   Stop: Run two different LIF simulations to generate spikes
    %***********************************************
    
elseif isempty(dirStrs) && ~isempty(spikePath)     
    %************************************************
    %   Start: Load demo spikes
    %***********************************************

    [a sessionName c] = fileparts(spikePath);
    mkdir([spikesMainPath sessionName]);
    copyfile(spikePath,[spikesMainPath sessionName '\' sessionName '.bin']);
    disp('Spike file was copied to the "Spikes directory":');
    disp([spikesMainPath sessionName]);
    disp('');
    dirStrs = {sessionName};
    
    if ~isempty(intracellularPathFile)
        copyfile(intracellularPathFile,[spikesMainPath sessionName '\IntracellularActivity.bin']);
        disp('Intracellular file was copied to the "Spikes directory":');
        disp([spikesMainPath sessionName]);
        disp('');
    end
    
    fid = fopen([spikesMainPath sessionName '\TargetNeurons.bin'],'w');
    fwrite(fid,targetNeurons(:),'int');
    fclose(fid);
    
    %************************************************
    %   Stop: Load demo spikes
    %***********************************************
end
clear targetNeurons;

%*****************************************************************
%   Start: dirStrs may contain asterisk (*) to define multiple folders
%*****************************************************************
ci = 1;
notTrainingDataDirs = [];
for di = 1:length(notDirStrs)
    folders = [];
    if isempty(strfind(notDirStrs{di},'*'))
        folders(1).isdir = 1;
        folders(1).name = notDirStrs{di};
    else
        folders = dir([spikesMainPath notDirStrs{di}]);
    end
    
    for fi=1:length(folders)
        if folders(fi).isdir
        
            sessionName = folders(fi).name;
             
            notTrainingDataDirs{ci} = sessionName;
            ci = ci + 1;
        end 
    end
end

ci = 1;
trainingDataDirs = [];
for di = 1:length(dirStrs)
    folders = [];
    if isempty(strfind(dirStrs{di},'*'))
        folders(1).isdir = 1;
        folders(1).name = dirStrs{di};
    else
        folders = dir([spikesMainPath dirStrs{di}]);
    end
    
    for fi=1:length(folders)
        if folders(fi).isdir
        
            sessionName = folders(fi).name;
            
            found = 0;
            for ni=1:length(notTrainingDataDirs)
                if strcmp(notTrainingDataDirs{ni},sessionName) == 1
                    found = 1;
                end
            end
            
             if ~found
                trainingDataDirs{ci} = sessionName;
                disp(trainingDataDirs{ci});
                ci = ci + 1;
             end
        end 
    end
end
disp('Ctrl-C if those folders should not be processed!');
pause

fid = fopen(['totalFolderNumbers.txt'],'w');
fprintf(fid,'%d',length(trainingDataDirs)); 
fclose(fid);

numberOfTrainingSets = 1;
disp(['numberOfTrainingSets: ' num2str(numberOfTrainingSets) ', ok?']);
pause
fid = fopen(['numberOfTrainingSets.txt'],'w');
fprintf(fid,'%d',numberOfTrainingSets); 
fclose(fid);

%*****************************************************************
%   Stop: dirStrs may contain asterisk (*) to define multiple folders
%*****************************************************************



% ******************************************************************************
% *         Start: ReconstructionTraining
% *         Training network with 10ms bin size.
% *****************************************************************************

if resume1_overwrite0 == 0
    for ti = 1:length(trainingDataDirs)
        resultsPath = [resultsMainPath trainingDataDirs{ti} '\'];
        mkdir(resultsPath);
        
        delete(['trainingDataDir.txt']);
        fid = fopen(['trainingDataDir.txt'],'w');
        fprintf(fid,'%s\n',trainingDataDirs{ti});
        fclose(fid); 
    
        generateSeedFiles;
    end
end

for ti = 1:length(trainingDataDirs)
    % Prepare it
    fid = fopen([resultsMainPath 'TODO\' 'trainingDataDir' num2str(ti) '.txt'],'w');
    fprintf(fid,'%s\n',trainingDataDirs{ti});
    fclose(fid);
        
    resultsPath = [resultsMainPath trainingDataDirs{ti} '\'];
    mkdir(resultsPath);
    %delete([resultsPath '*.m']);
    %copyDependencies2Folder(mfilename(),resultsPath);
    
    delete([resultsPath 'TODO\*']);
    delete([resultsPath 'DONE\*']);
    delete([resultsPath 'Error\*']);
    delete([resultsPath 'temp_*']);  
    
    delete(['trainingDataDir.txt']);
    fid = fopen(['trainingDataDir.txt'],'w');
    fprintf(fid,'%s\n',trainingDataDirs{ti});
    fclose(fid);    
    
    st = systemDir(resultsPath,'Epoch','.mat', matlab1_octave0);
    
    if length(st)==0
        continue;
    end
    
    % Check if multiple epochs of the same runnr (delete lowest)
    epochInfo = [];
    for sti=1:length(st)
        
        currentFileBase = st(sti).name;
        inds = strfind(currentFileBase,'_');
        epochNr = str2num(currentFileBase(6:(inds(1)-1)));
        runnr = str2num(currentFileBase((inds(1)+6):(inds(2)-1)));
        postFix = currentFileBase((inds(1)+1):end);
        epochInfo = [epochInfo ; sti runnr epochNr];        
    end
    
    unRuns = unique(epochInfo(:,2));
    for ri=1:length(unRuns)
        inds = find(epochInfo(:,2)==unRuns(ri));
        [vs is] = max(epochInfo(inds,3));
        
        for ii=1:length(inds)
            sti = epochInfo(inds(ii),1);
            if ii~=is
                delete([resultsPath st(sti).name]);
            else            
                fid = fopen([resultsPath 'TODO\' st(sti).name],'w'); fclose(fid);
            end
        end
    end
end

% Only deleting working files
for ti=1:length(trainingDataDirs)
    resultsPath = [resultsMainPath trainingDataDirs{ti} '\'];
    workingPath = [resultsPath 'Working\'];
    delete([workingPath '*']);
end
    
delete([resultsMainPath 'Running\*']);
if 1 % For debugging put to 0 and to call ReconstructionTraining_distr.m manually
    finished = 1;
    [st, str] = matlabOctaveLs([resultsMainPath 'TODO\'], matlab1_octave0);
    if ~isempty(str)
        finished = 0;
    end
    
    while ~finished
        for i=1:ReconstructionTraining_ProcessCount    
            if matlab1_octave0 == 0
                system([matlabOctavePath ' --no-gui ' sublabPath 'ReconstructionTraining_distr.m']);
            else
                system([matlabOctavePath ' -nodisplay -nosplash -nodesktop -singleCompThread -r "run(''' sublabPath 'ReconstructionTraining_distr.m'');exit;"'])
            end
            
            pause(1); % Important for ensuring unique processes identities since they are defined by time. 
        end
        
        disp('Running training...');
        pause(10); % Waiting for all "Running" files to be written to disk.
        disp('If you want to pause put an empty textfile:');
        disp(parallelControlPath);
        disp('');
        
        while (~exist(parallelControlPath)) && (~finished)
            finished = 1;
            [st, str] = matlabOctaveLs([resultsMainPath 'Running\'], matlab1_octave0);
            if ~isempty(str)
                finished = 0;
            end
            pause(10);
            plotTrainingProgress(resultsMainPath,trainingDataDirs,matlab1_octave0);
            
        end
                    
        if ~finished    
            disp('Stopped');
            disp('Can now press Ctrl-C or remove the stop-file to resume processing');
            while exist(parallelControlPath) && (~finished)
                pause(10);
            end
        end
    end
elseif 0
    ReconstructionTraining_distr;
end

disp('Training done.');

%disp('');
%disp('Wait 10 seconds for the files to be written');
%pause(10);

% Plot reconstruction result
if 0 %for ti = 1:length(trainingDataDirs)
    resultsPath = [resultsMainPath trainingDataDirs{ti} '\'];
    
    fid = fopen([spikesMainPath trainingDataDirs{ti} '\TargetNeurons.bin'],'r');
    targetNeurons = fread(fid,'int');
    fclose(fid);
    
    try
        fid = fopen([spikesMainPath trainingDataDirs{ti} '\' 'IntracellularActivity.bin'],'r');
        analogTrace1ms = single(fread(fid,'float')');
        fclose(fid);
        analogTrace1ms = reshape(analogTrace1ms,[length(targetNeurons) length(analogTrace1ms)/length(targetNeurons)]);
    catch        
        analogTrace1ms = [];
    end
    
    figure(ti); clf;
    for ni=1:length(targetNeurons)
        st = dir([resultsPath 'Epoch*neuron' num2str(targetNeurons(ni)) '*.mat']);
        if matlab1_octave0
            load([resultsPath st(1).name],'g_opts');
        else
            % Opening this file using the normal Octave load function crashes Octave (probably because of the function handles in the file)
            g_opts = loadMat([resultsPath st(1).name],{'testBatchIndices','batchSize','RC_subReconstr','spikesRef','reconstrCorr','reconstrCorr2'});
        end   
        
        disp('Correlation index for each epoch for the test data set:');
        g_opts.reconstrCorr
        
        disp('Correlation index for each epoch for the validation data set:');
        g_opts.reconstrCorr2

        subplot(length(targetNeurons),1,ni);
        if ~isempty(analogTrace1ms)
            analogTrace10ms = filterGaussTime(analogTrace1ms(ni,:),10);
            analogTrace10ms = analogTrace10ms(1:10:end);        
            
            batchIndex = 1;
            testAnalog = analogTrace10ms(g_opts.batchSize*(g_opts.testBatchIndices(batchIndex)-1)+(1:g_opts.batchSize));
       
            plot((1:g_opts.batchSize)/100,scaleStd(scaleMean(testAnalog))); hold on;
        end
        plot((1:g_opts.batchSize)/100,scaleStd(scaleMean(g_opts.RC_subReconstr(1:g_opts.batchSize)))); hold on;
        plot((1:g_opts.batchSize)/100,4+g_opts.spikesRef(1:g_opts.batchSize),'k');
        xlabel('Time (s)');
        
        
    end
end


% ******************************************************************************
% *         Stop: ReconstructionTraining
% *         Training network with 10ms bin size.
% *****************************************************************************



% ******************************************************************************
% *         Start: ReconstructionComplete
% *         Runs the trained network with 1ms resolution for the entire data set.
% *****************************************************************************

for ti=1:length(trainingDataDirs)
    runName = trainingDataDirs{ti};
    
    % Have to check if already prepared or already done...
    if exist([fullReconstructionMainPath 'TODO\' 'FullReconstructionSessions' num2str(ti) '.txt'])
        continue;
    end
    
    if exist([fullReconstructionMainPath 'DONE\' runName '.txt'])
        continue;
    end
    
    % Prepare it
    fid = fopen([fullReconstructionMainPath 'TODO\' 'FullReconstructionSessions' num2str(ti) '.txt'],'w');
    fprintf(fid,'%s\n',runName);
    fclose(fid);
    
    resultsPath = [fullReconstructionMainPath runName '\'];
    
    delete([resultsPath '*.mat']);
    
    mkdir(resultsPath);
    resultsTODOPath = [resultsPath 'TODO\'];  
    mkdir(resultsTODOPath);
    delete([resultsPath 'TODO\*']);
    delete([resultsPath 'DONE\*']);    
    
    
    workingPath = [resultsPath 'Working\'];
    mkdir(workingPath);
    delete([workingPath '*']);
    errorPath = [resultsPath 'ErrorFiles\'];
    mkdir(errorPath);
    debugPath = [resultsPath 'DebugFiles\'];
    mkdir(debugPath);

    delete([resultsTODOPath '*']);

    st = dir([resultsMainPath runName '\Epoch*']);       
    for i=1:length(st)
        fid = fopen([resultsTODOPath st(i).name],'w'); fclose(fid);
    end
end
    
if 1 % 0 for debugging and then call ReconstructionComplete_distr.m manually
    finished = 1;
    [st, str] = matlabOctaveLs([fullReconstructionMainPath 'TODO\'], matlab1_octave0);
    if ~isempty(str)
        finished = 0;
    end
    delete([fullReconstructionMainPath 'Running\*']);
    
    while ~finished
        for thisJobNr=1:ReconstructionComplete_ProcessCount    
            if matlab1_octave0 == 0
                system([matlabOctavePath ' --no-gui ' sublabPath 'ReconstructionComplete_distr.m']);
            else
                system([matlabOctavePath ' -nodisplay -nosplash -nodesktop -singleCompThread -r "run(''' sublabPath 'ReconstructionComplete_distr.m'');exit;"'])
                %system([matlabOctavePath ' -nodisplay -nosplash -nodesktop -singleCompThread -r "ReconstructionComplete_distr ' num2str(thisJobNr) ');exit;"'])
            end
            pause(1); % Important for ensuring unique processes identities since they are defined by time. 
        end        
        
        disp('Running complete reconstruction...');
        pause(10); % Waiting for all "Running" files to be written to disk.
        disp('If you want to pause put an empty textfile:');
        disp(parallelControlPath);
        disp('');
        
        while (~exist(parallelControlPath)) && (~finished)
            finished = 1;
            [st, str] = matlabOctaveLs([fullReconstructionMainPath 'Running\'], matlab1_octave0);
            if ~isempty(str)
                finished = 0;
            end
            plotCompleteReconstrProgress;
            pause(5);
        end           
        
        if ~finished    
            disp('Stopped');
            disp('Can now press Ctrl-C or remove the stop-file to resume processing');
            while exist(parallelControlPath) && (~finished)
                pause(10);
            end
        end
    end
else
    ReconstructionComplete_distr;
end


disp('Complete reconstruction done.');

disp('');
disp('Wait 10 seconds for the files to be written');
pause(10);


% ******************************************************************************
% *         Stop: ReconstructionComplete
% *         Runs the trained network with 1ms resolution for the entire data set.
% *****************************************************************************



% **********************************************
% *         Start: myRate calculation
% ***********************************************

for ti=1:length(trainingDataDirs)
    sessionName = trainingDataDirs{ti};
        
    % Have to check if already prepared or already done...
    if exist([myRateMainPath 'TODO\' sessionName '.txt'])
        continue;
    end
    
    if exist([myRateMainPath 'DONE\' sessionName '.txt'])
        continue;
    end
    
    % Prepare it
    fid = fopen([myRateMainPath 'TODO\' sessionName '.txt'],'w'); fclose(fid);
end

if 1 % 0 for debugging and then call myRate_distr.m manually
    finished = 1;
    [st, str] = matlabOctaveLs([myRateMainPath 'TODO\'], matlab1_octave0);
    if ~isempty(str)
        finished = 0;
    end
    delete([myRateMainPath 'Running\*']);
    
    while ~finished
        for i=1:myRate_ProcessCount    
            if matlab1_octave0 == 0
                system([matlabOctavePath ' --no-gui ' sublabPath 'myRate_distr.m']);
            else
                system([matlabOctavePath ' -nodisplay -nosplash -nodesktop -singleCompThread -r "run(''' sublabPath 'myRate_distr.m'');exit;"'])
            end
            pause(1); % Important for ensuring unique processes identities since they are defined by time. 
        end
        
        disp('Running myRate calculation...');
        pause(10); % Waiting for all "Running" files to be written to disk.
        disp('If you want to pause put an empty textfile:');
        disp(parallelControlPath);
        disp('');
        
        while (~exist(parallelControlPath)) && (~finished)
            finished = 1;
            [st, str] = matlabOctaveLs([myRateMainPath 'TODO\'], matlab1_octave0);
            if ~isempty(str)
                finished = 0;
            end
            pause(5);
        end

        if ~finished            
            disp('Stopped');
            disp('Can now press Ctrl-C or remove the stop-file to resume processing');
            while exist(parallelControlPath) && (~finished)
                pause(10);
            end
        end

    end
else
    myRate_distr;
end      
% **********************************************
% *         Stop: myRate calculation
% ***********************************************
