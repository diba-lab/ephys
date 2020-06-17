"""Functions to compare different spike-sorting algorithms using SpikeInterface.
# Basically a bunch of wrapper functions for examples on the spikeinterace read-the-docs page:
# https://spikeinterface.readthedocs.io/en/latest/modules/comparison/plot_1_compare_two_sorters.html"""

import numpy as np
import matplotlib.pyplot as plt
import spikeinterface.extractors as se
import spikeinterface.comparison as sc
import spikeinterface.widgets as sw
from pathlib import Path


## Construct object to make easy comparisons between two different sorters

class CompareObject:
    def __init__(self, sort1dir, sort2dir, exclude_groups=[], SampleRate = 30000):
        """ Compares klusta to spyking-circus for now. Does NOT yet compare manually clustered data in Phy (2020MAY25).
        :param sort1dir: directory with klusta spike sorting files
        :param sort2dir: directory with spyking-circus sorting files
        :param exclude_groups: Phy unit classifications ['good','mua','noise','unsorted'] to exclude,
         (e.g. ['noise','unsorted'] will only include good units and multi-unit activity. default = 30000
        :param SampleRate in Hz. default = 30000
        """

        # Load in data
        self.sorting1, self.sort1name = load_sorted_data(sort1dir, exclude_groups)
        self.sorting2, self.sort2name = load_sorted_data(sort2dir, exclude_groups)
        self.SampleRate = SampleRate

        # Start out doing this for just Klusta and Spyking-Circus and Phy manually
        # self.sort1name = sort1name
        # self.sort2name = sort2name
        # self.sorting1 = se.KlustaSortingExtractor(sort1dir)
        # try:  # Look for spyking circus, if not there load phy folder
        #     self.sorting2 = se.SpykingCircusSortingExtractor(sort2dir)
        # except AssertionError:
        #     self.sorting2 = se.PhySortingExtractor(sort2dir)
        #     self.sort2name = 'Phy manual clustering'

        self.cmp_sorters = sc.compare_two_sorters(sorting1=self.sorting1, sorting2=self.sorting2,
                                                  sorting1_name=self.sort1name, sorting2_name=self.sort2name)

    # Plot agreement matrix
    def plot_agreement_matrix(self):
        sw.plot_agreement_matrix(self.cmp_sorters)

    # Plot rasters for all mapped cells
    def plot_mapped_rasters(self):
        mapped_sorting1 = self.cmp_sorters.get_mapped_sorting1()  # units matched to sorter 1
        mapped_sorting2 = self.cmp_sorters.get_mapped_sorting2()  # units matched to sorter 2

        # find units from sorter1 that were matched to sorter2
        mapped_inds = [int(a) for a in np.where(np.array(mapped_sorting1.get_mapped_unit_ids()) != -1)[0]]  #sorter1 indices that are mapped
        units1 = [self.sorting1.get_unit_ids()[a] for a in mapped_inds]   # unit ids in sorter1
        units2 = [mapped_sorting1.get_mapped_unit_ids()[a] for a in mapped_inds]  # unit ids in sorter2

        # compare spike trains
        figs = []
        ax = []
        for unit1, unit2 in zip(units1, units2):
            st1 = self.sorting1.get_unit_spike_train(unit1)
            st2 = mapped_sorting1.get_unit_spike_train(unit1)
            ax.append(plot_matched_rasters(st1, st2, st1name=self.sort1name + ' Unit ' + str(unit1),
                                           st2name=self.sort2name + ' Unit ' + str(unit2), SampleRate=self.SampleRate))

        self.mapped_raster_axes = ax


def plot_matched_rasters(spike_train1, spike_train2, st1name='sorter1', st2name='sorter2', SampleRate=30000):
    fig, ax = plt.subplots()
    fig.set_size_inches([24, 5])
    ax.plot(spike_train1/SampleRate, np.zeros(spike_train1.size), '|')
    ax.plot(spike_train2/SampleRate, np.ones(spike_train2.size), '|')
    ax.set_ylim([-3, 4])
    ax.set_yticks([0, 1])
    ax.set_yticklabels([st1name, st2name])

    return ax


def load_sorted_data(sortdir, exclude_groups):
    """Helper function to load sorted data directly from Klusta, Spyking-Circus, or even from Phy after cleanup"""

    sorterlist = ['KlustaSortingExtractor', 'SpykingCircusSortingExtractor', 'PhySortingExtractor']
    sorternames = ['Klusta', 'Spy. Circ', 'Phy']
    for sortername, extractor in zip(sorternames, sorterlist):
        try:  # try to load each sorter
            sorting = getattr(se, extractor)(sortdir)
            sorting_name = sortername
            # Iterate through parent directories to identify auto-sorter used before manual clustering in Phy.
            if extractor is 'PhySortingExtractor':
                if any([f_.suffix == '.hdf5' for f_ in Path(sortdir).parent.iterdir()]):
                    sorting_name = 'Spy. Circ. + Phy'
                elif any([f_.suffix == '.kwik' for f_ in Path(sortdir).parent.iterdir()]):
                    sorting_name = 'Klusta + Phy'

                else:
                    sorting_name = 'Phy + ? Auto-Clusterer'

                sorting = getattr(se, extractor)(sortdir, exclude_cluster_groups=exclude_groups)

            break
        except AssertionError:  # Only send an error if you encounter a different error
            # (We expect to get this error if you try the wrong sorter).
            continue

    return sorting, sorting_name