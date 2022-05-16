#! /usr/bin/env python3
#
# Main driver for benchmarks
#
# Copyright (C) 2016, Robert Cowham, Perforce
#

from __future__ import print_function

import logging
import os
import P4
import platform
import sys
import random
import string
import subprocess
from argparse import ArgumentParser
import yaml
from createfiles import create_file, generator

python3 = sys.version_info[0] >= 3

CONFIG_FILE = "benchmark_config.yaml"   # Configuration parameters

# The following can be overridden in the config file svn/svnexe
SVN = "svn" # Default SVN command
if platform.system() == "Windows":
    SVN = "svn.exe"

def readConfig(startdir):
    config = {}
    with open(os.path.join(startdir, CONFIG_FILE), "r") as f:
        config = yaml.load(f)
    return config

logger = logging.getLogger("repo_benchmark")

if not (0x02070000 <= sys.hexversion < 0x02080000):
    sys.exit("Python 2.7 is required to run this program.")

LINE_LENGTH = 80
BLOCK_SIZE = 65536

class RepoBenchmark(object):
    """Generic benchmarking class - must be subclassed"""

    def __init__(self, startdir, config):
        self.id = id(self)      # Object id - unique enough for now.
        if "workspace_root" in config["general"]:
            self.test_root = config["general"]["workspace_root"]
        else:
            self.test_root = os.path.join(startdir, "testdata")
        self.localfilelist = []

    def createWorkspace(self):
        raise NotImplementedError("createWorkspace")

    def syncWorkspace(self):
        raise NotImplementedError("syncWorkspace")

    def addFile(self, filename):
        raise NotImplementedError("addFile")

    def editFile(self, filename):
        raise NotImplementedError("editFile")

    def deleteFile(self, filename):
        raise NotImplementedError("deleteFile")

    def basicFileActions(self):
        """Randomly edit/delete/add files in workspace"""
        numActions = random.randint(1, 20)
        for i in range(numActions):
            action = random.choice(["add", "edit", "edit", "edit", "edit", "delete"])
            filename = random.choice(self.localfilelist)
            if action == "add":
                addfilename = os.path.join(os.path.dirname(filename), generator(20, eol=""))
                create_file(random.randint(100, 1000000), addfilename, random.choice([True, False]))
                self.addFile(addfilename)
            elif action == "edit":
                self.editFile(filename)
                with open(filename, "a") as f:
                    f.write("Some extra data\n")
            else:
                self.deleteFile(filename)
        return numActions

    def commit(self):
        """Commit/Submit changes"""
        raise NotImplementedError("commit")

    def run(self):
        """Run the appropriate test - basically a sync/edit/add/delete and submit"""
        try:
            self.createWorkspace()
            self.syncWorkspace()
            self.basicFileActions()
            self.commit()
        except Exception as e:
            logger.exception(e)
            raise e

class P4Benchmark(RepoBenchmark):
    """Performs basic benchmark test - Perforce specific subclass"""

    def __init__(self, startdir, config):
        super(P4Benchmark, self).__init__(startdir, config)
        if "P4CONFIG" in os.environ:    # Problems with DVCS
            logger.warning("Overriding P4CONFIG from environment")
            os.environ["P4CONFIG"] = "dummy_p4config"
        self.p4 = P4.P4()
        self.p4.logger = logger
        self.config = config
        p4config = config["perforce"]
        self.p4.port = p4config["port"]
        if "charset" in p4config and p4config["charset"]:
            self.p4.charset = p4config["charset"]
        self.repoPath = p4config["repoPath"]
        self.p4.user = p4config["user"]
        result = self.p4.connect()
        if p4config["password"]:
            self.p4.password = p4config["password"]
            self.p4.run_login()
        self.workspace_name = "{}.{}.{}".format(self.p4.user, self.id, platform.node())
        self.workspace_root = os.path.join(self.test_root, self.workspace_name)
        if not os.path.isdir(self.test_root):
            os.makedirs(self.test_root, 0o777)

    def createWorkspace(self):
        ws = self.p4.fetch_client(self.workspace_name)
        existed = (ws._root == self.workspace_root)
        ws._root = self.workspace_root
        ws._view = ["{} //{}/...".format(self.repoPath, self.workspace_name)]
        ws._options = ws._options.replace("normdir", "rmdir")
        result = self.p4.save_client(ws)
        self.p4.client = self.workspace_name
        return existed

    def syncWorkspace(self):
        result = None
        if not os.path.isdir(self.workspace_root):
            os.makedirs(self.workspace_root, 0o777)
        os.chdir(self.workspace_root)
        with self.p4.at_exception_level(P4.P4.RAISE_ERRORS):
            result = self.p4.run_sync("//{}/...".format(self.p4.client))
        havelist = self.p4.run_have()
        self.localfilelist = [f["path"] for f in havelist]
        return len(result)

    def addFile(self, filename):
        self.p4.run_add(filename)

    def editFile(self, filename):
        self.p4.run_edit(filename)

    def deleteFile(self, filename):
        self.p4.run_delete(filename)

    def commit(self):
        """Submit our change"""
        opened = self.p4.run_opened()
        if len(opened) > 0:
            with self.p4.at_exception_level(P4.P4.RAISE_ERRORS):
                files = [x['depotFile'] for x in opened]
                self.p4.run_sync(files)
                self.p4.run_resolve("-ay")
            chg = self.p4.fetch_change()
            chg._description = "A test change"
            self.p4.save_submit(chg)
            with self.p4.at_exception_level(P4.P4.RAISE_ERRORS):
                self.p4.run_revert("//...")


