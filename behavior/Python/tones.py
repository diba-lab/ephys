"""Set of functions to play tones, tone sweeps, and white/brown/pink noise. Should I make it into a class?
"""

import pyaudio
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# Keep this up top for now, can easily put into a function later if it seems like I need to do so...
fs = 20100  # sampling rate, Hz, must be integer


class tones:
    """Class to play tones/noise.  Initializes with a 1 second 400 Hz tone and 10 second white noise ready to go."""

    def __init__(self, tone_duration=1.0, tone_f=1200, white_noise_duration=10):
        self.tone_duration = tone_duration
        self.tone_f = tone_f
        self.white_noise_duration = white_noise_duration

        self.p, self.stream = initialize_player(channels=1, rate=fs)

        # self.generate_pure_tone(self.tone_duration, self.tone_f)

    def generate_pure_tone(self):
        self.pure_tone_samples = generate_pure_tone(self.tone_duration, self.tone_f)

    def generate_white_noise(self):
        self.white_noise_samples = generate_white_noise(self.white_noise_duration)

    def play_flat_tone(self, volume=1.0):
        play_flat_tone(
            stream=self.stream,
            duration=self.tone_duration,
            f=self.tone_f,
            volume=volume,
        )

    def play_white_noise(self, volume=1.0):
        play_white_noise(
            duration=self.white_noise_duration, volume=volume, stream=self.stream
        )


def initialize_player(channels, rate):
    p = pyaudio.PyAudio()

    # for paFloat32 sample values must be in range [-1.0, 1.0]
    stream = p.open(format=pyaudio.paFloat32, channels=channels, rate=rate, output=True)

    return p, stream


def play_tone(stream, samples, volume):
    """Generic function to play tone specified in samples array on pre-defined pyaudio stream
    :param: samples = array to play
    :param: fs = sampling rate
    :param: volume = 0 to 1.0"""

    # p = pyaudio.PyAudio()
    #
    # # for paFloat32 sample values must be in range [-1.0, 1.0]
    # stream = p.open(format=pyaudio.paFloat32, channels=1, rate=fs, output=True)

    # play. May repeat with different volume values (if done interactively)
    stream.write((volume * samples).tobytes())

    # stream.stop_stream()
    # stream.close()

    # p.terminate()
    #
    # return p


def generate_pulse_tone(duration, f, fp):
    """Generate a pure tone with underlying frequency f that pulses at frequency fp"""
    return (np.sin(2 * np.pi * np.arange(fs * duration) * f / fs) *
            np.sin(np.pi * np.arange(fs * duration) * fp / fs)).astype(np.float32)


def generate_pure_tone(duration, f):
    return (np.sin(2 * np.pi * np.arange(fs * duration) * f / fs)).astype(
        np.float32
    )  # note conversion to float32 array


def play_flat_tone(duration=10.0, f=700.0, volume=1.0, fp=None, stream=None, plot=False):
    """Play a flat tone at a certain frequency f. Pulses at frequency fp if specified"""
    # duration = 1.0   # in seconds, may be float
    # f = 700.0        # sine frequency, Hz, may be float

    close_stream = False
    if stream is None:
        p, stream = initialize_player(channels=1, rate=fs)
        close_stream = True

    # generate samples for tone
    if fp is None:
        samples = generate_pure_tone(duration, f)
    else:  # generate pulsed tone if fp is specified.
        samples = generate_pulse_tone(duration, f, fp)
    # play tone
    play_tone(stream, samples, volume)

    # close player if not pre-initialized
    if close_stream:
        p.terminate()

    # plot tone trace and frequency spectrum if specified
    if plot:
        fig, ax = plt.subplots(1, 2)
        fig.set_size_inches([12, 4])
        sns.lineplot(x=np.linspace(0, duration, len(samples)), y=samples, ax=ax[0])
        ax[0].set_xlabel("Time (s)")
        ax[0].set_ylabel("Amplitude")


def play_tone_sweep(duration=1.0, freq_start=400, freq_end=700, volume=1.0):
    """Generates a tone sweep. Note that inputs are different than "play_flat_tone"""


def generate_white_noise(duration):
    """Generate gaussian white noise"""
    noise = np.random.normal(
        loc=0, scale=1, size=np.round(duration * fs, 0).astype("int")
    ).astype(np.float32)

    return noise


def play_white_noise(duration, volume=1.0, stream=None):
    if stream is None:
        p, stream = initialize_player(channels=1, rate=fs)

    noise = generate_white_noise(duration)
    play_tone(stream, noise, volume)


def pitch_to_freq(pitch):
    """Convert pitch from a piano key to the appropriate frequency"""
    return 2 ** ((pitch - 49) / 12) * 440


def freq_to_pitch(freq):
    """Convert frequency to a piano key pitch.
    Note that the input to play_tone_sweep and play_tone uses pitch-40 as an input!!!"""
    pitch_piano = 12 * np.log2(freq / 440) + 49
    return pitch_piano


# def play_color():

# Test run when importing to ensure speaker is hooked up!
print("Playing a quick 400Hz tone - check speaker setup if you don" "t hear it!")
play_flat_tone(duration=0.5, f=400)

# NRK Todo: 1) Make all pure tones and sweeps use pysinewave and same inputs (frequencies)
