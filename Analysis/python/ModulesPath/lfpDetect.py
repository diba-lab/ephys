import numpy as np
import scipy.signal as sg
import scipy.fftpack as ft
import scipy.ndimage as smth
import scipy.stats as stat
import numpy.random as rnd
import os
import matplotlib.pyplot as plt
from datetime import datetime


def swr(lfp, sRate, PlotRippleStat=0):

    # setting thresholds
    SampFreq = sRate
    nyq = 0.5 * SampFreq
    lowFreq = 150
    highFreq = 240
    lowthresholdFactor = 1
    highThresholdFactor = 2
    # TODO chnage raw amplitude threshold to something statistical
    highRawSigThresholdFactor = 15000
    minRippleDuration = 20  # in milliseconds
    maxRippleDuration = 800  # in milliseconds
    maxRipplePower = 60  # in normalized power units

    signal = lfp
    signal = np.array(signal, dtype=np.float)  # convert data to float
    zscoreRawSig = stat.zscore(signal)

    b, a = sg.butter(3, [lowFreq / nyq, highFreq / nyq], btype="bandpass")
    yf = sg.filtfilt(b, a, signal)

    squared_signal = np.square(yf)
    normsquaredsignal = stat.zscore(squared_signal)

    windowLength = SampFreq / SampFreq * 11
    window = np.ones((int(windowLength),)) / windowLength

    smoothSignal = sg.filtfilt(window, 1, squared_signal, axis=0)
    zscoreSignal = stat.zscore(smoothSignal)

    hist_zscoresignal, edges_zscoresignal = np.histogram(
        zscoreSignal, bins=np.linspace(0, 6, 100)
    )

    ThreshSignal = np.diff(np.where(zscoreSignal > lowthresholdFactor, 1, 0))
    start_ripple = np.argwhere(ThreshSignal == 1)
    stop_ripple = np.argwhere(ThreshSignal == -1)

    # print(start_ripple.shape, stop_ripple.shape)
    firstPass = np.concatenate((start_ripple, stop_ripple), axis=1)

    # TODO delete half ripples in begining or end

    # ===== merging close ripples
    minInterRippleSamples = 30 / 1000 * SampFreq
    secondPass = []
    ripple = firstPass[0]
    for i in range(1, len(firstPass)):
        if firstPass[i, 0] - ripple[1] < minInterRippleSamples:
            # Merging ripples
            ripple = [ripple[0], firstPass[i, 1]]
        else:
            secondPass.append(ripple)
            ripple = firstPass[i]

    secondPass.append(ripple)
    secondPass = np.asarray(secondPass)

    # =======delete ripples with less than threshold power
    thirdPass = []
    peakNormalizedPower = []

    for i in range(0, len(secondPass)):
        maxValue = max(zscoreSignal[secondPass[i, 0] : secondPass[i, 1]])
        if maxValue > highThresholdFactor:
            thirdPass.append(secondPass[i])
            peakNormalizedPower.append(maxValue)

    thirdPass = np.asarray(thirdPass)

    ripple_duration = np.diff(thirdPass, axis=1) / SampFreq * 1000

    # delete very short ripples
    shortRipples = np.where(ripple_duration < minRippleDuration)[0]
    thirdPass = np.delete(thirdPass, shortRipples, 0)
    peakNormalizedPower = np.delete(peakNormalizedPower, shortRipples)

    # delete ripples with unrealistic high power
    artifactRipples = np.where(peakNormalizedPower > maxRipplePower)[0]
    fourthPass = np.delete(thirdPass, artifactRipples, 0)
    peakNormalizedPower = np.delete(peakNormalizedPower, artifactRipples)

    # delete very long ripples
    veryLongRipples = np.where(ripple_duration > maxRippleDuration)[0]
    fifthPass = np.delete(fourthPass, veryLongRipples, 0)
    peakNormalizedPower = np.delete(peakNormalizedPower, veryLongRipples)

    # delete ripples which have unusually high amp in raw signal (takes care of disconnection)
    highRawInd = []
    for i in range(0, len(fifthPass)):
        maxValue = max(signal[fifthPass[i, 0] : fifthPass[i, 1]])
        if maxValue > highRawSigThresholdFactor:
            highRawInd.append(i)

    sixthPass = np.delete(fifthPass, highRawInd, 0)
    peakNormalizedPower = np.delete(peakNormalizedPower, highRawInd)

    print(f"{len(sixthPass.shape)} ripples detected")
    # TODO delete sharp ripple like artifacts
    # Maybe unrelistic high power has taken care of this but check to confirm

    # selecting some example ripples
    idx = rnd.randint(0, sixthPass.shape[0], 5, dtype="int")
    example_ripples = []
    example_ripples_duration = []  # in frames
    for i in range(5):
        example_ripples.append(
            signal[sixthPass[idx[i], 0] - 125 : sixthPass[idx[i], 1] + 125]
        )
        example_ripples_duration.append(sixthPass[idx[i], 1] - sixthPass[idx[i], 0])

    # selecting high power ripples
    highpoweredRipples = np.argsort(peakNormalizedPower)
    for i in range(5):
        example_ripples.append(
            signal[sixthPass[idx[i], 0] - 125 : sixthPass[idx[i], 1] + 125]
        )
        example_ripples_duration.append(sixthPass[idx[i], 1] - sixthPass[idx[i], 0])

    # ====== Plotting some results===============
    if PlotRippleStat == 1:
        flat_ripples = [item for sublist in example_ripples for item in sublist]
        ripple_duration_hist, duration_edges = np.histogram(
            example_ripples_duration, bins=20
        )

        numRow, numCol = 3, 2
        plt.figure()
        plt.subplot(numRow, 1, 1)
        plt.plot(flat_ripples)

        plt.subplot(numRow, 2, 3)
        # plt.plot(duration_edges, ripple_duration_hist)
        sns.distplot(ripple_duration, bins=None)
        plt.xlabel("Ripple duration (ms)")
        plt.ylabel("Counts")
        plt.title("Ripple duration distribution")

        plt.subplot(numRow, 2, 4)
        # sns.set_style("darkgrid")
        sns.distplot(peakNormalizedPower, bins=np.arange(1, 100))
        plt.xlabel("Normalized Power")
        plt.ylabel("Counts")
        plt.title("Ripple Power Distribution")

    now = datetime.now()
    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

    ripples = dict()
    ripples["timestamps"] = sixthPass / SampFreq
    ripples["peakPower"] = peakNormalizedPower
    ripples["DetectionParams"] = {
        "lowThres": lowthresholdFactor,
        "highThresh": highThresholdFactor,
        "ArtifactThresh": maxRipplePower,
        "lowFreq": lowFreq,
        "highFreq": highFreq,
        "samplingRate": SampFreq,
        "minDuration": minRippleDuration,
        "maxDuration": maxRippleDuration,
    }
    ripples["Info"] = {"Date": dt_string, "DetectorName": "lfpDetect/swr"}

    return ripples


