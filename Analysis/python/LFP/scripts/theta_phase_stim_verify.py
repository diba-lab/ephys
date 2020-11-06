## Scratchpad for figuring out opto related data analysis


## Scratchpad for opto
import matplotlib.pyplot as plt
import numpy as np
import Analysis.python.LFP.preprocess_data as pd
import Analysis.python.LFP.lfp_analysis as lfp
import scipy.signal as signal
import pickle
import os
import Analysis.python.LFP.helpers as helpers

# Make text save as whole words
plt.rcParams['pdf.fonttype'] = 42

## Import 2/14/2020 theta stim session
sync_cputime = 4285440  # from sync_message.txt in recording1 folder
folder = '/data/Working/Opto/Rat615/Rat615_2020-02-14_11-16-15_track/'
phase_detect_folder = '/data/Working/Opto/Rat615/Rat615_2020-02-14_11-16-15_track/experiment1/recording1/events/Phase_Detector-108.0/TTL_1/'
event_data, cont_array, SRoe = pd.load_openephys(folder)
phase_events = pd.load_binary_events(phase_detect_folder)

traces_ds, SRlfp = pd.OEtoLFP(cont_array['100']['0']['0'])  # downsample
traces_ds = traces_ds.T  # hack

## or just load directly
if os.name == 'nt':
    phase_detect_folder = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat615\2020-02-14_11-16-15\experiment1\recording1\events\Phase_Detector-108.0\TTL_1'
    event_detect_folder = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat615\2020-02-14_11-16-15\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1'
    save_loc = r'C:\Users\Nat\Dropbox\UM\Meeting Plots'

sync_cputime = 4285440  # from sync_message.txt in recording1 folder
saved_data_file = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat615\2020-02-14_11-16-15\theta_phase_data.pkl'
save_file = open(saved_data_file, 'rb')
data = pickle.load(save_file)
traces_ds, SRoe, SRlfp = data['traces_ds'], data['SRoe'], data['SRlfp']
event_data = pd.load_binary_events(event_detect_folder)
phase_events = pd.load_binary_events(phase_detect_folder)

## Plot channel with units on
chan_plot = 19  # channel you triggered off of
artifact_chan = 13  # this channel should have good stimulation artifact on it for reference...
start_time = 17  # minutes
end_time = 29  # minutes
v_range = 600  # uV
time_span = 2  # seconds
fig, ax = plt.subplots(2, 1, sharex=True, sharey=True)
fig.set_size_inches([26, 7])

time_sec = np.arange(0, traces_ds.shape[0])/SRlfp
event_times_sec = (event_data[3] - sync_cputime)/SRoe
phase_times_sec = (phase_events[3] - sync_cputime)/SRoe

plot_bool = np.bitwise_and(time_sec > start_time*60, time_sec <= end_time*60)
event_plot_bool = np.bitwise_and(event_times_sec > start_time*60, event_times_sec <= end_time*60)
phase_plot_bool = np.bitwise_and(phase_times_sec > start_time*60, phase_times_sec <= end_time*60)

ax[0].plot(time_sec[plot_bool], traces_ds[plot_bool, chan_plot])
ax[1].plot(time_sec[plot_bool], traces_ds[plot_bool, artifact_chan])
ax[0].set_ylim([-v_range, v_range])
ax[1].set_xlim([start_time*60, start_time*60 + time_span])

## Plot stim start and end times

# First get TTL in from OSC1lite
on_stim_bool = np.bitwise_and(event_plot_bool, event_data[0] == 1)
off_stim_bool = np.bitwise_and(event_plot_bool, event_data[0] == -1)
on_stim_times = event_times_sec[on_stim_bool]
off_stim_times = event_times_sec[off_stim_bool]
ylims = [-2*v_range, 2*v_range]
ylims_plot = [-2*v_range, 2*v_range, np.nan]
on_stim_time_plot = []
off_stim_time_plot = []
ystim_plot = []
for t_start, t_end in zip(on_stim_times, off_stim_times):
    on_stim_time_plot.extend([t_start, t_start, np.nan])
    off_stim_time_plot.extend([t_end, t_end, np.nan])
    ystim_plot.extend(ylims_plot)

