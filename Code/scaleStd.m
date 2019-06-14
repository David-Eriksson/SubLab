function y = scaleStd(y)
  
for i=1:size(y,1)
    y(i,:) = y(i,:)/std(y(i,:),[],2);
end
