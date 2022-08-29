#!/usr/bin/env python
import k
import sys

from multiprocessing.managers import BaseManager
import queue

queue_a = queue.Queue()
queue_b = queue.Queue()
BaseManager.register('queue_a', callable=lambda: queue_a)
BaseManager.register('queue_b', callable=lambda: queue_b)

m = BaseManager(address=('', int(sys.argv[1])), authkey=b'qwerty')
m.start()

shared_queue_a = m.queue_a()
shared_queue_b = m.queue_b()

while True:
    msg = shared_queue_b.get()
    shared_queue_a.put(k.k(msg))

m.shutdown()