hon = [a.plot(on_stim_time_plot, ystim_plot, 'g-') for a in ax]
hoff = [a.plot(off_stim_time_plot, ystim_plot, 'r-') for a in ax]

# Now plot phase detector times
on_detect_bool = np.bitwise_and(phase_plot_bool, phase_events[0] > 0)
off_detect_bool = np.bitwise_and(phase_plot_bool, phase_events[0] < 0)
on_detect_times = phase_times_sec[on_detect_bool]
off_detect_times = phase_times_sec[off_detect_bool]
on_detect_time_plot = []
off_detect_time_plot = []
ydetect_plot = []
# aggregate these into a list.
for t_on, t_off in zip(on_detect_times, off_detect_times):
    on_detect_time_plot.extend([t_on, t_on, np.nan])
    off_detect_time_plot.extend([t_off, t_off, np.nan])
    ydetect_plot.extend(ylims_plot)

hon_detect = [a.plot(on_detect_time_plot, ydetect_plot, 'g--') for a in ax]
hoff_detect = [a.plot(off_detect_time_plot, ydetect_plot, 'r--') for a in ax]

fig.legend([hon_detect[1][0], hoff_detect[1][0], hon[1][0], hoff[1][0]],
             ['Phase Detect Start', 'Phase Detect End', 'Stim TTL Start', 'Stim TTL End'])

## Get histogram of lag times between phase detection and stimulation TTL

on_detect_match = []
for t_stim_on in on_stim_times:
    on_detect_match.append(on_detect_times[t_stim_on - on_detect_times > 0].max())

detect_stim_lags = on_stim_times - on_detect_match

fig2, ax2 = plt.subplots(2, 2)
fig2.set_size_inches([14.9, 8.25])

# Plot detection to TTL lags
ax2[0, 0].hist(detect_stim_lags)
ax2[0, 0].set_xlabel('Detection to Stimulation TTL Lags (s)')
ax2[0, 0].set_ylabel('Count')
ax2[0, 0].set_title(str(len(on_detect_times) - len(on_detect_match)) + ' detections not triggered')

# Plot detection to stim artifact lags
ax2[0, 1].set_title('Detection to Stim Artifact Lags Here')

# Plot phase detection lengths -
# this doesn't work because sometimes multiple ons happen before an off happens...
# if on_detect_times[0] > off_detect_times[0]:
#     phase_durations = off_detect_times[1:] - on_detect_times[0:-1]
# else:
#     phase_durations = off_detect_times - on_detect_times

# this should work - assume you only get an "off" phase detection event if you have a preceding "on" phase detection event
phase_durations = []
for t_end in off_detect_times:
    if np.any(t_end > on_detect_times):
        phase_durations.append(t_end - np.max(on_detect_times[on_detect_times < t_end]))

ax2[1, 0].hist(phase_durations, bins=10, range=((np.mean(phase_durations) - 0.1, np.mean(phase_durations) + 0.1)))
ax2[1, 0].set_xlabel('Phase Detection Durations (s)')
ax2[1, 0].set_ylabel('Count')

# Plot stimulation TTL times
if on_stim_times[0] > off_stim_times[0]:
    stim_durations = off_stim_times[1:] - on_stim_times[0:-1]
else:
    if len(on_stim_times) == len(off_stim_times):
        stim_durations = off_stim_times - on_stim_times
    elif len(on_stim_times) == (len(off_stim_times) + 1):
        stim_durations = off_stim_times - on_stim_times[0:-1]

ax2[1, 1].hist(stim_durations)
ax2[1, 1].set_xlabel('Stimulation (TTL) Durations (s)')
ax2[1, 1].set_ylabel('Count')

## Now apply a butterworth filter to data to see how well it matches the phase...
# Might need to limit to only high theta epochs?
far_shank_channel = 1  # channel with no artifact on far shank from trace you are looking at.
spike_channel = 22  # to test if spikes mess with theta detection
plot_stim_times = False

lowcut = 4
highcut = 12
order = 2

time_plot = time_sec[plot_bool]
trace = traces_ds[plot_bool, chan_plot]
artifact_trace = traces_ds[plot_bool, artifact_chan]
far_trace = traces_ds[plot_bool, far_shank_channel]
spike_trace = traces_ds[plot_bool, spike_channel]

