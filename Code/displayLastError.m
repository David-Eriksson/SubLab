% David Eriksson, 2019

function displayLastError()
    l = lasterror;
    disp(l.message);
    for si=1:length(l.stack)
        disp(l.stack(si).file);
        disp(['Line ' num2str(l.stack(si).line) ' in function ' l.stack(si).name]);
    end  
end
