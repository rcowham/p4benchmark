# p4benchutils.py
# Various shared functions

import os
import yaml
import sys
import subprocess
import time
import P4
import pprint
import random
import platform
import errno

from createfiles import create_file, generator
from locust import events

python3 = sys.version_info[0] >= 3
if python3:
    str_types = (str)
else:
    str_types = (str, unicode)

ENCODING = None
if hasattr(sys.stdin, 'encoding'):
    ENCODING = sys.stdin.encoding
if ENCODING is None:
    import locale
    locale_name, ENCODING = locale.getdefaultlocale()
if ENCODING is None:
    ENCODING = "ISO8859-1"

def popen(exe, cmd, decode=False, errors=True):
    cmd.insert(0, exe)
    pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = pipe.communicate()
    if errors and pipe.returncode > 0:
        raise Exception((stderr + stdout).decode(ENCODING))
    return stdout if not decode else stdout.decode(ENCODING)

def readConfig(startdir, config_file):
    config = {}
    with open(os.path.join(startdir, config_file), "r") as f:
        config = yaml.load(f, Loader=yaml.Loader)
    return config

def fmtsize(num):
    for x in ['bytes', 'KB', 'MB', 'GB', 'TB']:
        if num < 1024.0:
            return "%3.1f %s" % (num, x)
        num /= 1024.0


class Timer(object):
    def __init__(self, request_type):
        self.start_time = time.time()
        self.request_type = request_type

    def report_failure(self, name, e):
        total_time = int((time.time() - self.start_time) * 1000)
        events.request_failure.fire(request_type=self.request_type, name=name, response_time=total_time, exception=e)

    def report_success(self, name, count):
        total_time = int((time.time() - self.start_time) * 1000)
        events.request_success.fire(request_type=self.request_type, name=name, response_time=total_time, response_length=count)


class SyncOutput(P4.OutputHandler):
    "Log sync progress"

    def __init__(self, logger, timer, event_name, sync_progress_size_interval=100000):
        P4.OutputHandler.__init__(self)
        self.logger = logger
        self.timer = timer
        self.event_name = event_name
        self.sync_progress_size_interval = sync_progress_size_interval
        self.filesSynced = 0
        self.sizeSynced = 0
        self.previousSizeSynced = 0

    def reportFileSync(self, fileSize):
        self.filesSynced += 1
        self.sizeSynced += fileSize
        if not self.sync_progress_size_interval:
            return
        if self.sizeSynced > self.previousSizeSynced + self.sync_progress_size_interval:
            self.previousSizeSynced = self.sizeSynced
            self.timer.report_success(self.event_name, 1)
            self.logger.info("Synced %d files, size %s" % (self.filesSynced, fmtsize(self.sizeSynced)))

    def outputStat(self, stat):
        if 'fileSize' in stat:
            self.reportFileSync(int(stat['fileSize']))
        return P4.OutputHandler.HANDLED