trace_lfilt = lfp.butter_bandpass_filter(trace, lowcut, highcut, SRlfp, order=order, type='lfilt')
trace_filtfilt = lfp.butter_bandpass_filter(trace, lowcut, highcut, SRlfp, order=order, type='filtfilt')
artifact_filt = lfp.butter_bandpass_filter(artifact_trace, lowcut, highcut, SRlfp, order=order)
far_filt = lfp.butter_bandpass_filter(far_trace, lowcut, highcut, SRlfp, order=order)
spike_filt = lfp.butter_bandpass_filter(spike_trace, lowcut, highcut, SRlfp, order=order)
filt_traces = [trace_lfilt, artifact_filt, far_filt, spike_filt]
trace_list = [trace, artifact_trace, far_trace, spike_trace]  # aggregate into a list for easy plotting later
trace_names = ['Trigger Trace', 'Artifact Trace', 'Far Shank Trace', 'Spiking Trace']  # corresponding names

# Plot specified traces
trace_plot_ids = [0, 1]  # specify traces here! Must have 0 in 1st index!
traces_plot = []
names_plot = []
filt_plot = []
[traces_plot.append(trace_list[ind]) for ind in trace_plot_ids]
[names_plot.append(trace_names[ind]) for ind in trace_plot_ids]
[filt_plot.append(filt_traces[ind]) for ind in trace_plot_ids]
fig, ax = plt.subplots(len(trace_plot_ids), 1, sharex=True, sharey=True)
fig.set_size_inches([26, 14*len(trace_plot_ids)/4])
[ax[idt].plot(time_plot, tr) for idt, tr in enumerate(traces_plot)]
[ax[idt].set_title(title_use) for idt, title_use in enumerate(names_plot)]
htrigl = [a.plot(time_plot, trace_lfilt, 'k-') for a in ax]  # plot triggered channel LFP over everything
hselfl = [a.plot(time_plot, tfilt, 'c--') for a, tfilt in zip(ax[1:], filt_plot[1:])]  # plot own-channel filtered trace

hon_detect = ax[0].plot(on_detect_time_plot, ydetect_plot, 'g--')
if plot_stim_times:
    hon = [a.plot(on_stim_time_plot, ystim_plot, 'g-') for a in ax]
    hoff = [a.plot(off_stim_time_plot, ystim_plot, 'r-') for a in ax]

[a.set_xlabel('Time (s)') for a in ax]
[a.set_ylabel('uV') for a in ax]
ax[0].set_xlim([start_time*60, start_time*60 + time_span])
ax[0].set_ylim([-v_range, v_range])
# if plot_stim_times:
#     fig.legend([htrigl[0][0], hselfl[0][0], hon_detect[0], hon[0][0], hoff[0][0]], ['Trigger Channel Filtered LFP (' + str(lowcut) + ' to ' + str(highcut) + 'Hz)',
#                                           'Self Channel Filtered LFP', 'Peak Detection', 'Stimulation Start', 'Stimulation End'])
# else:
#     fig.legend([htrigl[0][0], hselfl[0][0], hon_detect[0]], ['Trigger Channel Filtered LFP (' + str(lowcut) + ' to '
#                 + str(highcut) + 'Hz)', 'Self Channel Filtered LFP', 'Peak Detection'])


## Get phases of detection and stim!
nbins = 30  # number of bins to use in histograms

# Run hilbert transform to get real and imaginary parts of signal
trace_analytic = signal.hilbert(trace_lfilt)  # get real and imaginary parts of signal
trig_trace_phase = np.angle(trace_analytic)

# Sanity check plot to make sure you are getting the proper angle...
# fig3, ax3 = plt.subplots()
# fig3.set_size_inches(26, 4)
# ax3.plot(time_plot, trace_lfilt)
# ax3.plot(time_plot, np.angle(trace_analytic)*v_range/8, 'r-')
#
# ax3.set_xlim([start_time*60, start_time*60 + time_span])
# ax3.set_ylim([-v_range, v_range])

# Now plot histogram of trigger phases!!! Looks great!! Mostly a match
detect_phases2 = []
[detect_phases2.append(trig_trace_phase[np.searchsorted(time_plot, on_detect_time, side='left')])
 for on_detect_time in on_detect_times]

