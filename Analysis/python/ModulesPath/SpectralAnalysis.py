#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 21 09:39:25 2019

@author: bapung
"""

import numpy as np
import scipy.signal as sg
import scipy.fftpack as ft
import scipy.ndimage.filters as smth
import os
from datetime import datetime


def lfpSpectrogram(basePath, sRate, nChans, loadfrom=1, savefile=1):

    subname = os.path.basename(os.path.normpath(basePath))

    if loadfrom == 1:
        fileName = basePath + subname + "_BestRippleChans.npy"
        lfpCA1 = np.load(fileName, allow_pickle=True)
        eegChan = lfpCA1.item()
        eegChan = eegChan["BestChan"]
        # eegChan = np.array(eegChan, dtype=np.float)  # convert data to float

    window_spect = 10 * sRate
    window_overlap = 2 * sRate
    numfft = window_spect
    # sos = sg.butter(3, 625 / 1250, btype="lowpass", fs=sRate, output="sos")
    # yf = sg.sosfiltfilt(sos, eegChan)
    f, t, Pxx = sg.spectrogram(
        eegChan,
        fs=sRate,
        nperseg=window_spect,
        noverlap=window_overlap,
        nfft=numfft,
        scaling="spectrum",
    )

    # Smoothing the spectrogram if needed
    # yf = ft.fft(yf) / len(eegChan)
    # xf = np.linspace(0.0, SampFreq / 2, len(eegChan) // 2)
    # y1 = 2.0 / (len(xf)) * np.abs(yf[:len(eegChan) // 2])
    # y1 = smth.gaussian_filter(y1, 8)
    now = datetime.now()
    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

    spect = dict()
    spect["timestamps"] = t
    spect["Pxx"] = Pxx
    spect["freq"] = f
    spect["Params"] = {"windowSize": window_spect, "overlap": window_overlap}
    spect["Info"] = {"Date": dt_string, "DetectorName": "lfpDetect/swr"}

    if savefile == 1:
        np.save(basePath + subname + "_spectogram.npy", spect)

    return Pxx, f, t, sample_data


def lfpSpectMaze(sub_name, nREMPeriod, RecInfo, channel):

    SampFreq = RecInfo["samplingFrequency"]
    frames = RecInfo["behavFrames"]
    behav = RecInfo["behav"]
    nChans = RecInfo["numChannels"]
    #    ReqChan = RecInfo['SpectralChannel']
    ReqChan = channel
    duration = 5  # chunk of lfp in seconds

    offsetP = ((nREMPeriod - behav[1, 0]) // 1e6) * SampFreq + int(
        np.diff(frames[0, :])
    )
    b1 = np.memmap(
        "/data/EEGData/" + sub_name + ".eeg",
        dtype="int16",
        mode="r",
        offset=int(offsetP) * nChans * 2 + 1 * (ReqChan - 1) * 2,
        shape=(1, nChans * SampFreq * duration),
    )
    eegChan = b1[0, ::nChans]
    sos = sg.butter(3, 100, btype="low", fs=SampFreq, output="sos")
    yf = sg.sosfilt(sos, eegChan)
    yf = ft.fft(yf) / len(eegChan)
    xf = np.linspace(0.0, SampFreq / 2, len(eegChan) // 2)
    y1 = 2.0 / (len(xf)) * np.abs(yf[: len(eegChan) // 2])
    y1 = smth.gaussian_filter(y1, 8)

    return y1, xf


def bestThetaChannel(basePath, sampleRate, nChans, badChannels, saveThetaChan=0):
    """
    fileName: name of the .eeg file
    sampleRate: sampling frequency of eeg;

    """

    duration = 3600  # chunk of lfp in seconds
    nyq = 0.5 * sampleRate
    lowTheta = 5  # in Hz
    highTheta = 10  # in Hz

    for file in os.listdir(basePath):
        if file.endswith(".eeg"):
            print(file)
            subname = file[:-4]
            fileName = os.path.join(basePath, file)

    lfpCA1 = np.memmap(
        fileName, dtype="int16", mode="r", shape=(sampleRate * duration, nChans)
    )

    b, a = sg.butter(3, [lowTheta / nyq, highTheta / nyq], btype="bandpass")
    yf = sg.filtfilt(b, a, lfpCA1, axis=0)

    avgTheta = np.mean(np.square(yf), axis=0)
    idx = np.argsort(avgTheta)

    bestChannels = np.setdiff1d(idx, badChannels, assume_unique=True)[::-1]

    # selecting first three channels

    bestChannels = bestChannels[0:5]

    if saveThetaChan == 1:
        reqChan = bestChannels[0]
        b1 = np.memmap(fileName, dtype="int16", mode="r")
        ThetaExtract = b1[reqChan::nChans]
        # ThetaExtract2 = b1[reqChan - 16 :: nChans]

        np.save(basePath + subname + "_BestThetaChan.npy", ThetaExtract)
        # np.save(basePath + subname + "_BestThetaChan.npy", ThetaExtract2)

    return bestChannels


def bestRippleChannel(basePath, sampleRate, nChans, badChannels, saveRippleChan=1):
    """
    fileName: name of the .eeg file
    sampleRate: sampling frequency of eeg;

    """

    duration = 60 * 60  # chunk of lfp in seconds
    nyq = 0.5 * sampleRate  # Nyquist frequency
    lowRipple = 150  # ripple lower end frequency in Hz
    highRipple = 250  # ripple higher end frequency in Hz
    for file in os.listdir(basePath):
        if file.endswith(".eeg"):
            subname = file[:-4]
            fileName = os.path.join(basePath, file)

    lfpCA1 = np.memmap(
        fileName, dtype="int16", mode="r", shape=(sampleRate * duration, nChans)
    )

    b, a = sg.butter(3, [lowRipple / nyq, highRipple / nyq], btype="bandpass")
    delta = sg.filtfilt(b, a, lfpCA1, axis=0)

    # Hilbert transform for calculating signal's envelope
    analytic_signal = sg.hilbert(delta)
    amplitude_envelope = np.abs(analytic_signal)

    avgRipple = np.mean(amplitude_envelope, axis=0)
    idx = np.argsort(avgRipple)
    bestChannels = np.setdiff1d(idx, badChannels, assume_unique=True)[::-1]

    if saveRippleChan == 1:
        bestChan = bestChannels[0]
        best2ndChan = bestChannels[1]

        b1 = np.memmap(fileName, dtype="int16", mode="r")
        RipplelfpExtract = b1[bestChan::nChans]
        Ripple2ndlfpExtract = b1[best2ndChan::nChans]

        Ripplelfps = {"BestChan": RipplelfpExtract, "Best2ndChan": Ripple2ndlfpExtract}

        np.save(basePath + subname + "_BestRippleChans.npy", Ripplelfps)
        # np.save(basePath + subname + "_BestRippleChan.npy", RippleExtract2)

    # selecting first three channels

    bestChannels = bestChannels[0:5]

    return bestChannels


class SpectralRatio(object):
    def __init__(self, basePath):
        self.name = 4

    def ThetaDeltaRatio(self):
        f, t, sxx = sg.spectrogram(
            thetaData, fs=sampleRate, nperseg=10 * sampleRate, noverlap=5 * sampleRate
        )

        theta_ind = np.where((f > 5) & (f < 10))[0]
        delta_ind = np.where(((f > 1) & (f < 4)) | ((f > 12) & (f < 15)))[0]
        theta_sxx = np.mean(sxx[theta_ind, :], axis=0)
        delta_sxx = np.mean(sxx[delta_ind, :], axis=0)

        self.theta_delta_ratio = stats.zscore(theta_sxx / delta_sxx)
