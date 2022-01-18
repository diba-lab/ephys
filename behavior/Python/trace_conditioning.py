"""Class and functions for trace fear conditioning.
General order of events:
0) Run trace.trace()
1) Start USV recorder
2) Start webcam
3) run trace.start_experiment()
4) Start Optitrack (Make sure TTL_out connected to video_io_pin on arduino!)"""
import time
import tones
import pyfirmata
import numpy as np
import sys
from pathlib import Path
import csv
from datetime import datetime
import atexit

tone_dur_default = 10  # seconds
trace_dur_default = 20  # seconds
shock_dur_default = 1  # seconds at 1mA
fs = 44100
ITI_range = 20  # +/- this many seconds for each ITI

# Define dictionaries for experimental parameters
# Keep the original params from Gilmartin2013 here for reference - used a different scheme (CSshort and CSlong) vs CS1, CS2 ...
params_archive = {
    "Gilmartin2013": {
        "alias": "Pilot1",
        "recall_params": {
            "baseline_time": 120,
            "CSshort": 10,
            "ITI": 120,
            "ITI_range": 0,
            "CSlong": 300,
            "start_buffer": 6 * 60,
        },
        "training_params": {
            "tone_dur": 10,
            "trace_dur": 20,
            "shock_dur": 1,
            "ITI": 240,
            "ITI_range": 20,
            "nshocks": 6,
        },
    }
}

# Here's the updated list
params = {
    "Pilot1": {
        "alias": "Gilmartin2013",
        "tones": {
            "training": {
                "type": "white",
                "duration": 10,
                "fp": None,
                "f": "white",
            },
            "control": None,
        },
        "training_params": {
            "tone_use": "training",
            "tone_dur": 10,
            "trace_dur": 20,
            "shock_dur": 1,
            "ITI": 240,
            "ITI_range": 20,
            "nshocks": 6,
            "start_buffer": 6 * 60,
        },
        "recall_params": {
            "baseline_time": 120,
            "CStimes": [10, 300],
            "ITI": 120,
            "ITI_range": 0,
        },
    },
    "Pilot2": {
        "alias": "Pilot2",
        "tones": {
            "training": {
                "type": "white",
                "duration": 10,
                "fp": None,
                "f": "white",
            },
            "control": None,
        },
        "training_params": {
            "tone_use": "training",
            "tone_dur": 10,
            "trace_dur": 20,
            "shock_dur": 1,
            "ITI": 240,
            "ITI_range": 20,
            "nshocks": 6,
            "start_buffer": 6 * 60,
        },
        "recall_params": {
            "baseline_time": 180,
            "CStimes": [10, 10, 10, 10, 10, 10],
            "ITI": 60,
            "ITI_range": 10,
        },
    },
    "Pilot2test": {
        "alias": "Pilot2",
        "tones": {
            "training": {
                "type": "white",
                "duration": 3,
                "fp": None,
                "f": "white",
            },
            "control": None,
        },
        "training_params": {
            "tone_use": "training",
            "tone_dur": 3,
            "trace_dur": 2,
            "shock_dur": 1,
            "ITI": 5,
            "ITI_range": 1,
            "nshocks": 6,
            "start_buffer": 6,
        },
        "recall_params": {
            "baseline_time": 12,
            "CStimes": [3, 3, 3, 3, 3, 3],
            "ITI": 3,
            "ITI_range": 1,
        },
    },
    "Round3": {
        "alias": "Round3",
        "tone": {
            "training": {
                "type": "pure_tone",
                "f": 7000,
                "fp": 10,
                "duration": 10,
            },
            "control": {
                "type": "pure_tone",
                "f": 1000,
                "fp": None,
                "duration": 10,
            },
        },
        "ctx_recall_params": {
            "duration": 15,
        },
        "tone_habituation_params": {
            "baseline_time": 60,
            "tone_use": "control",
            "volume": 0.06,
            "tone_dur": 10,
            "CStimes": None,
            "nCS": 15,
            "ITI": 60,
            "ITI_range": 10,
        },
        "training_params": {
            "tone_use": "training",
            "tone_dur": 10,
            "volume": 0.55,
            "trace_dur": 20,
            "shock_dur": 1,
            "ITI": 240,
            "ITI_range": 20,
            "nshocks": 6,
            "start_buffer": 6 * 60,
        },
        "tone_recall_params": {
            "tone_use": "training",
            "volume": 1,
            "baseline_time": 60,
            "CStimes": None,
            "nCS": 15,
            "ITI": 60,
            "ITI_range": 10,
            "end_tone": "control",
            "end_volume": 0.03,
            "nCS_end": 0,
        },
        "control_tone_recall_params": {
            "tone_use": "control",
            "volume": 0.03,
            "baseline_time": 60,
            "CStimes": None,
            "nCS": 15,
            "ITI": 60,
            "ITI_range": 10,
            "end_tone": "training",
            "end_volume": 0.7,
            "nCS_end": 0,
        },
    },
    "Misc": {
        "alias": "Misc",
        "training_params": {"tone_dur": 10},
        "ctx+tone_recall_params": {
            "baseline_time": 8 * 60,
            "CStimes": [10],
            "ITI": 120,
            "ITI_range": 0,
        },
    },
}

