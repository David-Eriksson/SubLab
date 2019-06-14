function y = scaleMean(y)
  
for i=1:size(y,1)
    y(i,:) = y(i,:) - mean(y(i,:),2);
end
