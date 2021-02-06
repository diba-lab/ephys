"""Class and functions for trace fear conditioning.
General order of events:
0) Run trace.start_experiment()
1) Start USV recorder
2) Start webcam
3) Start Optitrack (Make sure TTL_out connected to video_io_pin on arduino!)"""
import time
import tones
import pyfirmata
import numpy as np
import sys
from pathlib import Path
import csv
from datetime import datetime

tone_dur_default = 10  # seconds
trace_dur_default = 20  # seconds
shock_dur_default = 1  # seconds at 1mA
fs = 44100
volume = 1.0
ITI_range = 20  # +/- this many seconds for each ITI


class trace:
    def __init__(
        self,
        arduino_port="COM7",
        tone_type="white",
        tone_dur=10,
        trace_dur=20,
        shock_dur=1,
        ITI=240,
        tone_freq=None,
        nshocks=6,
        volume=1.0,
        start_buffer=6 * 60,
        base_dir=Path.home(),
    ):
        print(
            "Initializing trace fc class with "
            + str(tone_dur)
            + " second tone, "
            + str(trace_dur)
            + " second trace, and "
            + str(shock_dur)
            + " second shock"
        )
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
        self.start_buffer = start_buffer  # seconds before 1st trial.
        self.base_dir = base_dir

        # First connect to the Arduino - super important
        self.initialize_arduino(self.arduino_port)

        # Next create tone
        self.tone_samples = self.create_tone(
            tone_type=tone_type, duration=tone_dur, freq=tone_freq
        )

    def run_training_session(self, test=False):
        """Runs training session."""

        if not test:
            ITIuse = [self.generate_ITI() for _ in range(0, self.nshocks)]

            # # start video if using trace class to trigger experiment start.
            # if not video_start:
            #     self.board.digital[self.video_io_pin].write(1)
            print("Initial exploration period started")
            self.write_event("start_exploration")
            sleep_timer(self.start_buffer)
            self.write_event("end_exploration")
        elif test:  # generate 3 second ITI
            ITIuse = np.ones(self.nshocks).astype("int") * 3

        for idt, ITIdur in enumerate(ITIuse):
            print("Starting trial " + str(idt + 1))

            # Run trial
            self.write_event("trial_" + str(idt) + "_start")
            self.run_trial(test_run=test)
            self.write_event("trial_" + str(idt) + "_end")

            # Run ITI
            print("Starting " + str(ITIdur) + " second ITI")
            self.write_event("ITI_" + str(idt) + "_start")
            sleep_timer(ITIdur)
            self.write_event("ITI_" + str(idt) + "_end")

        if not test:
            self.ITIdata = ITIuse

        # NRK TODO: save timestamps for all events to a .npy file? or a dict?

        # NRK TODO: Pickle and save entire class as reference data for later.
        # Best would be to track ALL timestamps for later reference just in case.

    def generate_ITI(self):
        return self.ITI + np.random.random_integers(
            low=-self.ITI_range, high=self.ITI_range
        )

    def start_experiment(self, session, test_run=False, force_start=False):
        """Starts running ALL experiments when video tracking starts.
        param: force_start: set to True if Optitrack crashes and you need to start manually"""
        assert session in [
            "pre",
            "training",
            "ctx_recall",
            "tone_recall",
        ]  # Make sure session is properly named
        if not test_run:
            self.session = session
        elif test_run:
            self.session = session + "_test"

        # Print update to screen
        if not force_start:
            print("Experiment initialized. Waiting for video triggering")
        else:
            print("Force starting experiment")

        # Now start once you get TTL to video i/o pin
        started = False
        while not started:
            if self.board.digital[self.video_io_pin].read() or force_start:
                print("Experiment triggered by video (or forced)!")
                self.start_time = time.time()
                self.start_datetime = datetime.now()
                self.csv_path = self.base_dir / (
                    self.session
                    + self.start_datetime.strftime("%m_%d_%Y-%H_%M_%S")
                    + ".csv"
                )  # Make csv file with start time appended
                self.write_event("video_start")  # write first line to csv
                if session == "training":
                    self.run_training_session(test=test_run)
                elif session in ["pre", "ctx_recall", "tone_recall"]:
                    self.write_event("start_sync_tone")
                    tones.play_flat_tone(
                        duration=0.5, f=700.0
                    )  # play tones for synchronization
                    self.write_event("end_sync_tone")
                started = True

    # NRK TODO: test force_start above!

    def run_trial(self, test_run):

        if not test_run:
            tone_use = self.tone_samples
            trace_dur_use = self.trace_dur
            shock_dur_use = self.shock_dur
        elif (
            test_run
        ):  # Run test with 1 second tone, 2 second trace, and 3 second shock
            tone_use = self.create_tone(
                tone_type=self.tone_type, duration=1, freq=self.tone_freq
            )
            trace_dur_use = 2
            shock_dur_use = 1

        # play tone
        self.write_event("tone_start")
        tones.play_tone(tone_use, fs, volume)
        self.write_event("tone_end")

        # start trace period
        print(str(trace_dur_use) + " sec trace period started")
        self.write_event("trace_start")
        sleep_timer(trace_dur_use)
        self.write_event("trace_end")

        # administer shock
        self.write_event("shock_start")
        self.board.digital[self.shock_box_pin].write(1)  # signal to shock box
        self.board.digital[self.shock_io_pin].write(1)  # TTL to Intan. Necessary?
        time.sleep(shock_dur_use)
        self.board.digital[self.shock_box_pin].write(0)  # stop shock signal
        self.board.digital[self.shock_io_pin].write(0)  # TTL off to Intan. Necessary?
        self.write_event("shock_end")

    def initialize_arduino(
        self,
        port="COM7",
        shock_box_pin=2,
        shock_io_pin=7,
        video_io_pin=9,
        video_start=True,
    ):
        """20210202: No try/except for now because I want to see an error when setting things up for now!
        Not sure shock_io_pin is entirely necessary - just send shock_box_pin to both shock box and open ephys"""
        # try:
        self.board = pyfirmata.Arduino(port)
        if video_start:
            # start iterator
            it = pyfirmata.util.Iterator(self.board)
            it.start()

            # set video_io_pin to read mode
            self.board.digital[video_io_pin].mode = pyfirmata.INPUT

        # except FileNotFoundError:
        #     print('Error connecting to Arduino on ' + port)
        #     print('Check connections and port and run ""trace.initialize_arduino"" again')
        #     board = None
        self.shock_box_pin = shock_box_pin
        self.shock_io_pin = shock_io_pin
        self.video_io_pin = video_io_pin

    def create_tone(self, tone_type="white", duration=1.0, freq=None):
        """Create a pure tone, tone_sweep, or noise.
        20210202: Only white noise working. freq input needs to be a float or list of floats for tone sweep"""
        if tone_type == "white":
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
        print(
            "Experiment set with "
            + str(self.tone_dur)
            + " second tone, "
            + str(self.trace_dur)
            + " second trace, "
            + str(self.shock_dur)
            + " second shock, and "
            + str(self.ITI)
            + "+/-"
            + str(self.ITI_range)
            + " second ITI"
        )

    def write_event(self, event_id):
        """Writes event and its timestamp to csv file"""
        write_csv(self.csv_path, time.time() - self.start_time, event_id)