def deltawave(sub_name, nREMPeriod, RecInfo):

    SampFreq = RecInfo["samplingFrequency"]
    frames = RecInfo["behavFrames"]
    behav = RecInfo["behav"]
    nChans = RecInfo["numChannels"]
    ReqChan = RecInfo["SpectralChannel"]

    offsetP = (
        ((nREMPeriod - behav[2, 0]) // 1e6) * SampFreq
        + int(np.diff(frames[0, :]))
        + int(np.diff(frames[1, :]))
    )
    b1 = np.memmap(
        "/data/EEGData/" + sub_name + ".eeg",
        dtype="int16",
        mode="r",
        offset=int(offsetP) * nChans * 2 + 1 * (ReqChan - 1) * 2,
        shape=(1, nChans * SampFreq * 5),
    )
    eegnrem1 = b1[0, ::nChans]
    sos = sg.butter(3, 100, btype="low", fs=SampFreq, output="sos")
    yf = sg.sosfilt(sos, eegnrem1)
    yf = ft.fft(yf) / len(eegnrem1)
    xf = np.linspace(0.0, SampFreq / 2, len(eegnrem1) // 2)
    y1 = 2.0 / (len(xf)) * np.abs(yf[: len(eegnrem1) // 2])
    y1 = smth.gaussian_filter(y1, 8)

    return y1, xf


def spindle(sub_name, nREMPeriod, RecInfo):

    SampFreq = RecInfo["samplingFrequency"]
    frames = RecInfo["behavFrames"]
    behav = RecInfo["behav"]
    nChans = RecInfo["numChannels"]
    ReqChan = RecInfo["SpectralChannel"]

    offsetP = (
        ((nREMPeriod - behav[2, 0]) // 1e6) * SampFreq
        + int(np.diff(frames[0, :]))
        + int(np.diff(frames[1, :]))
    )
    b1 = np.memmap(
        "/data/EEGData/" + sub_name + ".eeg",
        dtype="int16",
        mode="r",
        offset=int(offsetP) * nChans * 2 + 1 * (ReqChan - 1) * 2,
        shape=(1, nChans * SampFreq * 5),
    )
    eegnrem1 = b1[0, ::nChans]
    sos = sg.butter(3, 100, btype="low", fs=SampFreq, output="sos")
    yf = sg.sosfilt(sos, eegnrem1)
    yf = ft.fft(yf) / len(eegnrem1)
    xf = np.linspace(0.0, SampFreq / 2, len(eegnrem1) // 2)
    y1 = 2.0 / (len(xf)) * np.abs(yf[: len(eegnrem1) // 2])
    y1 = smth.gaussian_filter(y1, 8)

    return y1, xf


def sharpWaveOnly(sub_name, nREMPeriod, RecInfo):

    SampFreq = RecInfo["samplingFrequency"]
    frames = RecInfo["behavFrames"]
    behav = RecInfo["behav"]
    nChans = RecInfo["numChannels"]
    ReqChan = RecInfo["SpectralChannel"]

    offsetP = (
        ((nREMPeriod - behav[2, 0]) // 1e6) * SampFreq
        + int(np.diff(frames[0, :]))
        + int(np.diff(frames[1, :]))
    )
    b1 = np.memmap(
        "/data/EEGData/" + sub_name + ".eeg",
        dtype="int16",
        mode="r",
        offset=int(offsetP) * nChans * 2 + 1 * (ReqChan - 1) * 2,
        shape=(1, nChans * SampFreq * 5),
    )
    eegnrem1 = b1[0, ::nChans]
    sos = sg.butter(3, 100, btype="low", fs=SampFreq, output="sos")
    yf = sg.sosfilt(sos, eegnrem1)
    yf = ft.fft(yf) / len(eegnrem1)
    xf = np.linspace(0.0, SampFreq / 2, len(eegnrem1) // 2)
    y1 = 2.0 / (len(xf)) * np.abs(yf[: len(eegnrem1) // 2])
    y1 = smth.gaussian_filter(y1, 8)

    return y1, xf
