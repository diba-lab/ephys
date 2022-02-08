import time
import tones
import pyfirmata
import numpy as np
import sys
from pathlib import Path
import csv
from datetime import datetime
import atexit


class Waterport:
    def __init__(
        self,
        port_open_ms=50,
        port="COM7",
        left_sensor_pin=3,
        right_sensor_pin=5,
        left_port_pin=10,
        right_port_pin=8,
        OE_pin=7,
    ):
        self._initialize_arduino(
            port,
            left_sensor_pin,
            right_sensor_pin,
            left_port_pin,
            right_port_pin,
            OE_pin,
        )
        self.port_open_ms = port_open_ms

    def _initialize_arduino(
        self,
        port,
        left_sensor_pin,
        right_sensor_pin,
        left_port_pin,
        right_port_pin,
        OE_pin,
    ):
        self.board = pyfirmata.Arduino(port)

        # Set up board for reading in pins
        it = pyfirmata.util.Iterator(self.board)
        it.start()

        # set sensor pins to read mode - all pins write mode by default
        self.board.digital[left_sensor_pin].mode = pyfirmata.INPUT
        self.board.digital[right_sensor_pin].mode = pyfirmata.INPUT

        self.left_sensor_pin = left_sensor_pin
        self.right_sensor_pin = right_sensor_pin
        self.left_port_pin = left_port_pin
        self.right_port_pin = right_port_pin
        self.OE_pin = OE_pin

        # initialize cleanup function
        atexit.register(shutdown_arduino, self.board)

    def prime_left(self):
        """Prime left port for water delivery after lick! Sends TTL signal to OE at port open/close"""
        print("Left port primed")
        lick = False
        while not lick:
            if self.board.digital[self.left_sensor_pin].read():
                self.board.digital[self.left_port_pin].write(1)
                self.board.digital[self.OE_pin].write(1)
                time.sleep(self.port_open_ms / 1000)
                self.board.digital[self.OE_pin].write(0)
                self.board.digital[self.left_port_pin].write(0)
                lick = True
                print("Lick left detected")
            # maybe this helps prevent arduino stop reading inputs on Windows after awhile?
            time.sleep(0.01)

    def prime_right(self):
        """Prime left port for water delivery after lick! Sends TTL signal to OE at port open/close"""
        print("Right port primed")
        lick = False
        while not lick:
            if self.board.digital[self.right_sensor_pin].read():
                self.board.digital[self.right_port_pin].write(1)
                self.board.digital[self.OE_pin].write(1)
                time.sleep(self.port_open_ms / 1000)
                self.board.digital[self.OE_pin].write(0)
                self.board.digital[self.right_port_pin].write(0)
                print("Lick right detected")
                lick = True
            # maybe this helps prevent arduino stop reading inputs on Windows after awhile?
            time.sleep(0.01)

    def prime_both(self):
        """Primes both ports"""
        print("Both ports primed")
        lick = False
        while not lick:
            if self.board.digital[self.left_sensor_pin].read():
                self.board.digital[self.left_port_pin].write(1)
                self.board.digital[self.OE_pin].write(1)
                time.sleep(self.port_open_ms / 1000)
                self.board.digital[self.OE_pin].write(0)
                self.board.digital[self.left_port_pin].write(0)
                lick = True
                print("Lick left detected")

            if self.board.digital[self.right_sensor_pin].read():
                self.board.digital[self.right_port_pin].write(1)
                self.board.digital[self.OE_pin].write(1)
                time.sleep(self.port_open_ms / 1000)
                self.board.digital[self.OE_pin].write(0)
                self.board.digital[self.right_port_pin].write(0)
                print("Lick right detected")
                lick = True
            # maybe this helps prevent arduino stop reading inputs on Windows after awhile?
            time.sleep(0.01)


def shutdown_arduino(board):
    """cleanup function to shut down arduino in case of sudden exit"""
    if isinstance(board, pyfirmata.Arduino):
        print("Shutting down arduino")
        board.exit()
