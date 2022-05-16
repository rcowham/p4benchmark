# -*- encoding: UTF8 -*-
# Test harness for JobsCmdFilter.py

from __future__ import print_function

import sys
import unittest

from RepoBenchmark import create_file

python3 = sys.version_info[0] >= 3

class TestBase(unittest.TestCase):
    def __init__(self, methodName='runTest'):
        super(TestBase, self).__init__(methodName=methodName)

    def assertRegex(self, *args, **kwargs):
        if python3:
            return super(TestBase, self).assertRegex(*args, **kwargs)
        else:
            return super(TestBase, self).assertRegexpMatches(*args, **kwargs)

class TestCreateFile(TestBase):

    def __init__(self, methodName='runTest'):
        super(TestCreateFile, self).__init__(methodName=methodName)

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def testBasic(self):
        "simple creation"

        create_file(100, "test-text.dat", binary=False)
        create_file(100, "test-binary.dat", binary=True)