# Same but for start and end
stim_start_phases = []
stim_end_phases = []
[stim_start_phases.append(trig_trace_phase[np.searchsorted(time_plot, on_stim_time, side='left')])
 for on_stim_time in on_stim_times]
[stim_end_phases.append(trig_trace_phase[np.searchsorted(time_plot, off_stim_time, side='left')])
 for off_stim_time in off_stim_times]

figh, axh = plt.subplots(1, 3)
figh.set_size_inches([19.1, 5.3])
phases_list = [detect_phases2, stim_start_phases, stim_end_phases]
titles = ['Detection', 'Start of Stimulation', 'End of Stimulation']
[a.hist(phases, bins=nbins) for a, phases in zip(axh, phases_list)]
[a.set_xlabel('Phase (-pi = trough, 0 = peak)') for a in axh]
[a.set_ylabel('Count') for a in axh]
[a.set_title(title) for a, title in zip(axh, titles)]

# Draw an example cosine trace on top of each plot
ylims = [a.get_ylim()[1] for a in axh]
plot_phase = np.linspace(-np.pi, np.pi, 50)
curve_plot = np.cos(plot_phase)
[a.plot(plot_phase, curve_plot*ylim/4 + ylim/2, 'm-') for a, ylim in zip(axh, ylims)]


## Compare different band-pass filter limits
figc, axc = plt.subplots(3, 1, sharex=True, sharey=True)
figc.set_size_inches(26, 11)
bp_limits = [[4, 10], [6, 12], [4, 12]]
title_text = ['4-10Hz (Us)', '6-12Hz(Wide)', '4-12Hz(Sieglie et al.)']
for a, bp_limit, title_use in zip(axc, bp_limits, title_text):
    trace_plot = lfp.butter_bandpass_filter(trace, bp_limit[0], bp_limit[1], SRlfp, order=order)
    a.plot(time_plot, trace)
    a.plot(time_plot, trace_plot, 'r-')
    a.set_title(title_use)

axc[0].set_xlim([start_time*60, start_time*60 + time_span])
axc[0].set_ylim([-v_range, v_range])


## Peak-trough method (Belluscio et al. 2012 J Neuro) - fold into lfp_analysis.peak_trough_detect eventually
lowcut_bell = 1  # Hz
highcut_bell = 80  # Hz
peak_trough_offset_sec = 0.07  # seconds to look for trough of wide-filtered trace next to 4-10Hz filtered trace

wide_filt = lfp.butter_bandpass_filter(trace, lowcut_bell, highcut_bell, SRlfp, order=order)

fig, ax = plt.subplots(1, 1, sharex=True, sharey=True)
fig.set_size_inches([26, 3])
hraw = ax.plot(time_plot, trace)
ax.plot(time_plot, wide_filt, 'm')
ax.plot(time_plot, trace_lfilt, 'k--')
ax.set_xlim([start_time*60, start_time*60 + time_span])
ax.set_ylim([-v_range, v_range])
ax.set_xlabel(['Time (s)'])
ax.set_ylabel('uV')

offset_frames = np.round(peak_trough_offset_sec*SRlfp)

# First detect peak and trough off narrowband filtered signal - do hilbert transform
# trough = -pi->pi, peak = 0 (- -> +)
trace_analytic = signal.hilbert(trace_lfilt)  # get real and imaginary parts of signal
trig_trace_phase = np.angle(trace_analytic)
# ax.plot(time_plot, trig_trace_phase*v_range/8, 'r-')
peak_bool = np.bitwise_and(trig_trace_phase[0:-1] < 0, trig_trace_phase[1:] >= 0)
peak_bool = np.append(peak_bool, False)
trough_bool = np.bitwise_and(trig_trace_phase[0:-1] > 0, trig_trace_phase[1:] <= 0)
trough_bool = np.append(trough_bool, False)

# Indices to peak and trough of narrowband trace
peak_inds = np.where(peak_bool)[0]
trough_inds = np.where(trough_bool)[0]

# Check that above code works...
# ax.plot(time_plot[peak_bool], trace_lfilt[peak_bool], 'r*')
# ax.plot(time_plot[trough_bool], trace_lfilt[trough_bool], 'g*')

