% David Eriksson, 2019

function endInd = getCharInd(str,ch,ind)
  
while str(ind) ~= ch
    ind = ind + 1;
end

endInd = ind;

