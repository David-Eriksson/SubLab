close all;
dns = [];
st = dir([fullReconstructionMainPath '\DONE\*.txt']);
if length(st) == 0
    return;
end
for sti=1:length(st)
    dns = [dns st(sti).datenum];
end
[vs is] = max(dns);

sessionName = st(is).name(1:(end-4));
fid = fopen([spikesMainPath sessionName '\TargetNeurons.bin'],'r');
targetNeurons = fread(fid,'int');
fclose(fid);

try
    fid = fopen([spikesMainPath sessionName '\' 'IntracellularActivity.bin'],'r');
    analogTrace1ms = single(fread(fid,'float')');
    fclose(fid);
    analogTrace1ms = reshape(analogTrace1ms,[length(targetNeurons) length(analogTrace1ms)/length(targetNeurons)]);
catch        
    analogTrace1ms = [];
end


st = dir([fullReconstructionMainPath sessionName '\' '*Epoch*.mat']);

figure(1); clf;
mrecons = [];
avgCorrs = [];
for ni=1:length(st)
    readFileId = fopen([fullReconstructionMainPath sessionName '\' st(ni).name],'r');
    len = fread(readFileId,1,'int32');
    reconstrCorrs = fread(readFileId,len,'single');
    reconstructions = [];
    reconstrCorrPerBatch = [];
    spikes = [];
    %while ~feof(readFileId)
    for bi=1:2 % Just two for displyaing
        %fprintf('.');

        try
            dataType = fread(readFileId,1,'int32');
            batchSize = fread(readFileId,1,'int32');

            reconstrCorr = fread(readFileId,1,'single');
            reconstrCorrPerBatch = [reconstrCorrPerBatch reconstrCorr];
            spike = fread(readFileId,batchSize,'uint8')';
            spikes = [spikes spike];
            reconstruction = fread(readFileId,batchSize,'single')';
            reconstructions = [reconstructions reconstruction];
            pause(0.01);
        end
    end
    fclose(readFileId);
    %fprintf('\n');

    %disp('Cross validated correlation index for each batch:');
    %reconstrCorrPerBatch

    if isempty(reconstructions)
        continue;
    end

    recSnippet = reconstructions(1:50000);
    spkSnippet = spikes(1:50000);

    legends = {};

    if (length(st) == 1)
        subplot(length(targetNeurons),1,ni);
        if ~isempty(analogTrace1ms)
            legends{length(legends)+1} = 'Ground truth';
            analogSnippet = analogTrace1ms(ni,1:50000);
            plot(scaleStd(scaleMean(analogSnippet))); hold on;
        end

        legends{length(legends)+1} = 'Reconstruction';
        plot(scaleStd(scaleMean(recSnippet))+3*spkSnippet); hold on;
        hold on;            
        xlabel('Time (s)');
        legend(legends);
    else
        nr = scaleStd(scaleMean(recSnippet));                        
        mrecons = [mrecons ; nr+spkSnippet*3];
        avgCorrs = [avgCorrs mean(reconstrCorrPerBatch)];

    end
end

if length(avgCorrs) > 1
    [vs is] = sort(avgCorrs);
    inds = round(1:(length(avgCorrs)-1)/5:length(avgCorrs));

    plot(separateChannels(mrecons(inds,:),7)');
    title(sessionName);
    pause(0.001);
end