##  Plot times between peak and trough - seems likes looking 0.07 seconds to either side should be ok...
fig2, ax2 = plt.subplots(1, 2)
ax2[0].hist(np.diff(np.where(trough_bool))[0]/SRlfp)
ax2[0].set_xlabel('Trough-to-trough times (s)')
ax2[1].hist(np.diff(np.where(peak_bool))[0]/SRlfp)
ax2[1].set_xlabel('Peak-to-peak times (s)')

## now step through and find closest peak/trough in the wide-filtered trace when compared to the narrowband filtered trace.
# THIS IS ALL COMMENTED NOW SO THAT YOU DONT ACCIDENTALLY OVERWRITE EXISTING VALUES - NEED TO IMPLEMENT DOWNSAMPLING FIRST!!!
wide_peak_inds = []
wide_trough_inds = []

# Step through and look for each trough in the WIDE filtered signal between two peaks in the NARROW filtered signal
# how fast is this compared to just running it on all the trace and looking for closest inds? Bet it depends on if I
# downsample first...

n = 0
for idp, idp1 in zip(peak_inds[0:-1], peak_inds[1:]):
    wide_trough_inds.append(lfp.get_local_extrema(wide_filt[idp:idp1], type='min') + idp)
    n = n + 1
    if int(n/100) == n/100:
        print(n)

n = 0
# Ditto to above but for peaks
for idt, idt1 in zip(trough_inds[0:-1], trough_inds[1:]):
    wide_peak_inds.append(lfp.get_local_extrema(wide_filt[idt:idt1], type='max') + idt)
    n = n + 1
    if int(n/100) == n/100:
        print(n)

## looks decent except when there is crappy theta. Filter out these epochs? Put on speed threshold?
wide_peak_inds_good = [idp for idp in wide_peak_inds if not np.isnan(idp)]
wide_trough_inds_good = [idt for idt in wide_trough_inds if not np.isnan(idt)]

ax.plot(time_plot[wide_peak_inds_good], wide_filt[wide_peak_inds_good], 'ro')
ax.plot(time_plot[wide_trough_inds_good], wide_filt[wide_trough_inds_good], 'go')

## Get rise and falling times of theta - trough = -pi/+pi, peak = 0

# if peak times generally lead trough times, chop off first peak value
if np.nanmean(np.array(wide_peak_inds) - np.array(wide_trough_inds)) < 0:
    peak_inds_use = wide_peak_inds[1:]
    trough_inds_use = wide_trough_inds[0:-1]
    next_trough_inds = wide_trough_inds[1:]
else:
    peak_inds_use = wide_peak_inds
    trough_inds_use = wide_trough_inds
    next_trough_inds = wide_trough_inds[1:]


wave_phase_inds = []
wave_phases = []
for idt, idp, idt1 in zip(trough_inds_use, peak_inds_use, next_trough_inds):
    if not np.any(np.isnan([idt, idp, idt1])) and idt < idp < idt1:  # only run below if you have reliable peak/trough info
        trace_snippet = wide_filt[idt:idt1]  # grab a snippet of the trace to use
        if np.all(trace_snippet <= 0) or np.all(trace_snippet >= 0) or trace_snippet[0] > 0 or trace_snippet[-1] > 0\
                or wide_filt[idp] < 0:  # Make sure trace is not all above or below zero and that peak/troughs are above/below zero
            wave_phase_inds.extend([np.nan, np.nan, np.nan, np.nan, np.nan])
        else:
            rise_zero = np.max(np.where(np.bitwise_and(trace_snippet <= 0, np.arange(idt, idt1) < idp))[0])
            fall_zero = np.min(np.where(np.bitwise_and(trace_snippet <= 0, np.arange(idt, idt1) > idp))[0])
            wave_phase_inds.extend([idt, idt + rise_zero, idp, idt + fall_zero, idt1-1])
    else:
        wave_phase_inds.extend([np.nan, np.nan, np.nan, np.nan, np.nan])
    wave_phases.extend([-np.pi, -np.pi/2, 0, np.pi/2, np.pi])

