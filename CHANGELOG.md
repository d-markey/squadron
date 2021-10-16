## 2.0.1

- Remove dependency on js package.

## 2.0.0

- This version supports workers running in Isolates as well as Web Workers.
- Platform implementations are now more straightforward thanks to Worker.connect() and Worker.process().
- See examples on how to scaffold Services, Squadron Workers and platform workers.
- Added tests for Web Workers (run with "dart run build_runner serve -r" and point your browser to http://localhost:8080/index.html).

## 1.0.2

- Added support for minimum count of workers in pool.
- Make sure Isolate is killed when the worker is stopped.
- Keep track of stats from stopped workers.
- Update tests & examples (proper error handling, command map, worker monitoring).

## 1.0.1

- Improve error handling.
- Improve documentation.
- Add unit tests.

## 1.0.0

- Initial version.
