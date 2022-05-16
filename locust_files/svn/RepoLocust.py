import time
import os
import logging
from locust import events

logger = logging.getLogger("repo_benchmark")

startdir = os.getcwd()

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