class P4Benchmark(object):
    """Generic benchmarking class - must be subclassed"""

    def __init__(self, logger, startdir, config, prog="p4_bench"):
        self.logger = logger
        self.config = config
        self.id = id(self)      # Object id - unique enough for now.
        if "workspace_root" in config["general"]:
            self.test_root = config["general"]["workspace_root"]
        else:
            self.test_root = os.path.join(startdir, "testdata")
        self.localfilelist = []
        os.environ["P4CONFIG"] = os.path.join(startdir, "bench_p4config.txt")
        self.p4 = P4.P4()
        self.p4.prog = prog     # Identifier for log analysis
        self.p4.logger = logger
        p4config = config["perforce"]
        self.logger.info(pprint.pformat(p4config))
        if isinstance(p4config["port"], str_types):
            self.p4.port = p4config["port"]
        elif isinstance(p4config["port"], list):
            self.p4.port = random.choice(p4config["port"])
        else:
            raise Exception("Unknown port config")
        logger.info("Connecting to server: %s" % self.p4.port)
        self.p4.prog = "%s-%s" % (prog, self.p4.port)
        if "charset" in p4config and p4config["charset"]:
            self.p4.charset = p4config["charset"]
        self.repoPath = p4config["repoPath"]
        self.p4.user = p4config["user"]
        self.sync_progress_size_interval = 1000 * 1000 * 1000   # 1GB
        if "sync_progress_size_interval" in p4config:
            self.sync_progress_size_interval = int(eval(p4config["sync_progress_size_interval"]))
        self.p4.connect()
        if p4config["password"]:
            self.p4.password = p4config["password"]
            self.p4.run_login()
        server_id = self.p4.port.split(":")[-2].replace('.', '_')
        self.workspace_name = "{}.{}.{}.{}".format(self.p4.user, server_id, self.id, platform.node())
        self.workspace_root = os.path.join(self.test_root, self.workspace_name)
        if not os.path.isdir(self.test_root):
            try:
                os.makedirs(self.test_root, 0o777)
            except OSError as ex:
                if ex.errno != errno.EEXIST:
                    raise ex
                pass

    def getView(self):
        "Randomly select between dirs, or as directed by config file"
        p4config = self.config["perforce"]
        if p4config["repoSubDir"] == "*":
            dirs = [x['dir'] for x in self.p4.run_dirs("%s/%s" % (p4config["repoPath"], p4config["repoSubDir"]))]
        else:
            dirs = ["%s/%s" % (p4config["repoPath"], p4config["repoSubDir"])]
        if len(dirs) > 1:
            dir = random.choice(dirs)
            if "repoSubDirNum" in p4config and int(p4config["repoSubDirNum"]) > 1:
                subdirs = [x['dir'] for x in self.p4.run_dirs("%s/*" % dir)]
                subset = random.sample(subdirs, int(p4config["repoSubDirNum"]))
                return ["{}/... //{}/{}/...".format(x, self.workspace_name, x.replace("//", "")) for x in subset]
            else:
                return ["{}/... //{}/{}/...".format(dir, self.workspace_name, dir.replace("//", ""))]
        elif len(dirs) == 1:
            dir = dirs[0]
            return ["{}/... //{}/{}/...".format(dir, self.workspace_name, dir.replace("//", ""))]
        else:
            raise Exception("No dirs found!")

    def createWorkspace(self):
        p4config = self.config["perforce"]
        # Important to set client before attempting to create it in case we are talking to replica
        self.p4.client = self.workspace_name
        ws = self.p4.fetch_client(self.workspace_name)
        existed = (ws._root == self.workspace_root)
        ws._root = self.workspace_root
        ws._view = self.getView()
        ws._options = ws._options.replace("normdir", "rmdir")
        if "options" in p4config and p4config["options"]:
            self.logger.warn("Overwiting options")
            ws._options = p4config["options"]
        self.logger.info("Saving workspace view: %s" % ws._view[0])
        self.logger.info(pprint.pformat(ws))
        result = self.p4.save_client(ws)
        self.logger.info(pprint.pformat(result))
        return existed

    def syncWorkspace(self, timer):
        result = []
        p4config = self.config["perforce"]
        if "sync_args" in p4config and p4config["sync_args"]:
            cmd = "p4"
            args = [p4config["sync_args"], "-p", self.p4.port, "-u", self.p4.user, "-c", self.p4.client]
            args.extend(["sync", "//{}/...".format(self.p4.client)])
            self.logger.info("%s %s" % (cmd, " ".join(args)))
            result = popen(cmd, args)
            self.logger.info(result)
        else:
            if not os.path.isdir(self.workspace_root):
                os.makedirs(self.workspace_root, 0o777)
            os.chdir(self.workspace_root)
            event_name = "sync_partial_%s" % fmtsize(self.sync_progress_size_interval)
            syncCallback = SyncOutput(self.logger, timer, event_name, self.sync_progress_size_interval)
            with self.p4.at_exception_level(P4.P4.RAISE_ERRORS):
                result = self.p4.run_sync("//{}/...".format(self.p4.client), handler=syncCallback)
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

    def basicFileActions(self):
        """Randomly edit/delete/add files in workspace"""
        numActions = random.randint(1, 40)
        try:
            self.p4.run_sync("//...")
        except:
            pass
        try:
            self.localfilelist = [f["path"] for f in self.p4.run_have()]
        except:
            pass
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
        self.commit()
        return numActions

    def reportingActions(self):
        """Randomly describe/fstat/filelog"""
        numActions = random.randint(1, 20)
        try:
            self.p4.run_sync("//...")
        except:
            pass
        try:
            self.localfilelist = [f["path"] for f in self.p4.run_have()]
        except:
            pass
        for i in range(numActions):
            action = random.choice(["fstat", "filelog", "describe"])
            filename = random.choice(self.localfilelist)
            if action in ["fstat", "filelog"]:
                self.p4.run(action, filename)
            else:
                chg = self.p4.run_changes("-m1", "//...")
                desc = self.p4.run_describe("-s", chg[0]["change"])
        return numActions
