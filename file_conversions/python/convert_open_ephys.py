### module to convert openephys files to read into various other programs (spyking-circus, neuroscope, etc.)

import numpy as np
import Python3.Binary as ob  # need to have openephys-tools github repository on path
import os
from glob import glob


def events2neuroscope(exp_folder, Processor='100', Experiment=1, Recording=1, TTLport=1):
    """
    convert events in event folder to .evt file for reading into Neuroscope
    :param exp_folder: full path to experiment folder
    :param Processor, Experiment, Recording: optional if you want to filter out only certain recordings... for now it only
    spits out data for experiment 1 and recording 1... Need to implement outputting all into one file...
    :param TTLport: TTL port where you are recording data
    :return: nothing - writes .evt file to same folder...
    """

    # event_data, timing_data = ob.LoadTTLEvents(exp_folder, TTLport=TTLport)  # load event data
    evt_folder = glob(os.path.join(exp_folder, 'experiment' + str(Experiment), 'recording' +
                                   str(Recording), 'events', '*', 'TTL_' + str(TTLport)))[0]  # get event folder

    # # extract variables
    # timestamps = event_data[Processor][str(Experiment - 1)][str(Recording - 1)]['timestamps']
    # states = event_data[Processor][str(Experiment - 1)][str(Recording - 1)]['channel_states']
    # start_time = int(timing_data[Processor][str(Experiment - 1)][str(Recording - 1)]['start_time'])
    # SR = int(timing_data[Processor][str(Experiment - 1)][str(Recording - 1)]['Rate'])

    event_times_ms, channel_states = events2ms(exp_folder, Processor=Processor, Experiment=Experiment,
                                               Recording=Recording, TTLport=TTLport)

    # write to the file
    file1 = open(os.path.join(evt_folder, 'Processor' + str(Processor) + 'ttl_events.TL' + str(TTLport) + '.evt'), 'w')
    file1.writelines([str(timestamp) + ' ' + str(state) + '\n' for timestamp, state in
                      zip(event_times_ms, channel_states)])  # Event times in milliseconds + TTL channel in...
    file1.close()

    return


def artifacts2circus(exp_folder, event_channel, exclude_times=[1, 1], Processor='100', Experiment=1, Recording=1, TTLport=1):
    """
    Creates file for excluding artifact times logged in OpenEphys TTL events during processing in spyking-circus. This produces
    a .dead file for EXCLUDING all data around artifacts rather than removing the artifact...
    :param exp_folder: full path to experiment folder
    :param event_channel: TTL channel associated with artifacts. By default include both on and off events.
    :param exclude_times: array of size (2,) with time in (ms) to exclude BEFORE and AFTER event times. Positive numbers only!
    :param Processor, Experiment, Recording: optional if you want to filter out only certain recordings... for now it only
    spits out data for experiment 1 and recording 1... Need to implement outputting all into one file...
    :param TTLport: TTL port where you are recording data
    :return: nothing. writes file to event folder. rows = events, columns = t_start t_stop (in ms)
    """

    # Extract event times and channels
    event_times_ms, channel_states = events2ms(exp_folder, Processor=Processor, Experiment=Experiment,
                                               Recording=Recording, TTLport=TTLport)

    evt_folder = glob(os.path.join(exp_folder, 'experiment' + str(Experiment), 'recording' +
                                   str(Recording), 'events', '*', 'TTL_' + str(TTLport)))[0]  # get event folder

    # ID artifact-associate events
    exclude_times_ms = event_times_ms[np.bitwise_or(channel_states == event_channel, channel_states == -event_channel)]

    # write header
    art_file = open(os.path.join(evt_folder, 'ttl_artifacts.dead'), 'w')
    art_file.writelines(['// Artifact file for folder: ' + evt_folder + '\n', '// event_channel = ' + str(event_channel) + '\n'])

    # Now write all the times
    art_file = open(os.path.join(evt_folder, 'ttl_artifacts.dead'), 'a')
    art_file.writelines([str(time - exclude_times[0]) + ' ' + str(time + exclude_times[1]) + '\n' for time in exclude_times_ms])
    art_file.close()

    return


def events2ms(exp_folder, Processor='100', Experiment=1, Recording=1, TTLport=1):
    """
    extract event times and convert to ms, with reference to recording start.
    :param exp_folder:
    :param Processor:
    :param Experiment:
    :param Recording:
    :param TTLport:
    :return: event_times_ms and channel_states: arrays of size (nevents,) with event timestamps in ms (0 = recording start time)
    and corresponding on/off channels.
    """

    event_data, timing_data = ob.LoadTTLEvents(exp_folder, TTLport=TTLport)  # load event data

    # extract variables
    timestamps = event_data[Processor][str(Experiment - 1)][str(Recording - 1)]['timestamps']
    channel_states = event_data[Processor][str(Experiment - 1)][str(Recording - 1)]['channel_states']
    start_time = int(timing_data[Processor][str(Experiment - 1)][str(Recording - 1)]['start_time'])
    SR = int(timing_data[Processor][str(Experiment - 1)][str(Recording - 1)]['Rate'])

    # calculate event times in ms referenced to recording start
    event_times_ms = (timestamps - start_time) / SR * 1000

    return event_times_ms, channel_states


if __name__ == '__main__':
     artifacts2circus(r'/data/Working/Opto Project/Rat 613/Rat613Day1/Rat613simtest_2020-08-01_08-47-11/', 2)














