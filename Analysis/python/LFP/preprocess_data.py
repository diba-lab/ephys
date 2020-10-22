## Script/functions to import openephys data and sync with other data

# folder = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat594\2019DEC06'
# folder ='/data/Working/Opto Project/Rat 594/Rat594_placestim2019-12-05_16-18-31/'
test_folder = '/data/Working/Opto Project/Place stim tests/Rat651_2019-12-10_08-54-56/'
test_bin_folder = '/data/Working/Opto Project/Rat 594/594_placestim_test_2019-12-04_10-24-25/experiment1/recording1/'

import Python3.OpenEphys as oe
import Python3.Binary as ob
import Python3.SettingsXML as SettingsXML
import numpy as np
import matplotlib.pyplot as plt
import scipy.io as sio
import os
import glob
import pandas as pd
import helpers
import scipy.signal as signal

## Now load everything
# First import openephys data - all channels + input TTL events
def load_openephys(folder, Experiment=1, Recording=1, TTLport=None):
    """Loads in openephys continuous and event data from processor. Openephys format ok, binary format not yet finished/vetted"""
    try:  # Load in openephys format
        cont_array = oe.loadFolder(folder)
        events = oe.loadEvents(os.path.join(folder, 'all_channels.events'))
        oe_type = 'oe'
        Rate = 'See cont_array variable'
    except ZeroDivisionError:  # load in binary format
        _, PluginNames = SettingsXML.GetRecChs(os.path.join(folder, 'settings.xml'))
        Proc = list(PluginNames.keys())[0]  # assume first node is the recording processor
        ProcName = PluginNames[Proc]  # Get processor name
        ProcFolderName = ProcName.replace(' ', '_') + '-' + Proc + '.0'
        cont_array, Rate = ob.Load(folder, Experiment=Experiment, Recording=Recording)
        Proc = list(Rate.keys())[0]
        SR = Rate[Proc][str(Experiment - 1)]  # get sample rate
        cont_time = np.load(os.path.join(folder, 'experiment' + str(Experiment) + '/recording' + str(Recording)
                                         + '/continuous/' + ProcFolderName + '/timestamps.npy'))

        if TTLport is not None:
            event_folder = os.path.join(folder, 'experiment' + str(Experiment) + '/recording' + str(Recording) +
                                        '/events/' + ProcFolderName + '/TTL_' + str(TTLport))
            event_data = load_binary_events(event_folder)
        else:
            event_data = None

        oe_type = 'binary'

    return event_data, cont_array, SR


## Load events only recorded in binary format
def load_binary_events(event_folder):
    event_data = []
    for file_name in ['channel_states.npy', 'channels.npy', 'full_words.npy', 'timestamps.npy']:
        event_data.append(np.load(os.path.join(event_folder, file_name)))

    return event_data


## Next import MATLAB data - must have only one mat file in folder!
def load_mat(folder):
    """
    Load .mat file with synchronized optitrack time/position, linear position, matlab time, trigger events, and start/minute
    tracker
    :param:
    """
    mat_files = glob.glob(os.path.join(folder, '*.mat'))
    if len(mat_files) == 1:
        mat_data = sio.loadmat(os.path.join(folder, mat_files[0]))
    elif len(mat_files) == 0:
        mat_data = np.nan
        print('No .mat files in folder, unable to load')
    else:
        mat_data = np.nan
        print('No More than one .mat file in folder, unable to load')

    return mat_data


## Import OptiTrack data here once you've exported it to a csv...
def load_opti(folder):
    """
    Loads optitrack CSV folder - needs a check to make sure you are always loading the position and not rotation values.
    Also needs to get start time/hour for later interpolation!!!
    """
    csv_files = glob.glob(os.path.join(folder, '*.csv'))
    if len(csv_files) == 1:
        opti_data = pd.read_csv(os.path.join(folder, csv_files[0]), header=5)
        temp = pd.read_csv(os.path.join(folder, csv_files[0]), header=0)
        opti_start_time = temp.keys()[3][-11:-3]
    elif len(csv_files) == 0:
        opti_data = np.nan
        print('No .csv files in folder, unable to load')
    else:
        opti_data = np.nan
        print('More than one .csv file in folder, unable to load')

    return opti_data, opti_start_time


