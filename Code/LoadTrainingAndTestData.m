% David Eriksson, 2019

fid = fopen(['spikesMainPath.txt'],'r');
spikesMainPath = fscanf(fid,'%s\n');
fclose(fid);

disp('loading spiking data...');
fid = fopen([spikesMainPath trainingDataDir '\' trainingDataDir '.bin'],'r');
spikes = fread(fid,'double');
fclose(fid);
spikes = reshape(spikes,[2 length(spikes)/2]);
spikes(2,:) = round(spikes(2,:)*1000/g_opts.loadTemporalResolution);
g_trainingAndTestData{1} = spikes';
g_referenceData = [];
disp('done.');