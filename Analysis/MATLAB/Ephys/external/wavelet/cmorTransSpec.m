function c = cmorTransSpec(s, fs, f, f0, gamma)
% cmorTransSpec  Spectrum using continuous complex morlet transform
% c = cmorTransSpec(s, fs, f) or c = cmorTransSpec(s, fs, f, f0, gamma)
% s - signal, vector, in generic unit [Sig] ([Sig] can be V, mV, mA, ...)
% fs - sampling frequency, in Hz
% f - frequency vector, in Hz
% f0 - central frequency, dimensionless, default 1
% gamma - scaling exponent, dimensionless, default -1/2
% c - complex transform coefficient, in unit [Sig]*s^(1+gamma)
% Xin Wang, CNL-S, Salk Institute, 2011
sigmaWin = 4;
if nargin < 4
    f0 = 1;
    gamma = -1/2;
end
% b = (1:length(s))/fs;
a = f0./f;
c = zeros(length(f), length(s));
for i = 1 : length(f)
    n = ceil(a(i)*sigmaWin*fs);
    t = (-n:n)/fs;
    ker = cmorWave(t/a(i), f0)*(a(i))^gamma;
    temp = conv(ker, s)/fs;
    c(i, :) = temp(n+1:end-n);
end