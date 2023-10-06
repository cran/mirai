# mirai 0.11.0

* Implements an alternative communications backend for R, adding methods for the 'parallel' base package.
  + Fulfils a request by R Core at R Project Sprint 2023, and requires R >= 4.4 (currently R-devel).
  + `make_cluster()` creates a 'miraiCluster', compatible with all existing functions taking a 'cluster' object, for example in the 'parallel' and 'doParallel' / 'foreach' packages.
  + `status()` can now take a 'miraiCluster' as the argument to query its connection status.
* `launch_remote()` improvements:
  + Simplified interface with a single 'remote' argument taking a remote configuration to launch daemons.
  + Returned shell commands now have a custom print method which means they may be directly copy/pasted to a remote machine.
  + Can now take a 'miraiCluster' or 'miraiNode' to return the shell commands for deployment of remote nodes.
* `daemons()` gains the following features:
  + Adds argument 'remote' for launching remote daemons directly without recourse to a separate call to `launch_remote()`.
  + Adds argument 'resilience' to control the behaviour, when not using dispatcher, of whether to retry failed tasks on other daemons.
* `remote_config()` added to generate configurations for directly launching remote daemons, and can be supplied directly to a 'remote' argument.
* `ssh_config()` added as a convenience method to generate launch configurations using SSH, including SSH tunnelling.
* `mirai()` adds logical argument '.signal' for whether to signal the condition variable within the compute profile upon resolution of the 'mirai'.
* `daemon()` argument 'exitlinger' retired as daemons now synchronise with the host/dispatcher and exit as soon as possible (although a default 'exitlinger' period still applies to ephemeral daemons).
* Optimises scheduling at dispatcher: tasks are no longer assigned to a daemon if it is exiting due to specified time/task-outs.
* An 'errorValue' 19 'Connection reset' is now returned for a 'mirai' if the connection to either dispatcher or an ephemeral daemon drops, for example if they have crashed, rather than remaining unresolved.
* Invalid type of '...' arguments specified to `daemons()` or `dispatcher()` now raise an error early rather than attempting to launch daemons that fail.
* Eliminates a potential crash in the host process after querying `status()` if there is no longer a connection to dispatcher.
* Reverts the trailing line break added to the end of a 'miraiError' character string.
* Moves the '...' argument to `daemons()`, `dispatcher()` and `daemon()` to clearly delineate core vs peripheral options.
* Deprecates the Deferred Evaluation Pipe `%>>%` in favour of a recommendation to use package `mirai.promises` for performing side effects upon 'mirai' resolution.
* Deprecated use of alias `server()` for `daemon()` is retired.
* Adds a 'reference' vignette, incorporating most of the information from the readme.
* Requires nanonext >= 0.10.2.

# mirai 0.10.0

* Uses L'Ecuyer-CMRG streams for safe and reproducible (in certain cases) random number generation across parallel processes (thanks @ltierney for discussion during R Project Sprint 2023).
  + `daemons()` gains the new argument 'seed' to set a random seed for generating these streams.
  + `daemon()` and `dispatcher()` gain the argument 'rs' which takes a L'Ecuyer-CMRG random seed.
* New developer functions `nextstream()` and `nextget()`, opening interfaces for packages which extend `mirai`.
* Dispatcher enhancements and fixes:
  + Runs in an R session with `--vanilla` flags for efficiency, avoiding lengthy startup configurations (thanks @alexpiper).
  + Straight pass through without serialization/unserialization allows higher performance and lower memory utilisation.
  + Fixes edge cases of `status()` occasionally failing to communicate with dispatcher.
  + Fixes edge cases of ending a session with unresolved mirai resulting in a crash rather than a clean exit.
* Tweaks to `saisei()`:
  + specifying argument 'force' as TRUE now immediately regenerates the socket and returns any ongoing mirai as an 'errorValue'. This allows tasks that consistently hang or crash to be cancelled rather than repeated when a new daemon connects.
  + argument 'i' is now required and no longer defaults to 1L.
* Tweaks to `status()`:
  + The daemons status matrix adds a column 'i' for ease of use with functions such as `saisei()` or `launch_local()`.
  + The 'instance' column is now always cumulative - regenerating a URL with `saisei()` no longer resets the counter but instead turns it negative until a new daemon connects.
