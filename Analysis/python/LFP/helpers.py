# helper functions
import numpy as np
import datetime
import math
import numpy as np
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import seaborn as sns
import scipy.stats as stats
import scikit_posthocs as sp


def pretty_plot(ax, round_ylim=False):
    """Generic function to make plot pretty, bare bones for now, will need updating
    :param round_ylim set to True plots on ticks/labels at 0 and max, rounded to the nearest decimal. default = False
    """

    # TODO: move this into a plot_function helper module or something similar
    # set ylims to min/max, rounded to nearest 10
    if round_ylim == True:
        ylims_round = np.round(ax.get_ylim(), decimals=-1)
        ax.set_yticks(ylims_round)
        ax.set_yticklabels([f'{lim:g}' for lim in iter(ylims_round)])

    # turn off top and right axis lines
    ax.spines['right'].set_visible(False)
    ax.spines['top'].set_visible(False)

    return ax


def set_ytick_units(ax, unit):
    """Set tick units on y-axis, e.g. unit=100 will label 0, 100, 200, etc."""
    order_mag = math.floor(math.log10(unit))
    # ylims_round = [int(np.round(lim, decimals=-order_mag)) for lim in ax.get_ylim()]
    ylims_round = [int(np.floor(ax.get_ylim()[0]/unit)*unit), int(np.ceil(ax.get_ylim()[1]/unit)*unit)]
    ax.set_yticks(np.arange(ylims_round[0], ylims_round[1], unit))
    ax.set_yticklabels(np.arange(ylims_round[0], ylims_round[1], unit).astype('str'))

    return ax


def mat_time_to_sec(t0, t):

    print('test worked')
    # Get start time
    year0 = int(t0[0])
    month0 = int(t0[1])
    day0 = int(t0[2])
    hour0 = int(t0[3])
    min0 = int(t0[4])
    sec0 = int(np.floor(t0[5]))
    msec0 = int((t0[5]-sec0)*1000000)
    t0py = datetime.datetime(year0, month0, day0, hour0, min0, sec0, msec0)

    # Get times to compare
    year = t.reshape(-1, 6)[:, 0]
    month = t.reshape(-1, 6)[:, 1]
    day = t.reshape(-1, 6)[:, 2]
    hour = t.reshape(-1, 6)[:, 3]
    min = t.reshape(-1, 6)[:, 4]
    sec = np.floor(t.reshape(-1, 6)[:, 5])
    msec = (t.reshape(-1, 6)[:, 5] - sec)*1000000

    tdiff = []
    for yr, mo, dy, hr, mi, s, ms in zip(year, month, day, hour, min, sec, msec):
        diff_temp = datetime.datetime(int(yr), int(mo), int(dy), int(hr), int(mi), int(s), int(ms)) - t0py
        tdiff.append(diff_temp.total_seconds())

    tdiff_array = np.asarray(tdiff)
    return tdiff_array


def find_nearest(array, value):  # stolen from stackoverflow
    idx = np.searchsorted(array, value, side="left")
    if idx > 0 and (idx == len(array) or math.fabs(value - array[idx-1]) < math.fabs(value - array[idx])):
        return array[idx-1]
    else:
        return array[idx]


def contiguous_regions(condition):
    """Finds contiguous True regions of the boolean array "condition". Returns
    a 2D array where the first column is the start index of the region and the
    second column is the end index. Taken directly from stackoverflow:
    https://stackoverflow.com/questions/4494404/find-large-number-of-
    consecutive-values-fulfilling-condition-in-a-numpy-array"""

    # Find the indices of changes in "condition"
    d = np.diff(condition)
    idx, = d.nonzero()

    # We need to start things after the change in "condition". Therefore,
    # we'll shift the index by 1 to the right.
    idx += 1

    if condition[0]:
        # If the start of condition is True prepend a 0
        idx = np.r_[0, idx]

    if condition[-1]:
        # If the end of condition is True, append the length of the array
        idx = np.r_[idx, condition.size] # Edit

    # Reshape the result into two columns
    idx.shape = (-1, 2)
    return idx


