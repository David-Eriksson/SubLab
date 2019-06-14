% David Eriksson, 2019

function [st, str] = matlabOctaveLs(todoPath,matlab1_octave0)

if matlab1_octave0 == 0
    % Octave
    [st, str]= system(['ls ' todoPath]);
   
else
    % matlab
    st= ls([todoPath]);
    str = [];
    for fi=1:size(st,1)
        if strcmp(st(fi,1),'.') == 1
            continue;
        end
        if strcmp(st(fi,1:2),'..') == 1
            continue;
        end
        str = [str deblank(st(fi,:)) char(10)];
    end
    st = 1;
end