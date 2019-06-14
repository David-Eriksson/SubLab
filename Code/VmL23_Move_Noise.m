% David Eriksson, 2019

function y = VmL23_Move_Noise(CH,T)
  
data = importdata('VmL23_Move_Spektrum.txt');
[vs is] = sort(data(:,1));
data = data(is,:);

%figure(1); clf; plot(data(:,1),data(:,2));
  
if T <= 10
    y = randn(CH,T);
    return;
end

odd = 0;
if mod(T,2) == 1  
    odd = 1;
    T = T + 1;
end

N2 = floor(T/2);
r = randn(CH,T);
f = fft(r')';
fs = [(1:N2)-1 (N2:(-1):1)-1]*1000/T;
yp = interp1([-0.01 data(:,1)'],[0 data(:,2)'],fs,'nearest');

% extrapolating with k/f;
k = data(end,1)*data(end,2);
oneOverF = k./fs;
inds = find(isnan(yp));
yp(inds) = oneOverF(inds);

f = f.*repmat(yp,CH,1);
y = real(ifft(f')');
y = y/std(y(:));

if odd == 1
    y = y(:,1:(end-1));
end



if 0
    figure(1); clf;
    %subplot(2,1,1);
    plot(y');
    %subplot(2,1,2);
    %plot(abs(fft(y)));
end
