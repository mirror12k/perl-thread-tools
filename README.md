# perl-thread-tools
a reimplementation of some generic multi-threading tools

mostly just some practice of blindly cloning functionality from existing tools

## NewThread::Queue
a thread-safe queue reimplemented from Thread::Queue
allows safe passage of items between threads

## NewThread::PriorityQueue
an extension of NewThread::Queue which allows assignment of priority to items in the queue and dequeues items based on their priority

## NewThread::Pool
a thread pool reimplemented from Thread::Pool
allows easy management of a pool of threads which can assigned jobs to fulfill and read the results returned from workers

## NewThread::Semaphore
a thread-safe semaphore reimplemented from Thread::Semaphore
allows convenient management of shared resources

## NewThread::Pipe
a socket-like tool which allows bi-directional communication between two threads with read() and print()