## Now plot stuff
#
# # get time of MATLAB TTL pulse out!!!
# oe_zero = event_data[3][event_data[0] == 8]/SR
# start_hour = 16  # from .csv output file, hour (24-hr format) that data starts recording in - figure this out!!!!


## Plot x,y,z, pos over time
def plot_opti_v_mat(opti_data, mat_data, cont_data=np.nan, event_data=np.nan, Rate=30000, on_off_chan=8,
                    LED_chans = [1, 2, 4, 6]):
    """
    Plot optitrack v matlab tracking and continuous data (binary only enabled so far...)
    NEED TO CHECK LED channels!!!
    """
    fig1, ax1 = plt.subplots(3, 3)
    fig1.set_size_inches([15, 6.4])
    ax1[0][0].plot(opti_data['Time (Seconds)'], opti_data['X.2'])
    ax1[0][0].set_ylabel('Xpos Opti')
    ax1[0][0].set_xlabel('Opti time absolute')
    ax1[1][0].plot(opti_data['Time (Seconds)'], opti_data['Y.2'])
    ax1[1][0].set_ylabel('Ypos Opti')
    ax1[1][0].set_xlabel('Opti time absolute')
    ax1[2][0].plot(opti_data['Time (Seconds)'], opti_data['Z.2'])
    ax1[2][0].set_ylabel('Zpos Opti')
    ax1[2][0].set_xlabel('Opti time absolute')

    # Get time elapsed
    record_start_time = mat_data['time_mat'][np.where(np.bitwise_not(np.isnan(mat_data['trig_on'])))[0][0], :]
    tdiff = helpers.mat_time_to_sec(record_start_time, mat_data['time_mat'])
    # Plot matlab values received from optitrack
    ax1[0][1].plot(tdiff,  mat_data['pos_opti'][:, 0])
    ax1[1][1].plot(tdiff, mat_data['pos_opti'][:, 1])
    ax1[2][1].plot(tdiff, mat_data['pos_opti'][:, 2])

    # Plot trigger on and off
    trig_bool = mat_data['trig_on'][:, 0] > 0.9
    ax1[0][1].plot(tdiff[trig_bool], mat_data['pos_opti'][trig_bool, 0], 'r.')
    ax1[0][1].set_ylabel('Xpos Mat')
    ax1[0][1].set_xlabel('Mat_time from start')
    ax1[1][1].plot(tdiff[trig_bool], mat_data['pos_opti'][trig_bool, 1], 'r.')
    ax1[1][1].set_ylabel('Ypos Mat')
    ax1[1][1].set_xlabel('Mat_time from start')
    ax1[2][1].plot(tdiff[trig_bool], mat_data['pos_opti'][trig_bool, 2], 'r.')
    ax1[2][1].set_ylabel('Zpos Mat')
    ax1[2][1].set_xlabel('Mat_time from start')

    # Plot lin pos with triggering vs time.
    ax1[0][2].plot(tdiff, mat_data['pos_lin'][:, 0])
    ax1[0][2].plot(tdiff[trig_bool], mat_data['pos_lin'][trig_bool, 0], 'r.')
    ax1[0][2].set_ylabel('Linear position (-1=start, 1=end)')
    ax1[0][2].set_xlabel('Mat_time from start')

    # Plot trace with stimulations here!!!
    plot_colors = ['r', 'g', 'b', 'c']
    # get start time for matlab data
    try:  # Load from on_minutes input variable which tracks TTL pulses for when recording starts and switches every minute
        on_time_mat = mat_data['time_mat'][np.where(mat_data['on_minutes'] == 1)[0]]
    except KeyError:  # if no on_minutes found use first non-nan in 'trig_on'
        on_time_mat = mat_data['time_mat'][np.where(np.bitwise_not(np.isnan(mat_data['trig_on'])))]

    # get start, end, and overall times for all continuous timestamps
    on_time = event_data[3][event_data[0] == on_off_chan]/Rate
    off_time = event_data[3][event_data[0] == -on_off_chan]/Rate
    oe_times_aligned = np.arange(cont_data.shape[0]).reshape(cont_data.shape[0], -1)/Rate - on_time
    event_times_aligned = event_data[3]/Rate - on_time
    ax1[1][2].get_shared_x_axes().join(ax1[1][2], ax1[0][2])
    ax1[1][2].plot(oe_times_aligned, cont_data)
    ylims = ax1[1][2].get_ylim()
    for chan, color in zip(LED_chans, plot_colors):
        starts = np.where(event_data[0] == chan)[0]
        stops = np.where(event_data[0] == -chan)[0]
        [ax1[1][2].plot(event_times_aligned[[start, start]], ylims, color) for start in starts]
        # [ax1[1][2].plot(event_times_aligned[[stop, stop]], ax1[1][2].get_ylim(), color) for stop in stops]


    # plot x/z overhead...
    fig2, ax2 = plt.subplots(1, 2)
    fig2.set_size_inches([6.4, 4.8])
    ax2[0].plot(opti_data['X.2'], opti_data['Z.2'])
    ax2[0].set_title('Optitrack')
    ax2[1].plot(mat_data['pos_opti'][:, 0], mat_data['pos_opti'][:, 2])
    ax2[1].set_title('Opti API -> MATLAB')

    return fig1, ax1, fig2, ax2

