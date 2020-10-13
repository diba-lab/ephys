#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Feb  7 16:02:04 2019

@author: bapung
"""

import sys


def DataDirPath():

    comp = sys.platform

    if comp == 'linux':

        DataPath = '/data/DataGen/'

    else:

        DataPath = '../../DataGen/'

    return DataPath


def figDirPath():

    comp = sys.platform

    if comp == 'linux':

        figPath = '/data/DataGen/figuresGen/'

    else:

        figPath = '../../DataGen/figuresGen/'

    return figPath


def RawDataPath():

    comp = sys.platform

    if comp == 'linux':

        DataPath = '/data/Clustering/'

    else:

        DataPath = '../../DataGen/'

    return DataPath
