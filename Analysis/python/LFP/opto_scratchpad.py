## Scratchpad for opto related analyses

import numpy as np
import Python3.Binary as ob

## Relevant folder/files
chan_map_file = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\2x32MINT_chan_map_good.txt'
data_folder = r'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\Rat613Day1\Rat613track_2020-08-01_09-21-55'
## Load Data!
chan_map_dict = ob.LoadChannelMapFromText(chan_map_file)
chans_use = np.hstack((np.arange(0, 8), np.arange(16, 24)))  # Use only shank 1 and shank 3
channels_use = [chan for chan in np.asarray(chan_map_dict['0']['mapping'])[chans_use]]
Data, Rate = ob.Load(data_folder, ChannelMap=channels_use, Experiment=2, Recording=1, mode='r')