function [y, f, t, FStats]=mtcsglong(varargin);
%function [yo, fo, to, phi]=mtcsglong(x,nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);
% Multitaper Time-Frequency PowerSpectrum (spectrogram)
% for long files - splits data into blockes to save memory
% function A=mtcsg(x,nFFT,Fs,WinLength,nOverlap,NW,nTapers)
% x : input time series
% nFFT = number of points of FFT to calculate (default 1024)
% Fs = sampling frequency (default 2)
% WinLength = length of moving window (default is nFFT)
% nOverlap = overlap between successive windows (default is WinLength/2)
% NW = time bandwidth parameter (e.g. 3 or 4), default 3
% nTapers = number of data tapers kept, default 2*NW -1
%
% output yo is yo(f, t)
%
% If x is a multicolumn matrix, each column will be treated as a time
% series and you'll get a matrix of cross-spectra out yo(f, t, Ch1)
% NB they are cross-spectra not coherences. If you want coherences use
% mtcohere

% Original code by Partha Mitra - modified by Ken Harris 
% and adopted for long files and phase by Anton Sirota
% Also containing elements from specgram.m

% default arguments and that
%[x,nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,nChannels,...
%        nSamples,nFFTChunks,winstep,select,nFreqBins,f,t,FreqRange] = mtparam(varargin);

[x,nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,nChannels,...
        nSamples,nFFTChunks,winstep,select,nFreqBins,f,t] = mtparam(varargin);
global VERBOSE;
if VERBOSE
    h = waitbar(0,'Computing spectrograms  ..');
end

for i=1:nChannels
    if VERBOSE
        if i==1 tic; end
        if i==2 
            dur = toc; 
            durs = dur*(nChannels-1);
            durm = durs/60;
            fprintf('That will take ~ %f seconds (%f min)\n',durs,durm); 
            
        end
        waitbar(i/nChannels,h);
    end
    if (nargout>3)
        [ytmp, f, t, phi, ftmp] = ...
            mtchglong(x(:,i),nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers);
            %mtchglong(x(:,i),nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);
        y(:,:,i)=ytmp;
        FStats(:,:,i)=ftmp;
    else
         [ytmp, f, t] = ...
            mtchglong(x(:,i),nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers);
            %mtchglong(x(:,i),nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);
        y(:,:,i)=ytmp;
    end     
    
end
if VERBOSE
    close(h);
end

if nargout == 0
    % take abs, and use image to display results
    newplot;
    for Ch=1:nChannels, 
        subplot(nChannels, 1, Ch);
        imagesc(t,f,20*log10(abs(sq(y(:,:,Ch))')+eps));axis xy; colormap(jet)
    end; 
    xlabel('Time')
    ylabel('Frequency')
end
