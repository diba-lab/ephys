## Scratchpad for opto related analyses

import numpy as np
import Python3.Binary as ob
import numpy as np
import matplotlib.pyplot as plt
import os

## Relevant folder/files
chan_map_file = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\2x32MINT_chan_map_good.txt'
data_folder = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\Rat613Day1\Rat613track_2020-08-01_09-21-55'
## Load Data!
chan_map_dict = ob.LoadChannelMapFromText(chan_map_file)
chans_use = np.hstack((np.arange(0, 8), np.arange(16, 24)))  # Use only shank 1 and shank 3
channels_use = [chan for chan in np.asarray(chan_map_dict['0']['mapping'])[chans_use]]
Data, Rate = ob.Load(data_folder, ChannelMap=channels_use, Experiment=2, Recording=1, mode='r')

## Look at silencing for Jackie place stim day 2
adc_channel = 35  # channel with adc input
on_thresh = 1000000 # on voltage threshold
base_dir = r'C:\Users\Nat\Documents\UM\Working\Opto\Jackie671\placestim_day2\PRE'
spike_folder = 'Jackie_pre_2020-10-07.GUI'
raw_folder = 'Jackie_PRE_2020-10-07_10-48-13'
full_raw_path = r'C:\Users\Nat\Documents\UM\Working\Opto\Jackie671\placestim_day2\PRE\Jackie_PRE_2020-10-07_10-48-13\experiment1\recording1\continuous\Intan_Rec._Controller-100.0'
data_ds = np.load(full_raw_path)

timestamps = np.load(os.path.join(full_raw_path, 'timestamps.npy'))
time_ds = timestamps[0:-1:24]

on_times = np.where(data_ds[adc_channel] > on_thresh)
off_times = np.where(data_ds < on_thresh)