default_port = {
    "linux": "/dev/ttyACM0",
    "windows": "COM7",
}


class Trace:
    def __init__(
        self,
        arduino_port="COM6",
        paradigm="Round3",
        volume=1.0,
        base_dir=r'F:\Nat\Trace_FC\Recording_Rats\Finn',
    ):
        assert paradigm in params.keys()
        assert Path(base_dir).exists(), "Base path does not exist - create directory!"
        self.params = params[paradigm]
        print(
            "Initializing trace fc class with "
            + str(self.params["alias"])
            + " parameters"
        )
        self.arduino_port = arduino_port
        self.volume = volume
        self.base_dir = Path(base_dir)
        self.p, self.stream = tones.initialize_player(channels=1, rate=fs)
        self.csv_path = None

        # # First connect to the Arduino - super important
        # self.initialize_arduino(self.arduino_port)

        # Next create tone for training
        # NRK change this to CS+, change other below to CS-
        self.tone_samples = self.create_tone(
            f=self.params["tone"]["training"]["f"],
            duration=self.params["tone"]["training"]["duration"],
            fp=self.params["tone"]["training"]["fp"],
        )

        if self.params["tone"]["control"] is not None:
            self.control_tone_samples = self.create_tone(
                f=self.params["tone"]["control"]["f"],
                duration=self.params["tone"]["control"]["duration"],
                fp=self.params["tone"]["control"]["fp"],
            )

    def run_training_session(self, test=False):
        """Runs training session."""
        training_params = self.params["training_params"]
        if not test:
            ITIuse = [
                self.generate_ITI(training_params["ITI"], training_params["ITI_range"])
                for _ in range(0, training_params["nshocks"])
            ]

            # # start video if using trace class to trigger experiment start.
            # if not video_start:
            #     self.board.digital[self.video_io_pin].write(1)
            print("Initial exploration period started")
            self.write_event("start_exploration")
            sleep_timer(training_params["start_buffer"])
            self.write_event("end_exploration")
        elif test:  # generate 3 second ITI
            ITIuse = np.ones(training_params["nshocks"]).astype("int") * 3

        for idt, ITIdur in enumerate(ITIuse):
            print("Starting trial " + str(idt + 1))

            # Run trial
            self.write_event("trial_" + str(idt + 1) + "_start")
            self.run_trial(test_run=test, trial=idt + 1)
            self.write_event("trial_" + str(idt + 1) + "_end")

            # Run ITI
            print("Starting " + str(ITIdur) + " second ITI")
            self.write_event("ITI_" + str(idt + 1) + "_start")
            sleep_timer(ITIdur)
            self.write_event("ITI_" + str(idt + 1) + "_end")

        if not test:
            self.ITIdata = ITIuse

    def run_tone_recall(self):
        """Run tone recall or habituation session using params in specified paradigm"""

        # Grab correct parameters
        recall_params = self.params[self.session + "_params"]
        tone_type = recall_params["tone_use"]
        tone_dur = self.params["tone"][tone_type]["duration"]

        # Fill in CS times for code below, kept as is for backwards compatibility with earlier Pilots
        if recall_params["CStimes"] is None:
            recall_params["CStimes"] = [tone_dur for _ in range(recall_params["nCS"])]

        # Next, create tones
        tones_use = [
            self.create_tone(
                f=self.params["tone"][tone_type]["f"], duration=self.params["tone"][tone_type]["duration"],
                fp=self.params["tone"][tone_type]["fp"],
            )
            for _ in recall_params["CStimes"]
        ]

        # Last, create probe tones at end if specified
        play_end = False
        if "nCS_end" in recall_params:
            if recall_params["nCS_end"] > 0:
                play_end=True
                end_tone_type = recall_params["end_tone"]
                end_tone_dur = self.params[end_tone_type]["duration"]
                recall_params["CStimes_end"] = [end_tone_dur for _ in range(recall_params["nCS_end"])]
                end_tones_use = [
                    self.create_tone(
                        f=self.params["tone"][end_tone_type]["f"],
                        duration=self.params["tone"][end_tone_type]["duration"],
                        fp=self.params["tone"][end_tone_type]["fp"],
                    ) for _ in range(recall_params["nCS_end"])]
                end_ITIuse = [
                    self.generate_ITI(recall_params["ITI"], recall_params["ITI_range"])
                    for _ in range(recall_params["nCS_end"])]

        # Last, generate ITIs
        ITIuse = [
            self.generate_ITI(recall_params["ITI"], recall_params["ITI_range"])
            for _ in recall_params["CStimes"]
        ]

        # Start with baseline exploration period
        baseline_time = recall_params["baseline_time"]
        print("Starting " + str(baseline_time) + " sec baseline exploration period")
        self.write_event("baseline_start")
        sleep_timer(baseline_time)
        self.write_event("baseline_end")

        # Now start playing the tone!
        for idt, (tone, CStime, ITIdur) in enumerate(
            zip(tones_use, recall_params["CStimes"], ITIuse)
        ):
            print("Starting trial " + str(idt + 1))
            print(str(CStime) + " sec tone playing now")
            self.write_event("CS" + str(idt + 1) + "_start")
            self.board.digital[self.CS_pin].write(1)
            tones.play_tone(self.stream, tone, self.volume)
            self.board.digital[self.CS_pin].write(0)
            self.write_event("CS" + str(idt + 1) + "_end")

            print(str(ITIdur) + " sec ITI starting now")
            sleep_timer(ITIdur)

        if play_end:
            for idt, (endtone, endCStime, endITIdur) in enumerate(
                    zip(end_tones_use, recall_params["CStimes_end"], end_ITIuse)
            ):
                print("Starting end trial " + str(idt + 1))
                print(str(endCStime) + " sec tone playing now")
                self.write_event("CS_end_" + str(idt + 1) + "_start")
                self.board.digital[self.CS_pin].write(1)
                tones.play_tone(self.stream, endtone, self.volume)
                self.board.digital[self.CS_pin].write(0)
                self.write_event("CS_end_" + str(idt + 1) + "_end")

                print(str(endITIdur) + " sec ITI starting now")
                sleep_timer(endITIdur)

    def run_tone_recall_archive(
        self, baseline_time=120, CSshort=10, ITI=120, CSlong=300
    ):
        """Run tone recall session with baseline exploration time, short CS, ITI, and long CS - legacy from first version
        of class for Pilot1(Gilmartin2013) only"""
        self.tone_recall_params = {
            "baseline_time": baseline_time,
            "CSshort": CSshort,
            "ITI": ITI,
            "CSlong": CSlong,
        }

        CStone_short = self.create_tone(
            tone_type=self.tone_type, duration=CSshort, freq=self.tone_freq
        )

        CStone_long = self.create_tone(
            tone_type=self.tone_type, duration=CSlong, freq=self.tone_freq
        )

        print("Starting " + str(baseline_time) + " sec baseline exploration period")
        self.write_event("baseline_start")
        sleep_timer(baseline_time)
        self.write_event("baseline_end")

        print(str(CSshort) + " sec short tone playing now")
        self.write_event("CSshort_start")
        tones.play_tone(self.stream, CStone_short, self.volume)
        self.write_event("CSshort_end")

        print(str(ITI) + " sec ITI starting now")
        sleep_timer(ITI)

        print(str(CSlong) + " sec long tone playing now")
        self.write_event("CSlong_start")
        tones.play_tone(self.stream, CStone_long, self.volume)
        self.write_event("CSlong_end")

        print("Final 1 minute exploration period starting now")
        self.write_event("final_explore_start")
        sleep_timer(60)
        self.write_event("final_explore_end")

    def generate_ITI(self, ITI, ITI_range):
        return ITI + np.random.random_integers(low=-ITI_range, high=ITI_range)

    def send_recording_sync(self, length_min):
        """Send sync signal out to recording system(s)"""

        self.initialize_arduino()
        print("Sending recording sync signal")
        self.board.digital[self.record_sync_pin].write(1)

        # Now sleep until recording length has elapsed
        sleep_timer(length_min)

        # End signal
        self.board.digital[self.record_sync_pin].write(1)

    def start_experiment(self, session, test_run=False, force_start=False):
        """Starts running ALL experiments when video tracking starts.
        param: force_start: set to True if Optitrack crashes and you need to start manually"""
        assert session in [
            "pre",
            "post",
            "tone_habituation",
            "habituation",
            "training",
            "ctx_recall",
            "tone_recall",
            "ctx+tone_recall",
            "control_tone_recall"
        ]  # Make sure session is properly named
        if not test_run:
            self.session = session
        elif test_run:
            self.session = session + "_test"

        # First connect to the Arduino - super important
        print("Initializing arduino")
        video_start_bool = not force_start
        self.initialize_arduino(self.arduino_port, video_start=video_start_bool)

        # Print update to screen
        if not force_start:
            print("Experiment initialized. Waiting for video triggering")
        else:
            print("Force starting experiment")
            self.board.digital[self.video_io_pin].write(1)  # write to video pin

        # Now set up while loop to start once you get TTL to video i/o pin
        started = False
        while not started:
            if self.board.digital[self.video_io_pin].read() or force_start:
                print("Experiment triggered by video (or forced)!")
                self.board.digital[self.record_sync_pin].write(1)
                self.start_time = time.time()
                self.start_datetime = datetime.now()
                self.csv_path = self.base_dir / (
                    self.session
                    + self.start_datetime.strftime("%m_%d_%Y-%H_%M_%S")
                    + ".csv"
                )  # Make csv file with start time appended

                # play tones for synchronization
                self.write_event("start_sync_tone")
                tones.play_flat_tone(duration=0.5, f=500.0, volume=0.3)
                self.write_event("end_sync_tone")

                self.write_event(
                    "video_start"
                )  # write first line to csv - note this is off - should be same as start tone time.
                if session == "training":
                    self.run_training_session(test=test_run)
                elif session in [
                    "pre",
                    "habituation",
                    "tone_habituation",
                    "post",
                    "ctx_recall",
                    "tone_recall",
                    "ctx+tone_recall",
                ]:
                    if session in ["tone_recall", "ctx+tone_recall", "control_tone_recall", "tone_habituation"]:
                        self.run_tone_recall()
                    elif session == "ctx_recall":
                        if "ctx_recall_params" in self.params:
                            duration = self.params["ctx_recall_params"]["duration"]
                        else:
                            duration = 10
                        print("Starting context recall session")
                        self.write_event("ctx_explore_start")
                        sleep_timer(60 * duration)
                        self.write_event("ctx_explore_end")
                else:
                    print('Specified session not in code - double check!')

                started = True  # exit while loop after this!
            # elif KeyboardInterrupt:
            #     print("Interrupted by keyboard - closing arduino")
            #     self.board.exit()
            #     print("Trying to re-initialize arduino")
            #     self.initialize_arduino()

            # maybe this helps prevent arduino stop reading inputs on Windows after awhile?
            time.sleep(0.01)

        # close down arduino to prevent Iterator error on Windows machines.
        shutdown_arduino(self.board)

    # NRK TODO: Pickle and save entire class as reference data for later.
    # Best would be to track ALL timestamps for later reference just in case.

    # NRK TODO: save info for experiment run in a dict for later! Could initialize with session name or day name?

    # NRK TODO: make sure you list all relevant variables for each experiment in a dict.

    # NRK TODO: Make trace.run_tone_recall() input consistent - keep at top during initialization?

    def run_trial(self, test_run, trial=""):

        if not test_run:
            tone_use = self.tone_samples
            trace_dur_use = self.params["training_params"]["trace_dur"]
            shock_dur_use = self.params["training_params"]["shock_dur"]
        elif (
            test_run
        ):  # Run test with 1 second tone, 2 second trace, and 3 second shock
            tone_use = self.create_tone(
                f=self.params["tone"]["training"]["f"], duration=1, fp=self.params["tone"]["training"]["fp"],
            )
            trace_dur_use = 2
            shock_dur_use = 1

        # play tone
        self.write_event("CS" + str(trial) + "_start")
        self.board.digital[self.CS_pin].write(1)
        tones.play_tone(self.stream, tone_use, self.params["training_params"]["volume"])
        self.board.digital[self.CS_pin].write(0)
        self.write_event("CS" + str(trial) + "_end")

        # start trace period
        print(str(trace_dur_use) + " sec trace period started")
        self.write_event("trace" + str(trial) + "_start")
        sleep_timer(trace_dur_use)
        self.write_event("trace" + str(trial) + "_end")

        # administer shock
        print("Degrounding shock floor")
        self.board.digital[self.shock_relay_pin].write(
            0
        )  # signal to solid-state relay - send to floating ground
        time.sleep(
            0.05
        )  # make sure you give enough time for relay to switch over before shocking.
        print("Shock!")
        self.write_event("shock" + str(trial) + "_start")
        self.board.digital[self.shock_box_pin].write(1)  # signal to shock box
        time.sleep(shock_dur_use)
        self.board.digital[self.shock_box_pin].write(0)  # stop shock signal
        self.write_event("shock" + str(trial) + "_end")
        time.sleep(0.05)
        self.board.digital[self.shock_relay_pin].write(
            1
        )  # signal to solid-state relay - send to floating ground
        print("Shock floor re-grounded")

    def initialize_arduino(
        self,
        port="COM7",
        shock_box_pin=2,
        shock_relay_pin=7,
        video_io_pin=9,
        record_sync_pin=12,
        CS_pin = 11,
        video_start=True,
    ):
        """20210202: No try/except for now because I want to see an error when setting things up for now!"""
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
        self.shock_relay_pin = shock_relay_pin
        self.video_io_pin = video_io_pin
        self.record_sync_pin = record_sync_pin
        self.CS_pin = CS_pin

        # Make sure you always start out setting shock_relay_pin to 1 to ground box.
        print("Grounding shock floor")
        self.board.digital[self.shock_relay_pin].write(1)

        # initialize cleanup function
        atexit.register(shutdown_arduino, self.board)

    def create_tone(self, f="white", duration=1.0, fp=None):
        """Create a pure tone, tone_sweep, or noise.  Not used as of 2022_01_12.
        20210202: Only white noise working. freq input needs to be a float or list of floats for tone sweep"""
        if f == "white":
            tone_samples = tones.generate_white_noise(duration)
        elif type(f) in [int, float] and fp is None:
            tone_samples = tones.generate_pure_tone(duration, f)
        elif type(f) in [int, float] and fp is not None:
            tone_samples = tones.generate_pulse_tone(duration, f, fp)
        else:
            tone_samples = None

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
        if self.csv_path is None:
            self.start_time = time.time()
            self.start_datetime = datetime.now()
            self.csv_path = self.base_dir / (
                "test" + self.start_datetime.strftime("%m_%d_%Y-%H_%M_%S") + ".csv"
            )
        write_csv(self.csv_path, time.time() - self.start_time, event_id)


def shutdown_arduino(board):
    """cleanup function to shutdown arduino in case of suddent exit"""
    if isinstance(board, pyfirmata.Arduino):
        print("Shutting down arduino")
        board.exit()


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
    """Write time of event and event_id (int or str) to csv file"""

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


# NRK TODO: Figure out why play_tone for 1 second takes waaaay longer than 1 second. Probably need to initialize

# NRK TODO: Figure out why it doesn't work if video_in is on when you start experiment...git
# pyaudio stream first and keep it alive!  make it a better class!

# def test_run():
#     """Run this to quickly check that all components are working.
#     20210202: should hear tone and see shock lights turn on.
#     Future: will need to add in verification that TTL outs to acquisition system are working too."""
