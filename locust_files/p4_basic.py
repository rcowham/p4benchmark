#! /usr/bin/env python3
#
# Perforce benchmarks using Locust.io framework
#
# Copyright (C) 2016, Robert Cowham, Perforce
#

from __future__ import print_function

import os
import sys
import logging
from locust import User, events, task, TaskSet
from locust.exception import StopUser
import P4

from p4benchutils import popen, fmtsize, readConfig, Timer, P4Benchmark

from locust.stats import RequestStats
def noop(*arg, **kwargs):
    logger.info("Stats reset prevented by monkey patch!")
RequestStats.reset_all = noop

python3 = sys.version_info[0] >= 3

logger = logging.getLogger("p4_basic")

startdir = os.getcwd()

CONFIG_FILE = "config_p4_basic.yml"   # Configuration parameters

class P4BasicBenchmark(P4Benchmark):
    """Performs basic benchmark test - Perforce specific subclass"""

    def __init__(self, startdir, config):
        super(P4BasicBenchmark, self).__init__(logger, startdir, config, "basicActions")

def basicActions(bench, request_type):
    "Basic actions does sync/resolve/revert and then add/edit/delete"

    t = Timer(request_type)
    name = "actions"
    try:
        count = bench.basicFileActions()
        t.report_success(name, count)
    except Exception as e:
        logger.exception(e)
        t.report_failure(name, e, count)

def reportingActions(bench, request_type):
    "Does describe/fstat/filelog"

    t = Timer(request_type)
    name = "reporting"
    try:
        count = bench.reportingActions()
        t.report_success(name, count)
    except Exception as e:
        logger.exception(e)
        t.report_failure(name, e, count)

class AllTasks(TaskSet):
    """Entry point for locust"""

    min_wait = 1000
    max_wait = 3000
    request_type = "p4"

    def __init__(self, *args, **kwargs):
        super(AllTasks, self).__init__(*args, **kwargs)
        self.config = readConfig(startdir, CONFIG_FILE)
        self.min_wait = self.config["general"]["min_wait"]
        self.max_wait = self.config["general"]["max_wait"]
        self.repeat_count = 0
        if "repeat" in self.config["perforce"]:
            self.repeat_count = self.config["perforce"]["repeat"]
        self.count = 0
        self.task_name = "p4basic"
        self.bench = P4BasicBenchmark(startdir, self.config)

    def on_start(self):
        count = 0
        t = Timer(self.request_type)
        name = "create"
        try:
            self.bench.createWorkspace()
            count = 1
            t.report_success(name, count)
        except Exception as e:
            logger.exception(e)
            t.report_failure(name, e, count)
        t = Timer(self.request_type)
        name = "sync"
        try:
            count = self.bench.syncWorkspace(t)
            t.report_success(name, count)
        except Exception as e:
            logger.exception(e)
            t.report_failure(name, e, count)

    @task(10)
    def basicActions(self):
        logger.info("Starting basicActions %s" % self.task_name)
        basicActions(self.bench, self.task_name)
        logger.info("Finished %s" % self.task_name)
        self.count += 1
        if self.repeat_count and self.count >= self.repeat_count:
            raise StopUser(self.task_name)   # Die if done

    @task(10)
    def reportingActions(self):
        "Run describe, filelog and fstat"
        logger.info("Starting reportingActions %s" % self.task_name)
        reportingActions(self.bench, self.task_name)
        logger.info("Finished %s" % self.task_name)
        self.count += 1
        if self.repeat_count and self.count >= self.repeat_count:
            raise StopUser(self.task_name)   # Die if done

class P4RepoTestLocust(User):
    """Will be imported and then run by locust"""
    tasks = [AllTasks]