def sleep_timer(duration):
    """Simple function to sleep AND display time remaining.
    Taken from user Barkles response at
    https://stackoverflow.com/questions/17220128/display-a-countdown-for-the-python-sleep-function"""
    for remaining in range(duration, 0, -1):
        sys.stdout.write("\r")
        sys.stdout.write("{:2d} seconds remaining.".format(remaining))
        sys.stdout.flush()
        time.sleep(1)
    sys.stdout.write("\rComplete!            \n")


def write_csv(filename, timestamp, event_id):
    "Write time of event and event_id (int or str) to csv file"

    # Create file with header if file does not exist
    if not filename.exists():
        with open(filename, "w", newline="") as csvfile:
            spamwriter = csv.writer(csvfile, delimiter=",")
            start_time = datetime.now()
            spamwriter.writerow(
                [
                    "Start time",
                    start_time.strftime("%m/%d/%Y, %H:%M:%S"),
                    "microseconds",
                    str(start_time.microsecond),
                ]
            )
            spamwriter.writerow(["Time (s)", "Event"])

    # Append timestamp and event id to a new row
    with open(filename, "a", newline="") as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=",")
        spamwriter.writerow([timestamp, event_id])


# NRK TODO: append timestamp to end of csv file so that you never overwrite things!

# NRK TODO: Figure out why play_tone for 1 second takes waaaay longer than 1 second. Probably need to initialize
# pyaudio stream first and keep it alive!  make it a better class!

# def test_run():
#     """Run this to quickly check that all components are working.
#     20210202: should hear tone and see shock lights turn on.
#     Future: will need to add in verification that TTL outs to acquisition system are working too."""
