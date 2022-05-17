# -*- encoding: UTF8 -*-
# Test module for triggers.

from __future__ import print_function


import sys
import unittest
import yaml
import P4
import logging
import os
import shutil
import stat
import textwrap
from subprocess import Popen, PIPE

python3 = sys.version_info[0] >= 3
if sys.hexversion < 0x02070000 or (0x0300000 < sys.hexversion < 0x0303000):
    sys.exit("Python 2.7 or 3.3 or newer is required to run this program.")

if python3:
    from io import StringIO
else:
    from StringIO import StringIO


P4D = "p4d"
P4USER = "testuser"
P4CLIENT = "test_ws"

INTEG_ENGINE = 3

saved_stdoutput = StringIO()
test_logger = None

def onRmTreeError(function, path, exc_info):
    os.chmod(path, stat.S_IWRITE)
    os.remove(path)

def ensureDirectory(directory):
    if not os.path.isdir(directory):
        os.makedirs(directory)

def localDirectory(root, *dirs):
    "Create and ensure it exists"
    dir_path = os.path.join(root, *dirs)
    ensureDirectory(dir_path)
    return dir_path

def create_file(file_name, contents):
    "Create file with specified contents"
    ensureDirectory(os.path.dirname(file_name))
    if python3:
        contents = bytes(contents.encode())
    with open(file_name, 'wb') as f:
        f.write(contents)

def append_to_file(file_name, contents):
    "Append contents to file"
    if python3:
        contents = bytes(contents.encode())
    with open(file_name, 'ab+') as f:
        f.write(contents)

def getP4ConfigFilename():
    "Returns os specific filename"
    if 'P4CONFIG' in os.environ:
        return os.environ['P4CONFIG']
    if os.name == "nt":
        return "p4config.txt"
    return ".p4config"


class TestCase(unittest.TestCase):
    """Common structure"""

    def __init__(self, logger_name, log_file, methodName='runTest'):
        super(TestCase, self).__init__(methodName=methodName)
        if logger_name and log_file:
            self.logger = logging.getLogger(logger_name)
            self.logger.setLevel(logging.DEBUG)
            logformat = '%(levelname)s [%(asctime)s] [%(filename)s : %(lineno)d] - %(message)s'
            logging.basicConfig(format=logformat, filename=log_file, level=logging.DEBUG)

    # Python compatibility
    def assertRegex(self, *args, **kwargs):
        if python3:
            return super(TestCase, self).assertRegex(*args, **kwargs)
        else:
            return super(TestCase, self).assertRegexpMatches(*args, **kwargs)

class P4Server:
    def __init__(self, suffix="", cleanup=True, logger=None):
        self.startdir = os.getcwd()
        self.root = os.path.join(self.startdir, '_testrun')
        if logger:
            self.logger = logger
        else:
            self.logger = logging.getLogger()
        self.server_root = os.path.join(self.root, "server%s" % suffix)
        self.client_root = os.path.join(self.root, "client%s" % suffix)
        if cleanup:
            self.cleanupTestTree()
        
        ensureDirectory(self.root)
        ensureDirectory(self.server_root)
        ensureDirectory(self.client_root)

        self.p4d = P4D
        self.port = "rsh:%s -r \"%s\" -L log -i" % (self.p4d, self.server_root)
        self.p4 = P4.P4()
        self.p4.port = self.port
        self.p4.user = P4USER
        self.p4.client = P4CLIENT
        self.p4.connect()

        self.p4.run('depots') # triggers creation of the user
        self.p4.run('configure', 'set', 'dm.integ.engine=%d' % INTEG_ENGINE)

        self.p4.disconnect() # required to pick up the configure changes
        self.p4.connect()

        # Override standard environment in case test dir is not checked in due to parent p4ignore file
        self.p4.ignore_file = ".p4ignore-tests"

        self.client_name = P4CLIENT
        client = self.p4.fetch_client(self.client_name)
        client._root = self.client_root
        client._lineend = 'unix'
        self.p4.save_client(client)
        self.writeP4Config(suffix)

    def shutDown(self):
        if self.p4.connected():
            self.p4.disconnect()

    def enableUnicode(self):
        cmd = [self.p4d, "-r", self.server_root, "-L", "log", "-vserver=3", "-xi"]
        f = Popen(cmd, stdout=PIPE).stdout
        for s in f.readlines():
            pass
        f.close()

    def cleanupTestTree(self):
        os.chdir(self.startdir)
        if os.path.isdir(self.root):
            shutil.rmtree(self.root, False, onRmTreeError)

    def writeP4Config(self, suffix):
        "Write appropriate files - useful for occasional manual debugging"
        p4config_filename = getP4ConfigFilename()
        contents = """P4PORT=%s
P4USER=%s
P4CLIENT=%s
P4IGNORE=
""" % (self.port, self.p4.user, self.p4.client)
        config = os.path.join(self.root, p4config_filename)
        if suffix:
            config = os.path.join(self.client_root, p4config_filename)
        create_file(config, contents)

        config = os.path.join(self.server_root, p4config_filename)
        create_file(config, contents)

# from p4testutils import TestCase, P4Server, localDirectory, create_file, append_to_file

parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, parent_dir)
from p4benchutils import P4Benchmark

os.environ["LOGS"] = "."
LOGGER_NAME = "TestP4Benchmark"
LOG_FILE = "log-%s.log" % LOGGER_NAME

python3 = sys.version_info[0] >= 3

class TestP4Benchmark(TestCase):
    def __init__(self, methodName='runTest'):
        super(TestP4Benchmark, self).__init__(LOGGER_NAME, LOG_FILE, methodName=methodName)

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def setupServer(self):
        self.server = P4Server()
        p4 = self.server.p4
        p4.logger = self.logger
        # This works if no spaces in server root pathname!
        port = p4.port.replace('"', '')
        self.logger.debug("port: |%s|" % port)
        p4.disconnect()        
        p4.connect()
        return p4

    def loadConfig(self, yamlString):
        return yaml.load(StringIO(textwrap.dedent(
            yamlString % (self.server.client_root, self.server.p4.port))), Loader=yaml.Loader)

    def testSetupWorkspace(self):
        """Workspace created"""
        p4 = self.setupServer()

        dirs = []
        for i in range(5):
            for j in range(5):
                dirs.append(os.path.join(self.server.client_root, "%02d" % i, "%02d" %j))
        for d in dirs:
            f = os.path.join(d, 'file.txt')
            create_file(f, 'Test content')
            p4.run('add', f)
        p4.run('submit', '-d', 'files')

        config = self.loadConfig("""
            general:
                workspace_root:  '%s'
            perforce:
                port:       
                - '%s'
                user:       bruno
                password: 
                repoPath:   //depot/01/*
                repoDirNum: 5
            """)
        bench = P4Benchmark(self.logger, self.server.client_root, config)
        view = bench.getView()
        self.logger.debug("view: %s" % str(view))
        self.assertEqual(5, len(view))

        config['perforce']['repoPath'] = "//depot/*/*"
        config['perforce']['repoDirNum'] = 4
        bench = P4Benchmark(self.logger, self.server.client_root, config)
        view = bench.getView()
        self.logger.debug("view: %s" % str(view))
        self.assertEqual(4, len(view))

        config['perforce']['repoPath'] = "//depot/02"
        config['perforce']['repoDirNum'] = 4
        bench = P4Benchmark(self.logger, self.server.client_root, config)
        view = bench.getView()
        self.logger.debug("view: %s" % str(view))
        self.assertEqual(1, len(view))
        
if __name__ == '__main__':
    unittest.main()
