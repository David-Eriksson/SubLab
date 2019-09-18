function m = separateChannels(m,dist)

for i=1:size(m,1)
    m(i,:) = m(i,:) + dist*(i-1);
end