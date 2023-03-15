# mirai 0.8.0

* mirai 0.8.0 is a major feature release. Special thanks to @wlandau for suggestions, discussion and testing for many of the new capabilities.
* Compute profiles have been introduced through a new `.compute` argument in `daemons()` and `mirai()` for sending tasks with heterogeneous compute requirements.
  + `daemons()` can create new profiles to connect to different resources e.g. servers with GPU, accelerators etc.
  + `mirai()` tasks can be sent using a specific compute profile.
* `daemons()` interface has a new `url` argument along with `dispatcher` for using a background dispatcher process to ensure optimal FIFO task scheduling (now the default).
  + Supplying a client URL with a zero port number `:0` will automatically assign a free ephemeral port, with the actual port number subsequently reported by `daemons()`.
  + Calling with no arguments now provides an improved view of the current number of connections / daemons (URL, online and busy status, tasks assigned and completed, instance), replacing the previous `daemons("view")` functionality.
* `dispatcher()` is implemented as a new function for the dispatcher.
* `server()` gains the following arguments:
  + `asyncdial` to specify how the server dials into the client.
  + `maxtasks` for specifying a maximum number of tasks before exiting.
  + `idletime` for specifying an idle time, since completion of the last task before exiting.
  + `walltime` for specifying a soft walltime before exiting.
  + `timerstart` for specifying a minimum number of task completions before starting timers.
* Invalid URLs provided to `daemons()` and `server()` now error and return immediately instead of potentially causing a hang.
* `eval_mirai()` is removed as an alias for `mirai()`.
* 'mirai' processes are no longer launched in Rscript sessions with the `--vanilla` argument to enable site / user profile and environment files to be read.
* Requires nanonext >= 0.8.0.
* Internal performance enhancements.

# mirai 0.7.2

* Internal performance enhancements.

# mirai 0.7.1

* Allow user interrupts of `call_mirai()` again (regression in 0.7.0), now returning a 'miraiInterrupt'.
* Adds auxiliary function `is_mirai_interrupt()` to test if an object is a 'miraiInterrupt'.
* Requires nanonext >= 0.7.0: returned 'errorValues' e.g. mirai timeouts are no longer accompanied by warnings.
* Internal performance enhancements.

# mirai 0.7.0

* `daemons()` now takes 'n' and '.url' arguments. '.url' is an optional client URL allowing mirai tasks to be distributed across the network. Compatibility with existing interface is retained.
* The server function `server()` is exported for creating daemon / ephemeral processes on network resources.
* Mirai errors are formatted better and now print to stdout rather than stderr.
* Improvements to performance and stability requiring nanonext >= 0.6.0.
* Internal enhancements to error handling in a mirai / daemon process.

# mirai 0.6.0

* Notice: older package versions will no longer be supported by 'nanonext' >= 0.6.0. Please ensure you are using the latest version of 'mirai' or else refrain from upgrading 'nanonext'.
* Internal enhancements to `daemons()` and `%>>%` deferred evaluation pipe.

# mirai 0.5.3

* `mirai()` gains a '.args' argument for passing a list of objects already in the calling environment, allowing for example `mirai(func(x, y, z), .args = list(x, y, z))` rather than having to specify `mirai(func(x, y, z), x = x, y = y, z = z)`.
* Errors from inside a mirai will now return the error message as a character string of class 'miraiError' and 'errorValue', rather than just a nul byte. Utility function `is_mirai_error()` should be used in place of `is_nul_byte()`, which is no longer re-exported.
* `is_error_value()` can be used to test for all errors, including timeouts where the '.timeout' argument has been used.
* All re-exports from 'nanonext' have been brought in-package for better documentation.

# mirai 0.5.2

* Internal optimisations requiring nanonext >= 0.5.2.

# mirai 0.5.0

* Implements the `%>>%` deferred evaluation pipe.
* Adds '.timeout' argument to `mirai()` to ensure a mirai always resolves even if the child process crashes etc.

# mirai 0.4.1

* Exits cleanly when daemons have not been explicitly zeroed prior to ending an R session.
* Fixes possible hang on Windows when shutting down daemons.

# mirai 0.4.0

* Back to a pure R implementation thanks to enhanced internal design at nanonext.
* Adds auxiliary function `is_mirai()` to test if an object is a mirai.
* Versioning system to synchronise with nanonext e.g. v0.4.x requires nanonext >= 0.4.0.

# mirai 0.2.0

* The value of a mirai is now stored at `$data` to optimally align with the underlying implementation.
* Package now contains C code (requires compilation), using weak references for simpler management of resources.
* Switch to abstract sockets on Linux.

# mirai 0.1.1

* `mirai()` added as an alias for `eval_mirai()`; supports evaluating arbitrary length expressions wrapped in `{}`.
* A mirai now resolves automatically without requiring `call_mirai()`. Access the `$value` directly and an ‘unresolved’ logical NA will be returned if the async operation is yet to complete.
* `stop_mirai()` added as a function to stop evaluation of an ongoing async operation.
* Auxiliary functions `is_nul_byte()` and `unresolved()` re-exported from {nanonext} to test for evaluation errors and resolution of a 'mirai' respectively.
* New `daemons()` interface to set and manage persistent background processes for receiving 'mirai' requests.

# mirai 0.1.0

* Initial release.