def plot_pe_raster(spike_times, event_starts, buffer=1, event_ends=None, box_color=None, ax=None, spike_color='k'):
    """
    Plots peri-event rasters centered on event_starts.
    :param spike_times: (nspikes,) ndarray containing spike times in seconds
    :param event_starts: (nevent,) ndarray containing event times in seconds
    :param buffer: seconds to include before/after event start. Default = 1. Will extend from event end if that input is
     specified
    :param event_ends: (nevent,) ndarray containing event end times in seconds.
    :param spike_color: matplotlib color string or [r, g, b, a] list (a: 1 = opaque, 0 = transparent)
    :param box_color: matplotlib color string or [r, g, b, a] list (a: 1 = opaque, 0 = transparent)
    :param ax: axes to plot into, if None (default) will create a new figure.
    Will plot a box to overlay event start/end times.
    :return: axes
    """

    if ax is None: fig, ax = plt.subplots()  # Make new figure if no specified
    if event_ends is None: event_ends = event_starts  # set up arrays properly

    durations = event_ends - event_starts  # get event durations

    # Plot rasters
    for idn, start in enumerate(event_starts):
        spike_times_aligned = spike_times[np.bitwise_and(spike_times > (start - buffer),
                                                         spike_times < (event_ends[idn] + buffer))] - start

        ax.vlines(spike_times_aligned, idn, idn + 1, color=spike_color)  # plot each row of the raster

    # Add box if specified
    if box_color is not None:
        event_poly = np.concatenate((np.stack((durations, np.arange(1, len(durations) + 1)), axis=1),
                                     np.stack((np.zeros_like(durations), np.arange(len(durations), 0, -1)), axis=1)),
                                    axis=0)
        ax.add_patch(patches.Polygon(event_poly, closed=True, color=box_color))

    # Label axes
    ax.set_xlabel('Time from Event Start (s)')
    ax.set_ylabel('Trial #')

    return ax


def opto_boxplot(spike_times, on_times, off_times, buffer=None, ax=None, color_palette='Set2'):
    """
    Plot firing rates before/during/after optogentic stimulation period
    :param spike_times: (nspikes,) ndarray containing spike times in seconds
    :param on_times: (nstim,) ndarray containing light start times in seconds
    :param off_times: (nstim,) ndarray containing light end times in seconds
    :param buffer: seconds to include before/after stimulation. If None (default) uses a buffer the length of the light
    on period.
    :param ax: axes to plot into (Default = create new figure)
    :param color_palette: seaborn color palette to use ('Set2') by default (colorblind friendly)!
    :return:
    """

    sns.set_palette('Set2')  # set color palette
    if ax is None: fig, ax = plt.subplots()  # set up new axes if necessary

    # Set up buffer array
    if buffer is None:
        buffer = off_times - on_times
    else:
        buffer = buffer*np.ones_like(on_times)

    # Construct FR rate array for before/during/after light epochs
    FR = np.ones((1, 3))*np.nan  # pre-allocate FR array
    for idn, (on, off) in enumerate(zip(on_times, off_times)):
        nin = np.sum(np.bitwise_and(spike_times > on, spike_times < off))
        nbef = np.sum(np.bitwise_and(spike_times < on, spike_times > (on - buffer[idn])))
        naft = np.sum(np.bitwise_and(spike_times > off, spike_times < (off + buffer[idn])))
        FR = np.vstack((FR, [nbef/buffer[idn], nin/(off-on), naft/buffer[idn]]))

    sns.boxplot(data=FR, ax=ax, fliersize=0, saturation=0.35)
    sns.stripplot(data=FR, ax=ax, jitter=0.3)
    ax.set_xticklabels(['BEFORE', 'Light ON', 'AFTER'])
    ax.set_ylabel('FR (Hz)')

    # NRK Todo: run stats on FRs!
    stat, pval = stats.kruskal(FR[:, 0], FR[:, 1], FR[:, 2], nan_policy='omit')
    Pposthoc = sp.posthoc_dunn([FR[:, 0], FR[:, 1], FR[:, 2]], p_adjust='sidak')
    stat_dict = {'kw_stat': stat, 'kw_pval': pval, 'Dunn_posthoc': Pposthoc, 'correction': 'sidak'}

    # Draw quick stats lines for now
    # NRK Todo: print stats into another axis?
    ylim = ax.get_ylim()[-1]
    if pval < 0.05:
        p1, p2 = np.where(Pposthoc < 0.05)  # id
        for start, stop in zip(p1, p2):
            if start == 0 and stop == 2: yplot = ylim*0.95
            else: yplot = ylim*0.9
            if start < stop:
                ax.hlines(yplot, start + 0.1, stop - 0.1, color='k')
    else:
        ax.text(1, ylim - 5, 'n.s.')

    pretty_plot(ax, round_ylim=False)

    return ax, stat_dict


if __name__ == '__main__':


    pass