# now plot
wave_phase_inds_good = [idph for idph in wave_phase_inds if not np.isnan(idph)]
wave_phases_good = [ph for ph, idph in zip(wave_phases, wave_phase_inds) if not np.isnan(idph)]
ax.plot(time_plot[wave_phase_inds_good], np.asarray(wave_phases_good)*v_range/8, 'r-')


## histogram of rise times vs fall times overlaid to prove I'm doing things correctly
fig35, ax35 = plt.subplots(1, 2)
fig35.set_size_inches([13.5, 4.8])
rise_times = (np.array(peak_inds_use) - np.array(trough_inds_use))/SRlfp
fall_times = (np.array(next_trough_inds) - np.array(peak_inds_use))/SRlfp
ax35[0].hist(rise_times, bins=20, range=(-0.15, 0.3))
ax35[0].set_title('Peak-Trough Method')
ax35[0].set_xlabel('Rising Phase Times (s)')
ax35[0].text(0.15, 1000, 'mean = ' + '{:.3f}'.format(np.nanmean(rise_times)) + ' sec')
ax35[1].hist(fall_times, bins=20, range=(-0.15, 0.3))
ax35[1].set_title('Peak-Trough Method')
ax35[1].set_xlabel('Falling Phase Times (s)')
ax35[1].text(0.15, 1000, 'mean = ' + '{:.3f}'.format(np.nanmean(fall_times)) + ' sec')

## scatterplot of 4-10Hz phase versus Belluscio phase...

# first interpolate all wideband filtered points to the correct phase...
wide_phase = np.interp(np.arange(0, trig_trace_phase.shape[0]), wave_phase_inds, wave_phases)
# hph_bell = ax.plot(time_plot, wide_phase*v_range/8)  # plot on old trace as a sanity check

# now plot
figc, axc = plt.subplots()
axc.hist2d(wide_phase, trig_trace_phase, range=[[-np.pi, np.pi], [-np.pi, np.pi]], bins=100)
axc.set_xlabel('Belluscio Method Phase')
axc.set_ylabel('4-12Hz Bandpass Phase')
axc.plot([-np.pi, np.pi], [-np.pi, np.pi], 'r')


## Get phases of detection and stim with Belluscio method!
nbins = 30  # number of bins to use in histograms

# Now plot histogram of trigger phases!!! Looks great!! Mostly a match
detect_phases2bell = []
[detect_phases2bell.append(wide_phase[np.searchsorted(time_plot, on_detect_time, side='left')])
 for on_detect_time in on_detect_times]

# Same but for start and end
stim_start_phasesbell, stim_end_phasesbell = [], []
[stim_start_phasesbell.append(wide_phase[np.searchsorted(time_plot, on_stim_time, side='left')])
 for on_stim_time in on_stim_times]
[stim_end_phasesbell.append(wide_phase[np.searchsorted(time_plot, off_stim_time, side='left')])
 for off_stim_time in off_stim_times]


# Now plot histogram of trigger phases!!! Looks great!! Mostly a match
detect_phases2 = []
[detect_phases2.append(trig_trace_phase[np.searchsorted(time_plot, on_detect_time, side='left')])
 for on_detect_time in on_detect_times]

# Same but for start and end
stim_start_phases = []
stim_end_phases = []
[stim_start_phases.append(trig_trace_phase[np.searchsorted(time_plot, on_stim_time, side='left')])
 for on_stim_time in on_stim_times]
[stim_end_phases.append(trig_trace_phase[np.searchsorted(time_plot, off_stim_time, side='left')])
 for off_stim_time in off_stim_times]

figh, axh = plt.subplots(2, 3)
figh.set_size_inches([19.1, 11])
phases_list = [[detect_phases2, stim_start_phases, stim_end_phases],
               [detect_phases2bell, stim_start_phasesbell, stim_end_phasesbell]]
titles = [['Detection - 4-12Hz Bandpass', 'Start of Stim - 4-12Hz Bandpass', 'End of Stim - 4-12Hz Bandpass'],
          ['Detection - Belluscio Method', 'Start of Stim - Belluscio Method', 'End of Stim - Belluscio Method']]