# Get start time

## Downsample OE to 1250Hz
def resampleOEtoLFP(traces, SRin=30000, SRout=1250):
    """
    downsample open-ephys traces from 30000 to 1250 Hz. Currently only supports those two sampling rates
    :param traces: ntimes x nchannels memmap array
    :param SRin: 30000
    :param SRout: 1250
    :return:
    """
    if SRin == 30000 and SRout == 1250:
        nchannels = traces.shape[1]

        # this is a poor way to do this in python but it'll work for now
        ds_trace_list = []
        print('Downsampling data from ' + str(SRin) + 'Hz to ' + str(SRout) + 'Hz')
        for chan in range(0, nchannels):
            ds_trace_list.append(signal.decimate(signal.decimate(traces[:, chan], 6), 4))

        traces_ds = np.array(ds_trace_list)

        # This is buggy - figure out later!
        # if traces_ds.shape[1] != nchannels:  # make it the same format as the input!
        #     traces_ds.swapaxes(0, 1)

    else:
        print('SRin=30000 and SRout=1250 only supported currently')
        traces_ds = []

    return traces_ds, SRout



## Create eeg file from dat file
def oe_to_lfp_file(folder, Experiment=1, Recording=1, SReeg=1250):
    """Downsamples a .dat file to 1250 (default) and saves with .lfp"""
    _, full_traces, SRoe = load_openephys(folder, Experiment=Experiment, Recording=Recording)

    _, PluginNames = SettingsXML.GetRecChs(os.path.join(folder, 'settings.xml'))
    Proc = list(PluginNames.keys())[0]  # assume first node is the recording processor
    traces_eeg, _ = resampleOEtoLFP(full_traces[Proc][str(Experiment - 1)][str(Recording - 1)], SRin=SRoe, SRout=1250)
    np.save(os.path.join(folder, 'continuous_eeg.npy'), traces_eeg)


## Now plot stuff!!

if __name__ == '__main__':
    oe_to_lfp_file(r'/data/Working/Opto/Rat613/ClosedLoopTest2/Rat613_SWRstim_probe1_2020-08-07_10-55-22/', Experiment=2)

    pass