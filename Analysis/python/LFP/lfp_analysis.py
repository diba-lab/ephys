## LFP analysis functions
import scipy.signal as signal
import numpy as np


## Create Butterworth filter - copied from scipy-cookbook webpage
def butter_bandpass(lowcut, highcut, fs, order=2):
    """
    Simplify inputs for creating a Butterworth filter. copied from scipy-cookbook webpage.
    :param lowcut: Hz
    :param highcut: Hz
    :param fs: Sampling rate in Hz
    :param order: (optional) 2 = default
    :return:
    """
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    b, a = signal.butter(order, [low, high], btype='band')

    return b, a


## filter data through butterworth filter
def butter_bandpass_filter(data, lowcut, highcut, fs, type='filtfilt', order=2):
    """
    Filter data through butterworth bandpass filter. Copied from scipy-cookbook webpage.
    :param data: array of data sampled at fs
    :param lowcut: 4
    :param highcut: 10
    :param type: 'filtfilt' (default) filters both ways, 'lfilt' filters forward only (and likely induces a phase offset).
    :param fs: 30000
    :param order: (optional) default = 2 to match Sieglie et al., eLife (2014)
    :return: filt_data: filtered data
    """
    b, a = butter_bandpass(lowcut, highcut, fs, order=order)
    if type is 'lfilt':
        filt_data = signal.lfilter(b, a, data)
    elif type is 'filtfilt':
        filt_data = signal.filtfilt(b, a, data)

    return filt_data


## Peak-trough detection via Belluscio et al. (2012) J. Neuro
def get_local_extrema(trace, type='max'):
    """ Get local extrema, assuming it occurs near the middle of the trace. spits out an np.nan if there a relative min
    or max occurs at the edge.

    :param trace: lfp trace
    :param type: 'max' (default) or 'min'
    :return: index in trace where max/min is located. np.nan if there is a relative minima/maxima at edge of trace.
    """
    if type is 'max':
        temp = signal.argrelmax(trace, order=int(len(trace)/2))[0]
    elif type is 'min':
        temp = signal.argrelmin(trace, order=int(len(trace)/2))[0]

    if temp.size is 1:
        ind_rel_extreme = temp[0]
    else:
        ind_rel_extreme = np.nan

    return ind_rel_extreme


## Plot trace in a nice working window
