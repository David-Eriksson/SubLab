% David Eriksson, 2019

function endInd = getIndNewLineChar(str,ind)
  
while str(ind) ~= char(13)
    ind = ind + 1;
end

endInd = ind;

