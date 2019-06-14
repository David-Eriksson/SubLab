% David Eriksson, 2019

function data = loadMat(filename,varStrs)

fid = fopen(filename,'r');
%str = fscanf(fid,'%s');
str = char(fread(fid,Inf,'char'));
fclose(fid);
str = str';

data = [];

for si=1:length(varStrs)
    %si
    ind = strfind(str,['# name: ' varStrs{si} char(13)]);
    ind = ind(end);
    endInd = getIndNewLineChar(str,ind);
    %str((ind+8):endInd)
    
    formatstr = str(ind+(1:80));
    
    rowInd = strfind(formatstr,['# rows:']);
    if ~isempty(rowInd)
        rowEnd = getCharInd(formatstr, char(13),rowInd);
        %str2num(formatstr((rowInd+8):rowEnd))
        
        colInd = strfind(formatstr,['# columns:']);
        colEnd = getCharInd(formatstr, char(13),colInd);
        %str2num(formatstr((colInd+11):colEnd))
        
        dataStart = (ind+colEnd)+2;
        dataStop = getCharInd(str, char(13),dataStart);
        
        
        data = setfield(data,varStrs{si},str2num(str(dataStart:dataStop)));
        continue;
     end
     
      rowInd = strfind(formatstr,['# base, limit, increment']);
      if ~isempty(rowInd)
          rowEnd = getCharInd(formatstr, char(13),rowInd);
          
          
          dataStart = (ind+rowEnd)+2;
          dataStop = getCharInd(str, char(13),dataStart);
          
          rangeVar = str2num(str(dataStart:dataStop));
          vec = rangeVar(1):rangeVar(3):rangeVar(2);
          data = setfield(data,varStrs{si},vec);
          continue;
       end
       
       rowInd = strfind(formatstr,['# type: scalar']);
      if ~isempty(rowInd)
          rowEnd = getCharInd(formatstr, char(13),rowInd);
          
          
          dataStart = (ind+rowEnd)+2;
          dataStop = getCharInd(str, char(13),dataStart);
          
          rangeVar = str2num(str(dataStart:dataStop));
          data = setfield(data,varStrs{si},rangeVar);
          continue;
       end
  
end

