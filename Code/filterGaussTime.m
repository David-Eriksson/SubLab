function res = filterGaussTime(data,deviation,mask)

res = zeros(size(data));
t = -length(data):length(data);
%t = (-3*deviation):(3*deviation);
filt = exp(-(t/deviation).^2);


for i=1:size(data,1)
     	if mod(i,100)==0
		%i/size(data,1)
    	end
    
	if nargin == 2
		res(i,:) = filterTime(data(i,:),filt,length(data)+1);
	else
		res(i,:) = filterTime(data(i,:),filt,length(data)+1,mask);
	end
end
