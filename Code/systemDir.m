% David Eriksson, 2019

function st = systemDir(resultsDirPath,preFix,postFix, matlab1_octave0)

found = 0;
while found == 0  
    try
        %st = dir([resultsDirPath 'Epoch*']);
        [st, str] = matlabOctaveLs(resultsDirPath, matlab1_octave0);
        %[st, str]= system(['ls ' resultsDirPath]);
        found = 1;
    catch
        found = 0;
        disp('dir error');
        pause(1);
    end
end

startInds = strfind(str,preFix);
stopInds = strfind(str,postFix);
st = [];
for i=1:length(startInds)
    st(i).name = str(startInds(i):(stopInds(i)+3));
end