class P4BuildFarmBenchmark(RepoBenchmark):
    """Performs basic benchmark test - Perforce specific subclass"""

    def __init__(self, startdir, config):
        super(P4BuildFarmBenchmark, self).__init__(startdir, config)
        if "P4CONFIG" in os.environ:    # Problems with DVCS
            logger.warning("Removing P4CONFIG from environment")
            del os.environ["P4CONFIG"]
        self.p4 = P4.P4()
        self.p4.logger = logger
        self.config = config
        p4config = config["perforce"]
        self.p4.port = p4config["port"]
        if "charset" in p4config and p4config["charset"]:
            self.p4.charset = p4config["charset"]
        self.repoPath = p4config["repoPath"]
        self.p4.user = p4config["user"]
        result = self.p4.connect()
        if p4config["password"]:
            self.p4.password = p4config["password"]
            self.p4.run_login()
        self.workspace_name = "{}.{}.{}".format(self.p4.user, self.id, platform.node())
        self.workspace_root = os.path.join(self.test_root, self.workspace_name)
        if not os.path.isdir(self.test_root):
            os.makedirs(self.test_root, 0o777)

    def createWorkspace(self):
        ws = self.p4.fetch_client(self.workspace_name)
        existed = (ws._root == self.workspace_root)
        ws._root = self.workspace_root
        ws._view = ["{} //{}/...".format(self.repoPath, self.workspace_name)]
        ws._options = ws._options.replace("normdir", "rmdir")
        result = self.p4.save_client(ws)
        self.p4.client = self.workspace_name
        return existed

    def syncWorkspace(self):
        result = None
        if not os.path.isdir(self.workspace_root):
            os.makedirs(self.workspace_root, 0o777)
        os.chdir(self.workspace_root)
        with self.p4.at_exception_level(P4.P4.RAISE_ERRORS):
            result = self.p4.run_sync("//{}/...".format(self.p4.client))
        havelist = self.p4.run_have()
        self.localfilelist = [f["path"] for f in havelist]
        return len(result)

    def addFile(self, filename):
        pass

    def editFile(self, filename):
        pass

    def deleteFile(self, filename):
        pass

    def commit(self):
        pass

    def basicFileActions(self):
        return 1

    def run(self):
        """Run the appropriate test - basically a sync and submit"""
        try:
            self.createWorkspace()
            self.syncWorkspace()
        except Exception as e:
            logger.exception(e)
            raise e

class SvnBenchmark(RepoBenchmark):
    """Performs basic benchmark test - SVN specific subclass"""

    def __init__(self, startdir, config):
        super(SvnBenchmark, self).__init__(startdir, config)
        self.config = config
        svnconfig = config["svn"]
        self.serverURL = svnconfig["serverURL"]
        self.repoPath = svnconfig["repoPath"]
        self.fullURL = "{}/{}".format(self.serverURL, self.repoPath)
        self.user = svnconfig["user"]
        self.password = svnconfig["password"]
        if "svnexe" in svnconfig and svnconfig["svnexe"]:
            self.svnexe = svnconfig["svnexe"]
        else:
            self.svnexe = SVN
        self.workspace_name = "{}.{}.{}".format(self.user, self.id, platform.node())
        self.workspace_root = os.path.join(self.test_root, self.workspace_name)
        if not os.path.isdir(self.test_root):
            os.makedirs(self.test_root, 0o777)

    def svncmd(self, cmd, args, special = []):
        command = [self.svnexe, cmd]
        for arg in args:
            command.append(arg)

        logger.debug(", ".join(command))
        p = subprocess.Popen(command, stdout=subprocess.PIPE)
        result = p.stdout.read()
        logger.debug(result)
        return result

    def createWorkspace(self):
        "Returns true if existed previously"
        return os.path.isdir(self.workspace_root)

    def syncWorkspace(self):
        cmd = "co"
        if os.path.isdir(self.workspace_root):
            cmd = "update"
        result = self.svncmd(cmd,
                    ["--username", self.user, "--password", self.password,
                     self.fullURL,
                     self.workspace_root
                    ])
        self.localfilelist = []
        for root, dirs, files in os.walk(self.workspace_root):
            if ".svn" in dirs:
                dirs.remove(".svn")
            self.localfilelist.extend([os.path.join(root, f) for f in files])
        return len(result)

    def addFile(self, filename):
        os.chdir(self.workspace_root)
        self.svncmd("add", [filename])

    def editFile(self, filename):
        logger.info("svn edit")
        pass    # SVN doesn't do edits

    def deleteFile(self, filename):
        os.chdir(self.workspace_root)
        self.svncmd("delete", [filename])

    def commit(self):
        description = "SVN checkin"
        os.chdir(self.workspace_root)
        self.svncmd("ci", ["-m", description])

# For testing purposes - normally expect this module to be imported and classes used directly
if __name__ == "__main__":
    parser = ArgumentParser(
            description="Benchmark Testing",
            epilog="Copyright (C) 2016 Robert Cowham, Perforce Software Ltd")
    parser.add_argument("-s","--svn", action='store_true', default=False, help="Run SVN")
    parser.add_argument("-p","--p4", action='store_true', default=True, help="Run P4")
    options = parser.parse_args()

    startdir = os.getcwd()
    if options.svn:
        b = SvnBenchmark(startdir, readConfig(startdir))
    else:
        b = P4Benchmark(startdir, readConfig(startdir))
    try:
        b.run()
    except Exception as e:
        pass
