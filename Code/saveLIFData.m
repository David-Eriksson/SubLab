% David Eriksson, 2019

function saveLIFData(filename,spk,Vlast1s,SynInputs, SynCurrents, conditionInfo)

fid = fopen(filename,'w');
  
spikes = [];
for chi=1:length(spk)
    spikes = [spikes [int32(spk{chi}*1000) ; spk{chi}*0+chi]];
end

fwrite(fid,length(spk),'int32');
fwrite(fid,size(spikes,2),'int32');
fwrite(fid,spikes(1,:),'int32');
fwrite(fid,spikes(2,:),'int32');

fwrite(fid,size(Vlast1s,1),'int32');
fwrite(fid,size(Vlast1s,2),'int32');

fwrite(fid,Vlast1s(:),'float');
fwrite(fid,SynInputs(:),'float');
fwrite(fid,SynCurrents(:),'float');
fwrite(fid,conditionInfo(:),'float');

fclose(fid);