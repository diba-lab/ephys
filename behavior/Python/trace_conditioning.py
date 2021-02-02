"""Class and functions for trace fear conditioning"""
import time
import tones
import pyfirmata
import numpy as np

tone_dur_default = 10  # seconds
trace_dur_default = 20  # seconds
shock_dur_default = 1  # seconds at 1mA
fs = 44100
volume = 1.0
ITI_range = 10  # +/- this many seconds for each ITI

class trace:
    def __init__(self, arduino_port='COM7', tone_type='white', tone_dur=10, trace_dur=20, 
                 shock_dur=1, ITI=240, tone_freq=None, nshocks=6):
        print('Initializing trace fc class with ' + str(tone_dur) + ' second tone, ' 
        + str(trace_dur) + ' second trace, and ' + str(shock_dur) + ' second shock')
        self.tone_dur = tone_dur
        self.trace_dur = trace_dur
        self.shock_dur = shock_dur
        self.tone_freq = tone_freq
        self.arduino_port = arduino_port
        self.tone_type = tone_type
        self.ITI = ITI
        self.ITI_range = ITI_range
        self.nshocks = nshocks

        # First connect to the Arduino - super important
        self.initialize_arduino(self.arduino_port)

        # Next create tone
        self.tone_samples = self.create_tone(tone_type=self.tone_type, duration=tone_dur, freq=tone_freq)
    
    def run_experiment(self):
        """Basic idea would be to run this AND write the timestamps for everything to a CSV file just in case."""
        ITIactual = []
        for trial in range(0, nshocks):
            ITIactual.append(self.generate_ITI)
            time.sleep(ITIactual[trial])
            tone_trace_shock
            
    def generate_ITI(self):
        return self.ITI + np.random.random_integers(low=-self.ITI_range, high=self.ITI_range)

    def tone_trace_shock(self):
        tones.play_tone(self.tone_samples, fs, volume)
        time.sleep(self.trace_dur)
        self.board.digital[self.shock_box_pin].write(1)
        time.sleep(self.shock_dur)
        self.board.digital[self.shock_box_pin].write(0)


    def initialize_arduino(self, port='COM7', shock_box_pin=2, shock_io_pin=7, video_io_pin=9):
        """20210202: No try/except for now because I want to see an error when setting things up for now!"""
        # try:
        self.board = pyfirmata.Arduino('COM7')
            
        # except FileNotFoundError:
        #     print('Error connecting to Arduino on ' + port)
        #     print('Check connections and port and run ""trace.initialize_arduino"" again')
        #     board = None
        self.shock_box_pin = shock_box_pin
        self.shock_io_pin = shock_io_pin
        self.video_io_pin = video_io_pin
        
    
    def create_tone(self, tone_type='white', duration=1.0, freq=None):
        """Create a pure tone, tone_sweep, or noise. 
        20210202: Only white noise working. freq input needs to be a float or list of floats for tone sweep"""
        if tone_type == 'white':
            tone_samples = tones.generate_white_noise(duration, fs)
        else:
            tone_samples = None
        # elif tone_type == 'pure_tone':
        #     tone_samples = None
        # elif tone_type == 'tone_sweep':
        #     tone_samples = None
        return tone_samples

    # def test_run():
    #     """Run this to quickly check that all components are working.
    #     20210202: should hear tone and see shock lights turn on.
    #     Future: will need to add in verification that TTL outs to acquisition system are working too."""
    
    

