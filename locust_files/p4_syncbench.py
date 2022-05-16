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

logger = logging.getLogger("p4_syncbench")

startdir = os.getcwd()

CONFIG_FILE = "config_p4_syncbench.yml"   # Configuration parameters

class P4BuildFarmBenchmark(P4Benchmark):
    """Performs basic benchmark test - Perforce specific subclass"""

    def __init__(self, startdir, config):
        super(P4BuildFarmBenchmark, self).__init__(logger, startdir, config, "p4buildfarm")

def buildFarmActions(bench, request_type):
    "Build farm basically just does a sync"
    count = 0
    t = Timer(request_type)
    name = "create"
    try:
        bench.createWorkspace()
        count = 1
        t.report_success(name, count)
    except Exception as e:
        logger.exception(e)
        t.report_failure(name, e)
    t = Timer(request_type)
    name = "sync"
    try:
        count = bench.syncWorkspace(t)
        t.report_success(name, count)
    except Exception as e:
        logger.exception(e)
        t.report_failure(name, e)

class AllTasks(TaskSet):
    """Entry point for locust"""

    min_wait = 1000
    max_wait = 10000
    request_type = "p4"

    def __init__(self, *args, **kwargs):
        super(AllTasks, self).__init__(*args, **kwargs)
        self.config = readConfig(startdir, CONFIG_FILE)
        self.min_wait = self.config["general"]["min_wait"]
        self.max_wait = self.config["general"]["max_wait"]

    def on_start(self):
        pass

    @task(10)
    def buildFarmActions(self):
        task_name = "p4buildfarm"
        self.bench = P4BuildFarmBenchmark(startdir, self.config)
        buildFarmActions(self.bench, task_name)
        logger.info("Finished %s" % task_name)
        raise StopUser("task_name")   # Run once only and die

class P4RepoTestLocust(User):
    """Will be imported and then run by locust"""
    tasks = [AllTasks]
