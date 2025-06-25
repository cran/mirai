# mirai 2.4.0

#### Behavioural Changes

* An ephemeral daemon started by `mirai()` without setting daemons now exits as soon as the parent process does rather than finish the task.
  For previous behaviour use: `with(daemons(1L, dispatcher = FALSE, autoexit = NA), mirai(...))`.
* Change in `daemon()` defaults:
  + Argument `autoexit` default of `TRUE` now ensures daemons are terminated along with the parent process.
    Set to `NA` to retain the previous behaviour of having them automatically exit after completing any in-progress tasks.
  + Argument `dispatcher` now defaults to `TRUE`.
* Calling `daemons()` to create local daemons now errors if performed within a `mirai_map()` call.
  This guards against excessive spawning of local processes on a single machine.

#### New Features

* Adds `cluster_config()` to launch remote daemons via HPC resource managers for Slurm, SGE, Torque, PBS and LSF clusters.
* Adds `require_daemons()` as a developer function that prompts the user to set daemons if not already set, with a clickable function link if the cli package is available.

#### Updates

* Simplifies launches when using dispatcher - `launch_remote()` commands are now the same irrespective of the number of launches.
  This is as daemons now retrieve the next RNG stream from dispatcher rather than the `rs` argument to `daemon()`.
* Deprecated `call_mirai_()` is now removed.
* Requires nanonext >= 1.6.1.

# mirai 2.3.0

#### Behavioural Changes

