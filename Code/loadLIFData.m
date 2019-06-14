% David Eriksson, 2019

function [N,spk,Vlast1s,SynInputs, SynCurrents, conditionInfo] = loadLIFData(filename);

fid = fopen(filename,'r');
N = fread(fid,1,'int32');
len = fread(fid,1,'int32');
spk1 = fread(fid,len,'int32')';
spk2 = fread(fid,len,'int32')';
spk = [spk1 ; spk2];

CH = fread(fid,1,'int32');
T = fread(fid,1,'int32');
Vlast1s = zeros(CH,T);
Vlast1s(:) = fread(fid,CH*T,'float');

SynInputs = zeros(CH,T);
SynInputs(:) = fread(fid,CH*T,'float');

SynCurrents = zeros(CH,T);
SynCurrents(:) = fread(fid,CH*T,'float');

conditionInfo = zeros(1,T);
conditionInfo(:) = fread(fid,T,'float');

fclose(fid);


  