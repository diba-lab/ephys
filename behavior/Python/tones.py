"""Set of functions to play tones, tone sweeps, and white/brown/pink noise. Should I make it into a class?
"""

import pyaudio
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# Keep this up top for now, can easily put into a function later if it seems like I need to do so...
fs = 44100       # sampling rate, Hz, must be integer

def play_tone(samples, fs, volume):
    """Generic function to play tone specified in samples array
    :param: samples = array to play
    :param: fs = sampling rate
    :param: volumne = 0 to 1.0"""

    p = pyaudio.PyAudio()

    # for paFloat32 sample values must be in range [-1.0, 1.0]
    stream = p.open(format=pyaudio.paFloat32,
                channels=1,
                rate=fs,
                output=True)

    # play. May repeat with different volume values (if done interactively) 
    stream.write((volume * samples).tobytes())

    stream.stop_stream()
    stream.close()

    p.terminate()

    return p

def play_flat_tone(duration=10.0, f=700.0, volume=1.0, plot=False):
    """Play a flat tone at a certain frequency"""
    # duration = 1.0   # in seconds, may be float
    # f = 700.0        # sine frequency, Hz, may be float

    # generate samples, note conversion to float32 array
    samples = (np.sin(2*np.pi*np.arange(fs*duration)*f/fs)).astype(np.float32)

    play_tone(samples, fs, volume)

    # plot tone trace and frequency spectrum if specified
    if plot:
        fig, ax = plt.subplots(1,2)
        fig.set_size_inches([12, 4])
        sns.lineplot(x=np.linspace(0, duration, len(samples)), y=samples, ax=ax[0])
        ax[0].set_xlabel('Time (s)')
        ax[0].set_ylabel('Amplitude')


def play_tone_sweep(duration=1.0, freq_start=400, freq_end=700, volume=1.0):
    """Generates a tone sweep. Note that inputs are different than "play_flat_tone"""
    

def generate_white_noise(duration, fs):
    """Generate gaussian white noise"""
    noise = np.random.normal(loc=0, scale=1, size=np.round(duration*fs,0).astype('int'))

    return noise

def pitch_to_freq(pitch):
    """Convert pitch from a piano key to the appropriate frequency"""
    return 2**((pitch - 49)/12) * 440

def freq_to_pitch(freq):
    """Convert frequency to a piano key pitch. 
    Note that the input to play_tone_sweep and play_tone uses pitch-40 as an input!!!"""
    pitch_piano = 12 * np.log2(freq/440) + 49
    return pitch_piano

# def play_color():

play_flat_tone(duration=0.25, f=400)

# NRK Todo: 1) Make all pure tones and sweeps use pysinewave and same inputs (frequencies)
# 2) Create white-noise generator - base it off of the pysinesave architecture if possible
# 3) Create shock-box class: start/stop shock box. Maybe this is a more general arduino class?
# 4) Create parent class to coordinate timing.