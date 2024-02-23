function x = cmorWave(x, f0, t0)
% cmorWave  Complex morlet mother wavelet, L2 norm
% x = cmorWave(t, f0) or x = cmorWave(t, f0, t0)
% t - real vector, dimensionless
% f0 - central frequency, dimensionless
% t0 - bandwidth, dimensionless, default 1
% x - wavelet basis, dimensionless
% Xin Wang, CNL-S, Salk Institute, 2011
if nargin < 3
    t0 = 1;
end
sigma = 2*pi*f0;
c_sigma = 1/sqrt(1+exp(-sigma^2)-2*exp(-3/4*sigma^2));
k_sigma = exp(-1/2*sigma^2);
x = c_sigma/sqrt(sqrt(pi))/t0*exp(-1/2*x.^2/t0^2).*(exp(1i*sigma.*x)-k_sigma);