* `mirai()` argument `.timeout` is upgraded to automatically cancel ongoing mirai upon timeout when using dispatcher (thanks @be-marc, @sebffischer #251).
* `serial_config()` now accepts vector arguments to register multiple custom serialization configurations. Argument `vec` is dropped as internal optimizations mean this option no longer needs to be set.

#### New Features

* `host_url()` is upgraded to return all local IP addresses (named by network interface), which provides a more comprehensive solution than just using a hostname.
* Adds `register_serial()` to register serialization configurations for all `daemons()` calls (may be used by package authors as a convenience).
* Adds `on_daemon()` which returns a logical value, whether or not evaluation is taking place within a mirai call on a daemon.
* Adds `daemons_set()` which returns a logical value, whether or not daemons are set for a given compute profile.
* `daemons()` now supports initial synchronization exceeding 10s (between host/dispatcher/daemons). This is particularly relevant for HPC setups (thanks @sebffischer, #275).

#### Updates

* For all functions that use `.compute`, this argument has a new default of `NULL`, which continues to use the `default` profile (and hence should not result in any change in behaviour).
* Fixes `stop_mirai()` failing to interrupt in certain cases on non-Windows platforms, and more robust interruption if `tools::SIGINT` is supplied or passed through to the `autoexit` argument of `daemon()` (thanks @LennardLux, #240).
* `daemons()` dispatcher argument 'process', deprecated in mirai v2.1.0, is removed.
* Requires nanonext >= 1.6.0.
* Package is re-licensed under the MIT license.

# mirai 2.2.0

#### Behavioural Changes

* Simplified SSH tunnelling for distributed computing:
  + `ssh_config()` argument 'port' is removed, with the tunnel port now inferred at the time of launch, and no longer set by the configuration.
  + `local_url()` adds logical argument 'tcp' for easily constructing an automatic local TCP URL when setting `daemons()` for SSH tunnelling.

#### New Features

* Adds `as.promise()` method for 'mirai_map' objects. This will resolve upon completion of the entire map operation.

#### Updates

* mirai (in R >= 4.5) is now one of the official base R parallel cluster types.
  + `register_cluster()` is removed as no longer required.
  + Directly use `parallel::makeCluster(type = "MIRAI")` to create a 'miraiCluster'.
* `call_mirai()` is now user-interruptible, consistent with all other functions in the package.
  + `call_mirai_()` is hence redundant and now deprecated.
* `with()` method for `daemons()` now propagates ".compute" so that this does not need to be specified in functions such as `mirai()` within the `with()` clause.
* `mirai()` arguments `...` and `.args` now accept environments containing variables beginning with a dot `.` (#207).
* 'miraiError' stack traces no longer sometimes contain an additional (internal) call (#216).
* 'miraiError' condition `$call` objects are now stripped of 'srcref' attributes (thanks @lionel-, #218).
* A mirai promise now rejects in exactly the same way whether or not the mirai was already resolved at time of creation.
  This avoids Shiny deep stack trace errors when the mirai had already resolved (#229).
* `daemons()` calls that error due to the remote launcher no longer leave the compute profile set up (#237).

# mirai 2.1.0

#### Behavioural Changes

* `daemons()` now requires an explicit reset before providing revised settings for a compute profile, and will error otherwise.
* `mirai_map()` now errors if daemons have not yet been set (rather than warn and launch one local daemon).
* Removal of mirai v1 compatibility features:
  + `saisei()` is now removed as no longer required.
  + `daemons()` dispatcher argument "thread" is removed.
  + `daemons()` dispatcher arguments "process" and "none" are formally deprecated and will be removed in a future version.

#### Updates

* 'miraiError' evaluation errors now return the call stack at `$stack.trace` as a list of calls (with srcrefs removed) without deparsing to character strings.
* `mirai_map()` improvements:
  + Multiple map on a dataframe or matrix now correctly preserves the row names of the input as the names of the output.
  + Fixes language objects being evaluated before the map function is applied (#194).
  + Fixes classes of objects in a dataframe being dropped during a multiple map (#196).
  + Better `cli` errors when collecting a 'mirai_map'.
* Fixes `daemons(NULL)` not causing all daemons started with `autoexit = FALSE` to quit, regression introduced in mirai v2.0.0.
* Requires nanonext >= 1.5.0.

# mirai 2.0.1

#### Updates

* `mirai_map()` collection option improvements:
  + The cli package is used, if installed, for richer progress bars and error messages.
  + `[.progress_cli]` is no longer a separate option.
  + `[.stop]` now reports the index number that errored.
* `collect_mirai()` replaces '...' with an 'options' argument, to which collection options should be supplied as a character vector. This avoids non-standard evaluation in this function.
* `daemon()` now returns an integer exit code to indicate the reason for termination.
* Adds `nextcode()` to provide a human-readable translation of the exit codes returned by `daemon()`.
* `everywhere()` now returns a list of at least one mirai regardless of the number of actual connections.

# mirai 2.0.0

#### New Architecture

* Distributed computing now uses a single socket and URL at which all daemons connect (with or without dispatcher).
  + Allows a more efficient `tcp://` or `tls+tcp://` connection in all cases.
  + The number of connected daemons may be upscaled or downscaled at any time without limit.

#### New Features

* `daemons(dispatcher = TRUE)` provides a new and more efficient architecture for dispatcher. This argument reverts to a logical value, although 'process' is still accepted and retains the previous behaviour of the v1 dispatcher.
* `daemons()` gains argument 'serial' to register serialization configurations when using dispatcher. These automatically apply to all daemons that connect.
* `stop_mirai()` is now able to cancel remote mirai tasks (when using dispatcher), returning a logical value indicating whether cancellation was successful.
* A 'miraiError' now preserves the original condition object. This means that `rlang::abort()` custom metadata may now be accessed using `$` on the 'miraiError' (thanks @James-G-Hill #173).

#### Updates

* `status()` using the new dispatcher is updated to provide more concise and insightful information.
* `everywhere()` updates:
  + Enhanced to return a list of mirai, which may be waited for and inspected (thanks @dgkf, #164).
  + Drops argument '.serial' as serialization configurations are now registered via an argument at `daemons()`.
* `daemon()` updates:
  + Gains the new argument 'dispatcher', which should be set to `TRUE` when connecting to dispatcher and `FALSE` when connecting directly to host.
  + Gains argument 'id' which accepts an integer value that allows `status()` to track connection and disconnection events.
  + '...' has been moved up to prevent partial matching on any of the optional arguments.
  + 'cleanup' argument simplified to a TRUE/FALSE value.
  + 'timerstart' argument removed.
* `launch_local()` and `launch_remote()` updates:
  + Enhanced to now launch daemons with the originally-supplied arguments by default.
  + Simplified to take the argument 'n' instead of 'url' for how many daemons to launch.
  + `launch_local()` now returns the number of daemons launched rather than invisible NULL.
* `collect_mirai()` is now interruptible and takes a '...' argument accepting the collection options provided to the 'mirai_map' `[]` method, such as `.flat` etc.
* `ssh_config()` simplified to take the argument 'port' instead of 'host'. For SSH tunnelling, this is the port that will be used, and the hostname is now required to be '127.0.0.1' (no longer accepting 'localhost').
* `host_url()` argument 'ws' is removed as a TCP URL is now always recommended (although websocket URLs are still supported).
* `saisei()` is defunct as no longer required, but still available for use with the old v1 dispatcher.
* `daemons(dispatcher = "thread")` (experimental threaded dispatcher) has been retired - as this was based on the old dispatcher architecture and future development will focus on the current design. Specifying 'dispatcher = thread' is defunct, but will point to 'dispatcher = process' for the time being.
* Requires `nanonext` >= 1.4.0.

# mirai 1.3.1

#### Updates

* Cleanup of packages only detaches them from the search path and does not attempt to unload them, as it is not always safe to do so. Fixes daemon crashes using packages such as `data.table` (thanks @D3SL, #166).
* `serialization()` deprecated in mirai 1.2.0 is now removed.

# mirai 1.3.0

#### New Features

* `daemons(dispatcher = "thread")` implements threaded dispatcher (experimental), a faster and more efficient alternative to running dispatcher in a separate process.
* `mirai_map()` adds `[.progress_cli]` as an alternative progress indicator, using the cli package to show % complete and ETA.
* `daemons()` gains argument 'force' to control whether further calls reset previous settings for the same compute profile.
* `daemon()` gains argument 'asyncdial' to allow control of connection behaviour independently of what happens when the daemon exits.

#### Behavioural Changes

* For `daemons()`:
  - Argument 'dispatcher' now takes the character options 'process', 'thread' and 'none'. Previous values of TRUE/FALSE continue to be accepted (thanks @hadley #157).
  - Return value is now always an integer - either the number of daemons set if using dispatcher, or the number of daemons launched locally (zero if using a remote launcher).
  - Invalid type of `...` arguments are now dropped instead of throwing an error. This allows `...` containing unused arguments to be more easily passed from other functions.
* For `mirai_map()`:
  - Now only performs multiple map over the rows of matrices and dataframes (thanks @andrewGhazi, #147).
  - Combining collection options is now easier, in the fashion of: `x[.stop, .progress]`.
  - Collection options now work even if mirai is not on the search path e.g. `mirai::mirai_map(1:4, Sys.sleep)[.progress]`.
* `dispatcher()` drops argument 'asyncdial' as it is rarely useful to set this here.
* `everywhere()` now errors if the specified compute profile is not yet set up, rather than fail silently.
* `launch_local()` and `launch_remote()` now strictly require daemons to be set, and will error otherwise.
* `serial_config()` now validates the arguments provided and returns them as a list. This means any saved configurations from previous package versions must be re-generated.

#### Updates

* Fixes `daemons()` to correctly handle a vector of URLs passed to 'url' again.
* Fixes flatmap with `mirai_map()[.flat]` assigning a variable 'typ' to the calling environment.
* Performance enhancements for `mirai()`, `mirai_map()` and the promises method.
* Requires `nanonext` >= 1.3.0.
* The package has a shiny new hex logo.

# mirai 1.2.0

* `everywhere()` adds argument '.serial' to accept serialization configurations created by `serial_config()`. These allow normally non-exportable reference objects such as Arrow Tables or torch tensors to be used seamlessly across parallel processes without additional marshalling steps. Configurations apply on a per compute profile basis.
* `serialization()` is now deprecated in favour of the above usage of `everywhere()`, and will be removed in a future version.
* `mirai_map()` enhanced to perform multiple map over 2D lists/vectors, allowing advanced patterns such as mapping over the rows of a dataframe or matrix.
* 'mirai_map' `[]` method gains the option `[.flat]` to collect and flatten results, avoiding coercion.
* Collecting a 'mirai_map' no longer spuriously introduces empty names where none were present originally.
* Faster local `daemons(dispatcher = FALSE)` and `make_cluster()` by using asynchronous launches (thanks @mtmorgan #123).
* Local dispatcher daemons now synchronize with host, the same as non-dispatcher daemons (prevents use before all have connected).
* Fixes rare cases of `everywhere()` not reaching all daemons when using dispatcher.
* More efficient dispatcher startup by only loading the base package, in addition to not reading startup configurations (thanks @krlmlr).
* Removes hard dependency on `stats` and `utils` base packages.
* Requires `nanonext` >= 1.2.0.

# mirai 1.1.1

* `serialization()` function signature and return value slightly modified for clarity. Successful registration / cancellation messages are no longer printed to the console.
* `dispatcher()` argument 'retry' now defaults to FALSE for consistency with non-dispatcher behaviour.
* `remote_config()` gains argument 'quote' to control whether or not to quote the daemon launch command, and now works with Slurm (thanks @michaelmayer2 #119).
* Ephemeral daemons now exit as soon as permissible, eliminating the 2s linger period.
* Requires `nanonext` >= 1.1.1.

# mirai 1.1.0

* Adds `mirai_map()` for asynchronous parallel/distributed map using `mirai`, with `promises` integration. Allows recovery from partial failure or else early stopping, together with optional progress reporting.
  + `x[]` collects the results of a mirai_map `x`, waiting for all asynchronous operations to complete.
  + `x[.progress]` collects the results whilst showing a text progress bar.
  + `x[.stop]` collects the results applying early-stopping, which stops at the first error, and aborts remaining in-progress operations.
* Adds the 'mirai' method `x[]` as a more efficient equivalent of the interruptible `call_mirai_(x)$data`.
* Adds `collect_mirai()` as a more efficient equivalent of the non-interruptible `call_mirai(x)$data`.
* `unresolved()`, `call_mirai()`, `collect_mirai()` and `stop_mirai()` now accept a list of 'mirai' such as that returned by `mirai_map()`.
* Improved mirai print method indicates whether a mirai has resolved.
* Calling `daemons()` with new settings when the compute profile is already set now implicitly resets daemons before applying the new settings instead of silently doing nothing.
* Argument 'resilience' retired at `daemons()` as automatic re-tries are no longer performed for non-dispatcher daemons.
* New argument 'retry' at `dispatcher()` governs whether to auto-retry in the dispatcher case.
* Fixes promises method for potential crashes when launching improbably short-lived mirai.
* Fixes bug that could cause a hang or crash when launching additional non-dispatcher daemons.
* Requires `nanonext` >= 1.1.0.

# mirai 1.0.0

* Implements completely event-driven (non-polling) promises (thanks @jcheng5 for prototyping).
  + This is an innovation which allows higher responsiveness and massive scalability for 'mirai' promises.
* Behavioural changes to `mirai()` and `everywhere()`:
  + (breaking change) no longer permits an unnamed list to be supplied to '.args'.
  + allows an environment e.g. `environment()` to be supplied to '.args' or as the only element of '...'.
  + allows evaluation of a symbol in the 'mirai' environment, e.g. `mirai(x, x = 1)`.
* `ssh_config()` improvements:
  + new argument 'host' allows specifying the localhost URL and port to create a standalone configuration object.
  + order of arguments 'tunnel' and 'timeout' reversed.
* `stop_mirai()` now resolves to an 'errorValue' 20 (operation canceled) in the case the asynchronous task was still ongoing (thanks @jcheng5 #110).
* Rejected promises now show the complete error code and message in the case of an 'errorValue'.
* A 'miraiError' reverts to not including a trailing line break (as prior to mirai 0.13.2).
* Non-dispatcher local daemons now synchronize with host in all cases (prevents use before all have connected).
* `[` method for 'miraiCluster' no longer produces a 'miraiCluster' object (thanks @HenrikBengtsson #83).
* Faster startup time as the `parallel` package is now only loaded when first used.
* Requires `nanonext` >= 1.0.0.

# mirai 0.13.2

* `mirai()` and `everywhere()` behaviour changed such that '...' args are now assigned to the global environment of the daemon process.
* Adds `with()` method for mirai daemons, allowing for example: `with(daemons(4), {expr})`, where the daemons last for the duration of 'expr'.
* Adds `register_cluster()` for registering 'miraiCluster' as a parallel Cluster type (requires R >= 4.4).
* Adds `is.promising()` method for 'mirai' for the promises package.
* A 'miraiError' now includes the full call stack, which may be accessed at `$stack.trace`, and includes the trailing line break for consistency with 'as.character.error()'.
* mirai promises now preserve deep stacks when a 'miraiError' occurs within a Shiny app (thanks @jcheng5 #104).
* Simplified registration for 'parallel' and 'promises' methods (thanks @jcheng5 #103).
* Fixes to promises error handling and Shiny vignette (thanks @jcheng5 #98 #99).
* Requires R >= 3.6.

# mirai 0.13.1

* Fixes regression in mirai 0.12.1, which introduced the potential for unintentional low level errors to emerge when querying dispatcher (thanks @dsweber2 for reporting in downstream {targets}).

# mirai 0.13.0

* `serialization` adds arguments 'class' and 'vec' for custom serialisation of all reference object types.
* Requires nanonext >= 0.13.3.

# mirai 0.12.1

* Dispatcher initial sync timeout widened to 10s to allow for launching large numbers of daemons.
* Default for `ssh_config()` argument 'timeout' widened to 10 (seconds).
* Fixes `daemons()` specifying 'output = FALSE' registering as TRUE instead.
* Fixes use of `everywhere()` specifying '.args' as an unnamed list or '.expr' as a language object.
* Ensures compatibility with nanonext >= 0.13.0.
* Internal performance enhancements.

# mirai 0.12.0

* More minimal print methods for 'mirai' and 'miraiCluster'.
* Adds `local_url()` helper to construct a random inter-process communications URL for local daemons (thanks @noamross #90).
* `daemon()` argument 'autoexit' now accepts a signal value such as `tools::SIGINT` in order to raise it upon exit.
* `daemon()` now records the state of initial global environment objects (e.g. those created in .Rprofile) for cleanup purposes (thanks @noamross #91).
* Slightly more optimal `as.promise()` method for 'mirai'.
* Eliminates potential memory leaks along certain error paths.
* Requires nanonext >= 0.12.0.

# mirai 0.11.3

* Implements `serialization()` for registering custom serialization and unserialization functions when using daemons.
* Introduces `call_mirai_()`, a user-interruptible version of `call_mirai()` suitable for interactive use.
* Simplification of `mirai()` interface:
  + '.args' will now coerce to a list if an object other than a list is supplied, rather than error.
  + '.signal' argument removed - now all 'mirai' signal if daemons are set up.
* `everywhere()` now returns invisible NULL in the case the specified compute profile is not set up, rather than error.
* `mirai()` specifying a timeout when `daemons()` has not been set - the timeout begins immediately rather than after the ephemeral daemon has connected - please factor in a small amount of time for the daemon to launch.
* `make_cluster()` now prints daemon launch commands where 'url' is specified without 'remote' whether or not interactive.
* Cluster node failures during load balanced operations now rely on the 'parallel' mechanism to error and no longer fail early or automatically stop the cluster.
* Fixes regression since 0.11.0 which prevented dispatcher exiting in a timely manner when tasks are backlogged (thanks @wlandau #86).
* Improved memory efficiency and stability at dispatcher.
* No longer loads the 'promises' package if not already loaded (but makes the 'mirai' method available via a hook function).
* Requires nanonext >= 0.11.0.

# mirai 0.11.2

* `make_cluster()` specifying only 'url' now succeeds with implied 'n' of one.
* Fixes `mirai()` specifying a language object by name for '.expr' in R versions 4.0 and earlier. 
* Fixes regression in 0.11.1 which prevented the correct random seed being set when using dispatcher.
* Internal performance enhancements.

# mirai 0.11.1

* Adds 'mirai' method for 'as.promise()' from the {promises} package (if available). This functionality is merged from the package {mirai.promises}, allowing use of the promise pipe `%...>%` with a 'mirai'.
* Parallel clusters (the alternative communications backend for R) now work with existing R versions, no longer requiring R >= 4.4.
* `everywhere()` evaluates an expression 'everywhere' on all connected daemons for a compute profile. Resulting changes to the global environment, loaded pacakges or options are persisted regardless of the 'cleanup' setting (request by @krlmlr #80).
* `host_url()` implemented as a helper function to automatically construct the host URL using the computer's hostname.
* `daemon()` adds argument 'autoexit', which replaces 'asyncdial', to govern persistence settings for a daemon. A daemon can now survive a host session and re-connect to another one (request by @krlmlr #81).
* `daemons(NULL)` implemented as a variant of `daemons(0)` which also sends exit signals to connected persistent daemons.
* `dispatcher()` argument 'lock' removed as this is now applied in all cases to prevent more than one daemon dialling into a dispatcher URL at any one time.
* `daemon()` argument 'cleanup' simplified to a logical argument, with more granular control offered by the existing integer bitmask (thanks @krlmlr #79).
* Daemons connecting over TLS now perform synchronous dials by default (as documented).
* Fixes supplying an `ssh_config()` specifying tunnelling to the 'remote' argument of `daemons()`.
* Fixes the print method for a subset 'miraiCluster' (thanks @HenrikBengtsson #83).
* Removes the deprecated deferred evaluation pipe `%>>%`.
* Requires nanonext >= 0.10.4.

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
