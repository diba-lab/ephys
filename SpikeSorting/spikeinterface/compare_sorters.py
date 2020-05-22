"""Functions to compare different spike-sorting algorithms using SpikeInterface.
# Basically a bunch of wrapper functions for examples on the spikeinterace read-the-docs page:
# https://spikeinterface.readthedocs.io/en/latest/modules/comparison/plot_1_compare_two_sorters.html"""

import numpy as np
import matplotlib.pyplot as plt
import spikeinterface.extractors as se
import spikeinterface.comparison as sc
import spikeinterface.widgets as sw


## Construct object to make easy comparisons between two different sorters

class CompareObject:
    def __init__(self, sort1dir, sort2dir, sort1name='Klusta', sort2name='Spy. Circ.', SampleRate = 30000):
        """ Compares klusta to spyking-circus for now
        :param sort1dir: directory with klusta spike sorting files
        :param sort2dir: directory with spyking-circus sorting files
        """
        # Start out doing this for just Klust and Spyking-Circus
        self.sort1name = sort1name
        self.sort2name = sort2name
        self.SampleRate = SampleRate
        self.sorting1 = se.KlustaSortingExtractor(sort1dir)
        self.sorting2 = se.SpykingCircusRecordingExtractor(sort2dir)
        self.cmp_sorters = sc.compare_two_sorters(sorting1=self.sorting1, sorting2=self.sorting2,
                                                  sorting1_name=sort1name, sorting2_name=sort2name)

    # Plot agreement matrix
    def plot_agreement_matrix(self):
        sw.plot_agreement_matrix(self.cmp_sorters)

    # Plot rasters for all mapped cells
    def plot_mapped_rasters(self):
        mapped_sorting1 = self.cmp_sorters.get_mapped_sorting1()  # units matched to sorter 1
        mapped_sorting2 = self.cmp_sorters.get_mapped_sorting2()  # units matched to sorter 2

        # find units from sorter1 that were matched to sorter2
        inds1 = np.where(np.array(mapped_sorting1.get_mapped_unit_ids()) != 1)[0]  #sorter1 indices
        inds2 = self.sorting1.get_unit_ids()[inds1]

        # compare spike trains
        figs = []
        ax = []
        for ind2 in inds2:
            st1 = self.sorting1.get_unit_spike_train(ind2)
            st2 = mapped_sorting1.get_unit_spike_train(ind2)
            ax.append(plot_matched_rasters(st1, st2, st1name=self.sort1name, st2name=self.sort2name),
                      SampleRate=self.SampleRate)


def plot_matched_rasters(spike_train1, spike_train2, st1name='sorter1', st2name='sorter2', SampleRate=30000):
    fig, ax = plt.subplots()
    fig.set_size_inches([24, 5])
    ax.plot(spike_train1/SampleRate, np.zeros(spike_train1.size), '|')
    ax.plot(spike_train2/SampleRate, np.ones(spike_train2.size), '|')
    ax.set_ylim([-1, 3])
    ax.set_yticks([0, 1])
    ax.set_yticklabels([st1name, st2name])

    return ax