#! /usr/bin/env python3
#
# Main driver for benchmarks
#
# Copyright (C) 2017, Robert Cowham, Perforce
#

from __future__ import print_function

import logging
import os
import platform
import math
import sys
import random
import string
import subprocess
from argparse import ArgumentParser
import yaml
from mimesis import Text # Fake text sentences

python3 = sys.version_info[0] >= 3

DEFAULT_SIZE = 20000
DEFAULT_MAX = 100

LINE_LENGTH = 80
BLOCK_SIZE = 8 * 1024  # For binary files

faketext = Text()

logger = logging.getLogger("createfiles")

# Random generators
try:
    import numpy as np

    def generator(size, eol="\n"):
        s = string.ascii_letters + string.digits
        return "".join(np.random.choice(list(s), size - 1)) + eol

except ImportError:
    print("No numpy installed, falling back to standard Python random. Prepare to wait ...", file=sys.stderr)

    def generator(size, eol="\n"):
        s = string.ascii_letters + string.digits
        return "".join((random.choice(s) for x in range(size - 1))) + eol

def create_file(fileSize, filename, binary=False):
    "Approximation for data generation"
    logger.debug("create_file '%s' binary: %s" % (filename, str(binary)))
    mode = "wb" if binary else "w"
    with open(filename, mode, buffering=(1024*1024)) as f:
        if binary:
            # Write 2 blocks at a time to allow for compression
            blocks = int(fileSize / BLOCK_SIZE / 2)
            for unused in range(blocks):
                b = os.urandom(BLOCK_SIZE)
                f.write(b)
                f.write(b)
        else:
            lines = int(fileSize / LINE_LENGTH)
            for unused in range(lines):
                f.write(faketext.text(1))
                f.write("\n")

class FileCreator:

    def __init__(self, options):
        self.options = options

    def getFileName(self):
        "Create a random filename"
        return "test"

    def getDirs(self, levels):
        "Return a list of directories from which to select"
        if len(levels) == 1:
            return ["%02d" % x for x in range(levels[0])]
        else:
            return ["%02d%s%s" % (x, os.path.sep,   y) for x in range(levels[0]) for y in self.getDirs(levels[1:])]

    def run(self):
        dirs = [os.path.join(self.options.rootdir, x) for x in self.getDirs(self.options.levels)]
        if self.options.create:
            for dir in dirs:
                if not os.path.isdir(dir):
                    os.makedirs(dir)
        maxsize = self.options.size * 3
        for i in range(self.options.max):
            dir = random.choice(dirs)
            if self.options.textonly:
                isBinary = False
            elif self.options.binaryonly:
                isBinary = True
            else:
                isBinary = random.choice([True, False])
            ext = ".txt"
            if isBinary:
                ext = ".dat"
            filename = os.path.join(dir, "%s%s" % (generator(20, eol=""), ext))
            print("File: %s" % filename)
            if self.options.create:
                create_file(random.randint(100, maxsize), filename, binary=isBinary)

def main():
    parser = ArgumentParser(add_help=True)
    parser.add_argument('-m', '--max', type=int, help="Number of files to create (default %d)" % DEFAULT_MAX, default=DEFAULT_MAX)
    parser.add_argument('-l', '--levels', type=int, nargs='+', help="Directories to create at each level, e.g. -l 5 10", default=5)
    parser.add_argument('-s', '--size', type=int, help="Average size of files (default %d)" % DEFAULT_SIZE, default=DEFAULT_SIZE)
    parser.add_argument('-d', '--rootdir', help="Directory where to start", default=None)
    parser.add_argument('-c', '--create', help="Create the files as specified instead of just printing names", action='store_true', default=False)
    parser.add_argument('-t', '--textonly', help="Only create text files", action='store_true', default=False)
    parser.add_argument('-b', '--binaryonly', help="Only create binary files", action='store_true', default=False)
    try:
        options = parser.parse_args()
        if not options.levels or len(options.levels) == 0:
            print("ERROR: At least one level must be specified")
        if options.textonly and options.binaryonly:
            print("ERROR: Specify either --textonly or --binaryonly but not both!\n")
            sys.exit(1)
    except:
        parser.print_help()
        sys.exit(1)

    fc = FileCreator(options)
    fc.run()

if __name__ == '__main__':
    main()

