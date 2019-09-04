spikePath = '..\Data\PlainSpikeData_c42.bin';

fid = fopen(spikePath,'r');
spikes = fread(fid,'double');
fclose(fid);
infoStr = ['Number of units: ' num2str(length(unique(spikes(1:2:end)))) char(10) 'Recording duration (seconds): ' num2str(max(spikes(2:2:end))) char(10) 'Average firing rate (Hz):  ' num2str(length(spikes)/2/length(unique(spikes(1:2:end)))/max(spikes(2:2:end)))];
disp(infoStr);

un = unique(spikes(1:2:end)); % Extract unique unit identities such we can select one for reconstruction

spikeData = reshape(spikes,[2 length(spikes)/2]);
targetNeuron = un(1);
maxNumberOfEpochs = 5;
%SubLab_Function;
[reconstruction_full, spikes_full] = SubLab_Function(spikeData, targetNeuron, maxNumberOfEpochs);

reconstruction_full = reconstruction_full - mean(reconstruction_full);
reconstruction_full = reconstruction_full / std(reconstruction_full);
timeInds = (1:10000);
figure(1); clf; plot([reconstruction_full(timeInds) ; spikes_full(timeInds)]');


intracellularPath = '..\Data\IntracellularActivity.bin';

fid = fopen(intracellularPath,'r');
IntracellularActivity = fread(fid,'single');
fclose(fid);
IntracellularActivity = IntracellularActivity - mean(IntracellularActivity);
IntracellularActivity = IntracellularActivity / std(IntracellularActivity);

hold on; plot(IntracellularActivity(timeInds));
