function res = filterTime(data,kernel,zeroIndex,mask)

if nargin == 3
	mask = data*0+1;
end

data = data.*mask;

inc = sum(cumsum(kernel)==0);

kernel = kernel(end:(-1):1);

dec = sum(cumsum(kernel)==0);
kernel = kernel((dec+1):(end-inc));
myeps = eps;
zeroIndex = zeroIndex - inc;

s = length(data)+length(kernel)-1;
a = 2^floor(log2(s)+0.9999999)-s;
K = length(kernel);
kernel = [kernel ((1:a)*0+myeps)];

Data = fft([data myeps+zeros(1,length(kernel)-1)]);
Mask = fft([mask myeps+zeros(1,length(kernel)-1)]);
Kernel = fft([kernel myeps+zeros(1,length(data)-1)]);

x = real(ifft(Data.*Kernel));
y = real(ifft(Mask.*Kernel));

inds = find(y<(max(y)*0.000001));

res = x./y;

%res(inds) = NaN;

%figure(1); clf; plot(x);
%figure(2); clf; plot(y);
%figure(3); clf; plot(res); pause
%res = conv(data,kernel)./conv(mask,kernel);

res = res((K-zeroIndex+1):(K-zeroIndex+length(data)));