for i in range(0, 2):
    [a.hist(phases, bins=nbins, color='k') for a, phases in zip(axh[i], phases_list[i])]
    [a.set_xlabel('Phase (-pi = trough, 0 = peak)') for a in axh[i]]
    [a.set_ylabel('Count') for a in axh[i]]
    [a.set_title(title) for a, title in zip(axh[i], titles[i])]

    # Draw an example cosine trace on top of each plot
    ylims = [a.get_ylim()[1] for a in axh[i]]
    plot_phase = np.linspace(-np.pi, np.pi, 50)
    curve_plot = np.cos(plot_phase)
    [a.plot(plot_phase, curve_plot*ylim/4 + ylim/2, 'm-') for a, ylim in zip(axh[i], ylims)]

[a.spines['right'].set_visible(False) for a in axh.reshape(-1)]
[a.spines['top'].set_visible(False) for a in axh.reshape(-1)]
## same as above but after adding a lag to target the peak

font = {'family': 'normal', 'weight': 'normal', 'size': 22}
plt.rc('font', **font)
peak_target_lag_time = 75  # ms to inject
ytick_unit = 100  #plotting units

stim_pseudostart_w_lag, stim_pseudoend_w_lag = [], []
[stim_pseudostart_w_lag.append(wide_phase[np.searchsorted(time_plot, on_stim_time + peak_target_lag_time/1000, side='left')])
 for on_stim_time in on_stim_times[on_stim_times + peak_target_lag_time/1000 < on_stim_times.max()]]
[stim_pseudoend_w_lag.append(wide_phase[np.searchsorted(time_plot, off_stim_time + peak_target_lag_time/1000, side='left')])
 for off_stim_time in off_stim_times[off_stim_times + peak_target_lag_time/1000 < off_stim_times.max()]]

figh2, axh2 = plt.subplots(2, 2)
figh2.set_size_inches([16.1, 9.2])
phases_list = [[stim_start_phasesbell, stim_end_phasesbell],
               [stim_pseudostart_w_lag, stim_pseudoend_w_lag]]
titles = [['Stim Start - Peak Detection', 'Stim End - Peak Detection'],
          ['Stim Start - Peak Det. + ' + str(peak_target_lag_time) + 'ms Lag',
           'Stim End - Peak Det. + ' + str(peak_target_lag_time) + 'ms Lag']]
overlay = False
colors = [(0, 0, 0, 0.5), (0, 1, 0, 0.5)]
ecs = ['k', 'g']
for i in range(0, 2):
    if overlay:
        [a.hist(phases, bins=nbins, color=colors[i], ec=ecs[i]) for a, phases in zip(axh2[0], phases_list[i])]
    else:
        [a.hist(phases, bins=nbins, color='k') for a, phases in zip(axh2[i], phases_list[i])]

    [a.set_xlabel(r'$\theta$ Phase') for a in axh2[i]]
    [a.set_ylabel('Count') for a in axh2[i]]
    [a.set_title(title) for a, title in zip(axh2[i], titles[i])]

    # Draw an example cosine trace on top of each plot
    ylims = [a.get_ylim()[1] for a in axh2[i]]
    plot_phase = np.linspace(-np.pi, np.pi, 50)
    curve_plot = np.cos(plot_phase)
    [a.plot(plot_phase, curve_plot*ylim/4 + ylim/2, 'm-') for a, ylim in zip(axh2[i], ylims)]

    # Make plots pretty
    [helpers.pretty_plot(a) for a in axh2[i]]
    [a.set_xticks([-3.14, 0, 3.14]) for a in axh2[i]]
    [a.set_xticklabels([r'-$\pi$', str(0), r'$\pi$']) for a in axh2[i]]
    [helpers.set_ytick_units(a, ytick_unit) for a in axh2[i]]

figh2.savefig(os.path.join(save_loc, 'Stim time histograms w ' + str(peak_target_lag_time) + 'ms lag.pdf'))

## Compare lfilt to filtfilt
fig, ax = plt.subplots()
fig.set_size_inches([26, 3])
hraw = ax.plot(time_plot, trace)
hlfilt = ax.plot(time_plot, trace_lfilt, 'k--')
hfiltfilt = ax.plot(time_plot, trace_filtfilt, 'm-.')

ax.set_xlim([start_time*60, start_time*60 + time_span])
ax.set_ylim([-v_range, v_range])

plt.legend([hlfilt[0], hfiltfilt[0]], ['lfilt', 'filtfilt'])

