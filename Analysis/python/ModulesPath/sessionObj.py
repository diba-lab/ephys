import os
from pathlib import Path

import numpy as np

# from eventCorr import hswa_ripple
from lfpEvent import hswa, ripple

# from makeChanMap import ExtractChanXml
# from MakePrmKlusta import makePrmPrb

# from parsePath import name2path

from callfunc import func


class session:
    def __init__(self, basePath):
        # super().__init__(basePath)
        self.ripple = ripple(basePath)