* Improves shell quoting of daemon launch commands, making it easier to deploy manually via `launch_remote()`.
* `daemons()` and `dispatcher()` gain the argument 'pass' to support password-protected private keys when supplying TLS credentials (thanks @wlandau #76).
* Cryptographic errors when using dispatcher with TLS are now reported to the user (thanks @wlandau #76).
* Passing a filename to the 'tls' argument of `daemons()`, `launch_local()` or `launch_remote()` now works correctly as documented.
* Extends and clarifies documentation surrounding use of certificate authority signed TLS certificates.
* Certain error messages are more accurate and informative.
* Increases in performance and lower resource utilisation due to updates in nanonext 0.10.0.
* Requires nanonext >= 0.10.0 and R >= 3.5.

# mirai 0.9.1

* Secure TLS connections implemented for distributed computing:
  + Zero-configuration experience - simply specify a `tls+tcp://` or `wss://` URL in `daemons()`. Single-use keys and certificates are automatically generated.
  + Alternatively, custom certificates may be passed to the 'tls' argument of `daemons()` and `daemon()`, such as those generated via a Ceritficate Signing Request (CSR) to a Certificate Authority (CA).
* `launch_remote()` launches daemons on remote machines and/or returns the shell command for launching daemons as a character vector.
  + Example using SSH: `launch_remote("ws://192.168.0.1:5555", command = "ssh", args = c("-p 22 192.168.0.2", .)`.
* User interface optimised for consistency and ease of use:
  + Documentation updated to refer consistently to host and daemons (rather than client and server) for clarity.
  + `daemon()` replaces `server()`, which is deprecated (although currently retained as an alias).
  + `launch_local()` replaces `launch_server()` and now accepts a vector argument for 'url' as well as numeric values to select the relevant dispatcher or host URL, returning invisible NULL instead of an integer value.
  + `status()` now retrieves connections and daemons status, replacing the call to `daemons()` with no arguments (which is deprecated). The return value of `$daemons` is now always the host URL when not using dispatcher.
* Redirection of stdout and stderr from local daemons to the host process is now possible (when running without dispatcher) by specifying `output=TRUE` for `daemons()` or `launch_local()`. `daemon()` accepts a new 'output' argument.
* `saisei()` argument validation now happens prior to sending a request to dispatcher rather than on dispatcher.
* A 'miraiError' now includes the trailing line break at the end of the character vector.
* Requires nanonext >= 0.9.1, with R requirement relaxed back to >= 2.12.

# mirai 0.9.0

* mirai 0.9.0 is a major release focusing on stability improvements. 
* Improvements to dispatcher:
  + Ensures the first URL retains the same format if `saisei(i = 1L)` is called.
  + Optimal scheduling when tasks are submitted prior to any servers coming online.
  + Fixes rare occasions where dispatcher running a single server instance could get stuck with a task.
  + `daemons()` status requests have been rendered more robust.
* Ensures `saisei()` always returns `NULL` if 'tcp://' URLs are being used as they do not support tokens.
* Daemons status matrix 'assigned' and 'complete' are now cumulative statistics, and not reset upon new instances.
* Requires nanonext >= 0.9.0 and R >= 3.5.0.
* Internal performance enhancements.

# mirai 0.8.7

* `server()` and `dispatcher()` argument 'asyncdial' is now FALSE by default, causing these functions to exit if a connection is not immediately available. This means that for distributed computing purposes, `daemons()` should be called before `server()` is launched on remote resources, or else `server(asyncdial = TRUE)` allows servers to wait for a connection.
* `launch_server()` now parses the passed URL for correctness before attempting to launch a server, producing an error if not valid.

# mirai 0.8.4

* The deferred evaluation pipe `%>>%` gains the following enhancements:
  + `.()` implemented to wrap a piped expression, ensuring return of either an 'unresolvedExpr' or 'resolvedExpr'.
  + expressions may be tested using `unresolved()` in the same way as a 'mirai'.
  + allows for general use in all contexts, including within functions.
* Improved error messages for top level evaluation errors in a 'mirai'.
* Requires nanonext >= 0.8.3.
* Internal stability and performance enhancements.

# mirai 0.8.3

* `mirai()` gains the following enhancements (thanks @HenrikBengtsson):
  + accepts a language or expression object being passed to '.expr' for evaluation.
  + accepts a list of 'name = value' pairs being passed to '.args' as well as the existing '...'.
  + objects specified via '...' now take precedence over '.args' if the same named object appears.
* `dispatcher()` gains the following arguments:
  + `token` for appending a unique token to each URL the dispatcher listens at.
  + `lock` for locking sockets to prevent more than one server connecting at a unique URL.
* `saisei()` implemented to regenerate the token used by a given dispatcher socket.
* `launch_server()` replaces `launch()` for launching local instances, with a simpler interface directly mapping to `server()`.
* Automatically-launched local daemons revised to use unique tokens in their URLs.
* Daemons status matrix headers updated to 'online', 'instance', 'assigned', and 'complete'.
* Fixes potential issue when attempting to use `mirai()` with timeouts and no connection to a server.
* Requires nanonext >= 0.8.2.
* Internal performance enhancements.

# mirai 0.8.2

* `dispatcher()` re-implemented using an innovative non-polling design. Efficient process consumes zero processor usage when idle and features significantly higher throughput and lower latency.
  + Arguments 'pollfreqh' and 'pollfreql' removed as no longer applicable.
* Server and dispatcher processes exit automatically if the connection with the client is dropped. This significantly reduces the likelihood of orphaned processes.
* `launch()` exported as a utility for easily re-launching daemons that have timed out, for instance.
* Correct passthrough of `...` variables in the `daemons()` call.
* Requires nanonext >= 0.8.1.
* Internal performance enhancements.

# mirai 0.8.1

* Fixes issue where daemon processes may not launch for certain setups (only affecting binary package builds).

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
