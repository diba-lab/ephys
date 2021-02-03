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
                 shock_dur=1, ITI=240, tone_freq=None, nshocks=6, volume=1.0):
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
        self.volume = volume

        # First connect to the Arduino - super important
        self.initialize_arduino(self.arduino_port)

        # Next create tone
        self.tone_samples = self.create_tone(tone_type=tone_type, duration=tone_dur, freq=tone_freq)
    
    def run_experiment(self, test=False):
        """Basic idea would be to run this AND write the timestamps for everything to a CSV file just in case."""
        if not test:
            ITIuse = [self.generate_ITI() for _ in range(0, self.nshocks)]
        elif test:  # generate 3 second ITI
            ITIuse = np.ones(self.nshocks)*3

        self.board.digital[self.video_io_pin].write(1)  # start video
        # NRK TODO: add in initial exploration time!
        for idt, ITIdur in enumerate(ITIuse):
            print('Starting trial ' + str(idt+1) + ' with ' + str(ITIdur) + ' second ITI')
            time.sleep(ITIdur)
            self.run_trial(test_run=test)
        self.board.digital[self.video_io_pin].write(0)  # experiment over
        
        if not test:
            self.ITIdata = ITIuse
        
        # NRK TODO: Pickle and save entire class as reference data for later. 
        # Best would be to track ALL timestamps for later reference just in case.
            
    def generate_ITI(self):
        return self.ITI + np.random.random_integers(low=-self.ITI_range, high=self.ITI_range)

    def run_trial(self, test_run):
        
        if not test_run:
            tone_use = self.tone_samples
            trace_dur_use = self.trace_dur
            shock_dur_use = self.shock_dur
        elif test_run:  # Run test with 1 second tone, 2 second trace, and 3 second shock
            tone_use = self.create_tone(tone_type=self.tone_type, duration=1, freq=self.tone_freq)
            trace_dur_use = 2
            shock_dur_use = 3

        tones.play_tone(tone_use, fs, volume)
        time.sleep(trace_dur_use)
        self.board.digital[self.shock_box_pin].write(1)  # signal to shock box
        self.board.digital[self.shock_io_pin].write(1)  # TTL to Intan or whatever other system you want
        time.sleep(shock_dur_use)
        self.board.digital[self.shock_box_pin].write(0)  # stop shock signal
        self.board.digital[self.shock_io_pin].write(0)  # TTL off to Intan or whatever other system you want


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
            tone_samples = tones.generate_white_noise(duration)
        else:
            tone_samples = None
        # elif tone_type == 'pure_tone':
        #     tone_samples = None
        # elif tone_type == 'tone_sweep':
        #     tone_samples = None
        return tone_samples
    
    @staticmethod
    def exp_parameters(self):
        print('Experiment set with ' + str(self.tone_dur) + ' second tone, ' 
        + str(self.trace_dur) + ' second trace, ' + str(self.shock_dur) + ' second shock, and '
        + str(self.ITI) + '+/-' + str(self.ITI_range) + ' second ITI')

    # def test_run():
    #     """Run this to quickly check that all components are working.
    #     20210202: should hear tone and see shock lights turn on.
    #     Future: will need to add in verification that TTL outs to acquisition system are working too."""
    
    

