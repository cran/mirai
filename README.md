
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai?color=112d4e)](https://CRAN.R-project.org/package=mirai)
[![mirai status
badge](https://shikokuchuo.r-universe.dev/badges/mirai?color=24a60e)](https://shikokuchuo.r-universe.dev)
[![R-CMD-check](https://github.com/shikokuchuo/mirai/workflows/R-CMD-check/badge.svg)](https://github.com/shikokuchuo/mirai/actions)
[![codecov](https://codecov.io/gh/shikokuchuo/mirai/branch/main/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/mirai)
[![DOI](https://zenodo.org/badge/459341940.svg)](https://zenodo.org/badge/latestdoi/459341940)
<!-- badges: end -->

Minimalist async evaluation framework for R. <br /><br /> Lightweight
parallel code execution and distributed computing. <br /><br /> Designed
for simplicity, a ‘mirai’ evaluates an R expression asynchronously, on
local or network resources, resolving automatically upon completion.
<br /><br /> Features efficient task scheduling, fast inter-process
communications, and Transport Layer Security over TCP/IP for remote
connections, courtesy of ‘nanonext’ and ‘NNG’ (Nanomsg Next Gen).
<br /><br /> `mirai()` returns a ‘mirai’ object immediately. ‘mirai’
(未来 みらい) is Japanese for ‘future’. <br /><br />
[`mirai`](https://doi.org/10.5281/zenodo.7912722) has a tiny pure R code
base, relying solely on
[`nanonext`](https://doi.org/10.5281/zenodo.7903429), a high-performance
binding for the ‘NNG’ (Nanomsg Next Gen) C library with zero package
dependencies. <br /><br />

### Table of Contents

1.  [Installation](#installation)
2.  [Example 1: Compute-intensive
    Operations](#example-1-compute-intensive-operations)
3.  [Example 2: I/O-bound Operations](#example-2-io-bound-operations)
4.  [Example 3: Resilient Pipelines](#example-3-resilient-pipelines)
5.  [Daemons: Local Persistent
    Processes](#daemons-local-persistent-processes)
6.  [Distributed Computing: Remote
    Daemons](#distributed-computing-remote-daemons)
7.  [Distributed Computing: TLS Secure
    Connections](#distributed-computing-tls-secure-connections)
8.  [Compute Profiles](#compute-profiles)
9.  [Errors, Interrupts and Timeouts](#errors-interrupts-and-timeouts)
10. [Deferred Evaluation Pipe](#deferred-evaluation-pipe)
11. [Integrations with Crew, Targets,
    Shiny](#integrations-with-crew-targets-shiny)
12. [Thanks](#thanks)
13. [Links](#links)

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

or the development version from rOpenSci R-universe:

``` r
install.packages("mirai", repos = "https://shikokuchuo.r-universe.dev")
```

[« Back to ToC](#table-of-contents)

### Example 1: Compute-intensive Operations

Use case: minimise execution times by performing long-running tasks
concurrently in separate processes.

Multiple long computes (model fits etc.) can be performed in parallel on
available computing cores.

Use `mirai()` to evaluate an expression asynchronously in a separate,
clean R process.

A ‘mirai’ object is returned immediately.

``` r
library(mirai)

m <- mirai(
  {
    res <- rnorm(n) + m
    res / rev(res)
  },
  m = runif(1),
  n = 1e8
)

m
#> < mirai >
#>  - $data for evaluated result
```

Above, all specified `name = value` pairs are passed through to the
‘mirai’.

The ‘mirai’ yields an ‘unresolved’ logical NA whilst the async operation
is ongoing.

``` r
m$data
#> 'unresolved' logi NA
```

Upon completion, the ‘mirai’ resolves automatically to the evaluated
result.

``` r
m$data |> str()
#>  num [1:100000000] -9.0846 17.02104 0.57708 0.00754 -0.11816 ...
```

Alternatively, explicitly call and wait for the result using
`call_mirai()`.

``` r
call_mirai(m)$data |> str()
#>  num [1:100000000] -9.0846 17.02104 0.57708 0.00754 -0.11816 ...
```

For easy programmatic use of `mirai()`, ‘.expr’ accepts a
pre-constructed language object, and also a list of named arguments
passed via ‘.args’. So, the following would be equivalent to the above:

``` r
expr <- quote({
  res <- rnorm(n) + m
  res / rev(res)
})

args <- list(m = runif(1), n = 1e8)

m <- mirai(.expr = expr, .args = args)

call_mirai(m)$data |> str()
#>  num [1:100000000] -1.389 1.052 -2.553 17.528 -0.794 ...
```

[« Back to ToC](#table-of-contents)

### Example 2: I/O-bound Operations

Use case: ensure execution flow of the main process is not blocked.

High-frequency real-time data cannot be written to file/database
synchronously without disrupting the execution flow.

Cache data in memory and use `mirai()` to perform periodic write
operations concurrently in a separate process.

Below, ‘.args’ is used to pass a list of objects already present in the
calling environment to the mirai by name. This is an alternative use of
‘.args’, and may be combined with `...` to also pass in `name = value`
pairs.

``` r
library(mirai)

x <- rnorm(1e6)
file <- tempfile()

m <- mirai(write.csv(x, file = file), .args = list(x, file))
```

A ‘mirai’ object is returned immediately.

`unresolved()` may be used in control flow statements to perform actions
which depend on resolution of the ‘mirai’, both before and after.

This means there is no need to actually wait (block) for a ‘mirai’ to
resolve, as the example below demonstrates.

``` r
# unresolved() queries for resolution itself so no need to use it again within the while loop

while (unresolved(m)) {
  cat("while unresolved\n")
  Sys.sleep(0.5)
}
#> while unresolved
#> while unresolved

cat("Write complete:", is.null(m$data))
#> Write complete: TRUE
```

Now actions which depend on the resolution may be processed, for example
the next write.

[« Back to ToC](#table-of-contents)

### Example 3: Resilient Pipelines

Use case: isolating code that can potentially fail in a separate process
to ensure continued uptime.

As part of a data science / machine learning pipeline, iterations of
model training may periodically fail for stochastic and uncontrollable
reasons (e.g. buggy memory management on graphics cards).

Running each iteration in a ‘mirai’ isolates this
potentially-problematic code such that even if it does fail, it does not
bring down the entire pipeline.

``` r
library(mirai)

run_iteration <- function(i) {
  
  if (runif(1) < 0.1) stop("random error", call. = FALSE) # simulates a stochastic error rate
  sprintf("iteration %d successful\n", i)
  
}

for (i in 1:10) {
  
  m <- mirai(run_iteration(i), .args = list(run_iteration, i))
  while (is_error_value(call_mirai(m)$data)) {
    cat(m$data)
    m <- mirai(run_iteration(i), .args = list(run_iteration, i))
  }
  cat(m$data)
  
}
#> iteration 1 successful
#> iteration 2 successful
#> iteration 3 successful
#> iteration 4 successful
#> iteration 5 successful
#> Error: random error
#> iteration 6 successful
#> iteration 7 successful
#> iteration 8 successful
#> iteration 9 successful
#> iteration 10 successful
```

Further, by testing the return value of each ‘mirai’ for errors,
error-handling code is then able to automate recovery and re-attempts,
as in the above example. Further details on [error
handling](#errors-interrupts-and-timeouts) can be found in the section
below.

The end result is a resilient and fault-tolerant pipeline that minimises
downtime by eliminating interruptions of long computes.

[« Back to ToC](#table-of-contents)

### Daemons: Local Persistent Processes

Daemons, or persistent background processes, may be set to receive
‘mirai’ requests.

This is potentially more efficient as new processes no longer need to be
created on an *ad hoc* basis.

#### With Dispatcher (default)

Call `daemons()` specifying the number of daemons to launch.

``` r
daemons(6)
#> [1] 6
```

To view the current status, `status()` provides the number of active
connections along with a matrix of statistics for each daemon.

``` r
status()
#> $connections
#> [1] 1
#> 
#> $daemons
#>                                                     i online instance assigned complete
#> abstract://9266a70addf7098c0cd43382d18433c4aa66836c 1      1        1        0        0
#> abstract://a4afd1471f6f9e3f3945f4f7593a778faf3d98bd 2      1        1        0        0
#> abstract://0f558157141354dc3f19eaa9320888dd18e38219 3      1        1        0        0
#> abstract://1f4066a857f952d29cd9f1bca055df638eab7e53 4      1        1        0        0
#> abstract://2593f6cc3119d9a70167b2f0ed86f64dba3b2f93 5      1        1        0        0
#> abstract://11823f25ab25529ff7be43e93a1fd1692c312e37 6      1        1        0        0
```

The default `dispatcher = TRUE` creates a `dispatcher()` background
process that connects to individual daemon processes on the local
machine. This ensures that tasks are dispatched efficiently on a
first-in first-out (FIFO) basis to daemons for processing. Tasks are
queued at the dispatcher and sent to a daemon as soon as it can accept
the task for immediate execution.

Dispatcher uses synchronisation primitives from
[`nanonext`](https://doi.org/10.5281/zenodo.7903429), waiting upon
rather than polling for tasks, which is efficient both in terms of
consuming no resources while waiting, and also being fully synchronised
with events (having no latency).

``` r
daemons(0)
#> [1] 0
```

Set the number of daemons to zero to reset. This reverts to the default
of creating a new background process for each ‘mirai’ request.

#### Without Dispatcher

Alternatively, specifying `dispatcher = FALSE`, the background daemons
connect directly to the host process.

``` r
daemons(6, dispatcher = FALSE)
#> [1] 6
```

Requesting the status now shows 6 connections, along with the host URL
at `$daemons`.

``` r
status()
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "abstract://433b4a53c73415653ff7a11afc91c7d389c37a11"
```

This implementation sends tasks immediately, and ensures that tasks are
evenly-distributed amongst daemons. This means that optimal scheduling
is not guaranteed as the duration of tasks cannot be known *a priori*.
As an example, tasks could be queued at a daemon behind a long-running
task, whilst other daemons remain idle.

The advantage of this approach is that it is low-level and does not
require an additional dispatcher process. It is well-suited to working
with similar-length tasks, or where the number of concurrent tasks
typically does not exceed available daemons.

``` r
daemons(0)
#> [1] 0
```

Set the number of daemons to zero to reset.

[« Back to ToC](#table-of-contents)

### Distributed Computing: Remote Daemons

The daemons interface may also be used to send tasks for computation to
remote daemon processes on the network.

Call `daemons()` specifying ‘url’ as a character string the host network
address and a port that is able to accept incoming connections.

The examples below use an illustrative local network IP address of
‘10.75.48.93’.

A port on the host machine also needs to be open and available for
inbound connections from the local network, illustratively ‘5555’ in the
examples below.

IPv6 addresses are also supported and must be enclosed in square
brackets `[]` to avoid confusion with the final colon separating the
port. For example, port 5555 on the IPv6 address `::ffff:a6f:50d` would
be specified as `tcp://[::ffff:a6f:50d]:5555`.

#### Connecting to Remote Daemons Through Dispatcher

The default `dispatcher = TRUE` creates a background `dispatcher()`
process on the local machine, which listens to a vector of URLs that
remote `daemon()` processes dial in to, with each daemon having its own
unique URL.

It is recommended to use a websocket URL starting `ws://` instead of TCP
in this scenario (used interchangeably with `tcp://`). A websocket URL
supports a path after the port number, which can be made unique for each
daemon. In this way a dispatcher can connect to an arbitrary number of
daemons over a single port.

``` r
daemons(n = 4, url = "ws://10.75.48.93:5555")
#> [1] 4
```

Above, a single URL was supplied, along with `n = 4` to specify that the
dispatcher should listen at 4 URLs. In such a case, an integer sequence
is automatically appended to the path `/1` through `/4` to produce these
URLs.

Alternatively, supplying a vector of URLs allows the use of arbitrary
port numbers / paths, e.g.:

``` r
daemons(url = c("ws://10.75.48.93:5566/cpu", "ws://10.75.48.93:5566/gpu", "ws://10.75.48.93:7788/1"))
```

Above, ‘n’ is not specified, in which case its value is inferred from
the length of the ‘url’ vector supplied.

–

On the remote resource, `daemon()` may be called from an R session, or
directly from a shell using Rscript. Each daemon instance should dial
into one of the unique URLs that the dispatcher is listening at:

    Rscript -e 'mirai::daemon("ws://10.75.48.93:5555/1")'
    Rscript -e 'mirai::daemon("ws://10.75.48.93:5555/2")'
    Rscript -e 'mirai::daemon("ws://10.75.48.93:5555/3")'
    Rscript -e 'mirai::daemon("ws://10.75.48.93:5555/4")'

Note that `daemons()` should be set up on the host machine before
launching `daemon()` on remote resources, otherwise the daemon instances
will exit if a connection is not immediately available. Alternatively,
specifying `daemon(asyncdial = TRUE)` will allow daemons to wait
(indefinitely) for a connection to become available.

`launch_remote()` may also be used to launch daemons directly on a
remote machine. For example, if the remote machine at 10.75.48.100
accepts SSH connections over port 22:

``` r
launch_remote(1:4, command = "ssh", args = c("-p 22 10.75.48.100", .))
#> [1] "Rscript -e \"mirai::daemon('ws://10.75.48.93:5555/1',rs=c(10407,-977864279,-1747156650,1333456863,-746624876,1038762629,-1132657278))\""
#> [2] "Rscript -e \"mirai::daemon('ws://10.75.48.93:5555/2',rs=c(10407,1352113970,1853298848,-1722410285,-686612439,1770409637,-667076591))\"" 
#> [3] "Rscript -e \"mirai::daemon('ws://10.75.48.93:5555/3',rs=c(10407,-1894415476,2126239662,-790740277,-243155846,-1153709897,-483282337))\""
#> [4] "Rscript -e \"mirai::daemon('ws://10.75.48.93:5555/4',rs=c(10407,1191519305,1229444965,-184999102,1155940357,447444428,-2035816043))\""
```

The returned vector comprises the shell commands executed on the remote
machine.

–

Requesting status, on the host machine:

``` r
status()
#> $connections
#> [1] 1
#> 
#> $daemons
#>                         i online instance assigned complete
#> ws://10.75.48.93:5555/1 1      1        1        0        0
#> ws://10.75.48.93:5555/2 2      1        1        0        0
#> ws://10.75.48.93:5555/3 3      1        1        0        0
#> ws://10.75.48.93:5555/4 4      1        1        0        0
```

As per the local case, `$connections` shows the single connection to
dispatcher, however `$daemons` now provides a matrix of statistics for
the remote daemons.

- `i` index number.
- `online` shows as 1 when there is an active connection, or else 0 if a
  daemon has yet to connect or has disconnected.
- `instance` increments by 1 every time there is a new connection at a
  URL. This counter is designed to track new daemon instances connecting
  after previous ones have ended (due to time-outs etc.). The count
  becomes negative immediately after a URL is regenerated by `saisei()`,
  but increments again once a new daemon connects.
- `assigned` shows the cumulative number of tasks assigned to the
  daemon.
- `complete` shows the cumulative number of tasks completed by the
  daemon.

Dispatcher automatically adjusts to the number of daemons actually
connected. Hence it is possible to dynamically scale up or down the
number of daemons according to requirements (limited to the ‘n’ URLs
assigned).

To reset all connections and revert to default behaviour:

``` r
daemons(0)
#> [1] 0
```

Closing the connection causes the dispatcher to exit automatically, and
in turn all connected daemons when their respective connections with the
dispatcher are terminated.

#### Connecting to Remote Daemons Directly

By specifying `dispatcher = FALSE`, remote daemons connect directly to
the host process. The host listens at a single URL, and distributes
tasks to all connected daemons.

``` r
daemons(url = "tcp://10.75.48.93:0", dispatcher = FALSE)
```

Alternatively, simply supply a colon followed by the port number to
listen on all interfaces on the local host, for example:

``` r
daemons(url = "tcp://:0", dispatcher = FALSE)
#> [1] "tcp://:45225"
```

Note that above, the port number is specified as zero. This is a
wildcard value that will automatically cause a free ephemeral port to be
assigned. The actual assigned port is provided in the return value of
the call, or it may be queried at any time via `status()`.

–

On the network resource, `daemon()` may be called from an R session, or
an Rscript invocation from a shell. This sets up a remote daemon process
that connects to the host URL and receives tasks:

    Rscript -e 'mirai::daemon("tcp://10.75.48.93:45225")'

Note that `daemons()` should be set up on the host machine before
launching `daemon()` on remote resources, otherwise the daemon instances
will exit if a connection is not immediately available. Alternatively,
specifying `daemon(asyncdial = TRUE)` will allow daemons to wait
(indefinitely) for a connection to become available.

`launch_remote()` may also be used to launch daemons directly on a
remote machine. For example, if the remote machine at 10.75.48.100
accepts SSH connections over port 22:

``` r
launch_remote("tcp://10.75.48.93:45225", command = "ssh", args = c("-p 22 10.75.48.100", .))
#> [1] "Rscript -e \"mirai::daemon('tcp://10.75.48.93:45225',rs=c(10407,-1992782545,1319334308,-1219799979,-286271214,1562951019,1755913648))\""
```

The returned vector comprises the shell commands executed on the remote
machine.

–

The number of daemons connecting to the host URL is not limited and
network resources may be added or removed at any time, with tasks
automatically distributed to all connected daemons.

`$connections` will show the actual number of connected daemons.

``` r
status()
#> $connections
#> [1] 1
#> 
#> $daemons
#> [1] "tcp://:45225"
```

To reset all connections and revert to default behaviour:

``` r
daemons(0)
#> [1] 0
```

This causes all connected daemons to exit automatically.

[« Back to ToC](#table-of-contents)

### Distributed Computing: TLS Secure Connections

TLS is available as an option to secure communications from the local
machine to remote daemons.

#### Zero-configuration

An automatic zero-configuration default is implemented. Simply specify a
secure URL of the form `wss://` or `tls+tcp://` when setting daemons.
For example, on the IPv6 loopback address:

``` r
daemons(n = 4, url = "wss://[::1]:5555")
#> [1] 4
```

Single-use keys and certificates are automatically generated and
configured, without requiring any further intervention. The private key
is always retained on the host machine and never transmitted, nor even
materialised as an R object.

The generated self-signed certificate is made available for read-only
access via `launch_remote()`. This function conveniently constructs the
full shell command to launch a daemon, including the correctly specified
‘tls’ argument to `daemon()`.

``` r
launch_remote(1)
#> [1] "Rscript -e \"mirai::daemon('wss://[::1]:5555/1',tls=c('-----BEGIN CERTIFICATE-----\nMIIFLTCCAxWgAwIBAgIBATANBgkqhkiG9w0BAQsFADAuMQwwCgYDVQQDDAM6OjEx\nETAPBgNVBAoMCE5hbm9uZXh0MQswCQYDVQQGEwJKUDAeFw0wMTAxMDEwMDAwMDBa\nFw0zMDEyMzEyMzU5NTlaMC4xDDAKBgNVBAMMAzo6MTERMA8GA1UECgwITmFub25l\neHQxCzAJBgNVBAYTAkpQMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA\nuMjcxAk4njDBDkyrEgDxolZ5pvQOqjRQTgX9WlaxV7gC4wJ97o2ZGBa43adFOSMF\nJCaVTzBZkBZ85hARg6U9AWZLauHrM/bcsNoGPkwya9A9HfaXDVSyGbmKn0Su2CqA\n2PifphXmCm6GBCI+shw+xaVpYo8mXx32ERZCHnCsXZO3z26NI4lA1V2sjBv+j2eX\nBaOVsf3LsoK4/1m4OKALrGr8rJCd3Cc5zPh/VzZo54Au0fpzFTNLpcPT5avo12lt\nuUCUvSzSNaQS7lAG7ngVZb+rrMMlRw6IHEbn8np2gdPnR2fORVTNaYn5GetMcoHD\nuIfWUUItrcjG4mpKs6RHwQFECxR3VfWc7XJ6QMry4IuEa8EjJ+0oYLwHWTmzVUII\nwKxXPQbA7mN2VydAa5O6vmJtPYpkGERS3VocicaGTJATMdd3k7PMI1fnJf0wptCi\nmU66vAc7PhCy9w+WDN2MjtXZFtWDF/qVP+zK0DNsEKLk2DF0h7/ywYkTHxDAyPKD\nfUi0qbwboqLZfeu9mLRpLPw7vrlC7Q9Rq3lDhtOH4ZAVqY/decyjwl3msrcvztDL\nm5HzROSaCORfn/XUtE6JsccFGrAPGKjIv54L7obfCdfSJkpAFHGlzwPqsvmQbfOc\n13ew+cPKA+tQ4sGAm4KR9toyDYgkqOJfMKR6knVEt1UCAwEAAaNWMFQwEgYDVR0T\nAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUofQIVsT5NCA25NuK00VnKVGAZokwHwYD\nVR0jBBgwFoAUofQIVsT5NCA25NuK00VnKVGAZokwDQYJKoZIhvcNAQELBQADggIB\nAGEMHw1SdG+TP2toQHy5RC1nDDrj8NXs0zuIvSHXTGfYjQrNm8KZznlqamWYn7ji\n8lWAT5hfklG3vC9tGu/czEXhOZxxE1Nv5xiOj9PFjLXMHivIOCiVdgNEiI1+XcQE\nCgicw1Y9Z+FkrwxZwCM0/dDt/KSSwj755/7FF3rTA0/ANEeEXuG6Bj61h2XJKvkE\nHPx/df43ugaSt4/5bpRGUjT+U372tBFNnpG7vs9DhroHpA0tRyc0whUGginiu7uP\nB3XY4XrUVnn3v16H6RKlsM99aID/XKeor4mBCXGN80NUHmVIAvKQsMVPAIUejn4t\nYYH8/hPd9ie2fh41F0lGaNp8Yxh3WAbH6GwG1bFrBFX8C4O/2rfdULRPsBJi4v0v\nCaYcrLBlOCknBEvWly962KIF5rKpT9wAhJKM2VxqlSQ9JEWT+ZDYW8RHxP4FEHEq\nywF6oooKGcKFVpBjqZ8RIgvfoVaXGTzTxM2L0jFKQcH8kalYRdm75REMiDFZVbDR\n/oXK1lQhb8a0c/vcDMMpxus+gantX8/KRdn3EMNuNie02SejdIAUpvrb0lvL1aLx\nwnWyZR2Fs5Rn7TyYQoBXOYkAthchz1tkDvmjrRloBk5gqvAjl7uAzA5FjzNHdtfj\njUY457rj9NkjQ2IKxtNlwJDuCbpMzY10nevT6xy1J/NC\n-----END CERTIFICATE-----\n',''),rs=c(10407,1699173505,233453646,1102646391,323487308,525002461,-1013901318))\""
```

The return value may be deployed manually on a remote machine by
unescaping the double quotes around the call to `"mirai::daemon()"`, or
directly via SSH or a resource manager by additionally specifying
‘command’ and ‘args’ to `launch_remote()`.

#### CA Signed Certificates

As an alternative to the zero-configuration option, a certificate may
also be generated in the traditional manner via a Certificate Signing
Request (CSR) to a Certificate Authority (CA), which may be a public CA
or a CA internal to your organisation.

1.  Generate a private key and CSR. The following resources describe how
    to do so:

- using Mbed TLS:
  <https://mbed-tls.readthedocs.io/en/latest/kb/how-to/generate-a-certificate-request-csr/>
- using OpenSSL:
  <https://www.feistyduck.com/library/openssl-cookbook/online/> (Chapter
  1.2 Key and Certificate Management)

2.  Send or provide the generated CSR to the CA for it to sign a new TLS
    certificate.

- The received certificate should comprise a block of cipher text
  between the markers `-----BEGIN CERTIFICATE-----` and
  `-----END CERTIFICATE-----`. Make sure to request the certificate in
  the PEM format. If only available in other formats, your TLS library
  should usually provide conversion utilities.
- Check also that your private key is a block of cipher text between the
  markers `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.

3.  When setting daemons, the TLS certificate and private key should be
    provided to the ‘tls’ argument of `daemons()`.

- If the certificate and private key have been imported as character
  strings `cert` and `key` respectively, then the ‘tls’ argument may be
  specified as the character vector `c(cert, key)`.
- Alternatively, the certificate may be copied to a new text file, with
  the private key appended, in which case the path/filename of this new
  file may be provided to the ‘tls’ argument.

4.  When launching daemons, the certificate chain to the CA should be
    supplied to the ‘tls’ argument of `daemon()` or `launch_remote()`.

- The certificate chain should comprise multiple certificates, each
  between `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`
  markers. The first one should be the newly-generated TLS certificate,
  the same supplied to `daemons()`, and the final one should be a CA
  root certificate.
- These are the only certificates required if your certificate was
  signed directly by a CA. If not, then the intermediate certificates
  should be included in a certificate chain that starts with your TLS
  certificate and ends with the certificate of the CA.
- If these are concatenated together as a single character string
  `certchain` (and assuming no certificate revocation list), then the
  character vector `c(certchain, "")` may be supplied to the relevant
  ‘tls’ argument.
- Alternatively, if these are written to a file (and the file replicated
  on the remote machines), then the ‘tls’ argument may also be specified
  as a path/filename (assuming these are the same on each machine).

[« Back to ToC](#table-of-contents)

### Compute Profiles

The `daemons()` interface also allows the specification of compute
profiles for managing tasks with heterogeneous compute requirements:

- send tasks to different daemons or clusters of daemons with the
  appropriate specifications (in terms of CPUs / memory / GPU /
  accelerators etc.)
- split tasks between local and remote computation

Simply specify the argument `.compute` when calling `daemons()` with a
profile name (which is ‘default’ for the default profile). The daemons
settings are saved under the named profile.

To create a ‘mirai’ task using a specific compute profile, specify the
‘.compute’ argument to `mirai()`, which defaults to the ‘default’
compute profile.

Similarly, functions such as `status()`, `launch_local()` or
`launch_remote()` should be specified with the desired ‘.compute’
argument.

[« Back to ToC](#table-of-contents)

### Errors, Interrupts and Timeouts

If execution in a mirai fails, the error message is returned as a
character string of class ‘miraiError’ and ‘errorValue’ to facilitate
debugging. `is_mirai_error()` may be used to test for mirai execution
errors.

``` r
m1 <- mirai(stop("occurred with a custom message", call. = FALSE))
call_mirai(m1)$data
#> 'miraiError' chr Error: occurred with a custom message

m2 <- mirai(mirai::mirai())
call_mirai(m2)$data
#> 'miraiError' chr Error in mirai::mirai(): missing expression, perhaps wrap in {}?

is_mirai_error(m2$data)
#> [1] TRUE
is_error_value(m2$data)
#> [1] TRUE
```

If a daemon instance is sent a user interrupt, the mirai will resolve to
an empty character string of class ‘miraiInterrupt’ and ‘errorValue’.
`is_mirai_interrupt()` may be used to test for such interrupts.

``` r
is_mirai_interrupt(m2$data)
#> [1] FALSE
```

If execution of a mirai surpasses the timeout set via the ‘.timeout’
argument, the mirai will resolve to an ‘errorValue’. This can, amongst
other things, guard against mirai processes that have the potential to
hang and never return.

``` r
m3 <- mirai(nanonext::msleep(1000), .timeout = 500)
call_mirai(m3)$data
#> 'errorValue' int 5 | Timed out

is_mirai_error(m3$data)
#> [1] FALSE
is_mirai_interrupt(m3$data)
#> [1] FALSE
is_error_value(m3$data)
#> [1] TRUE
```

`is_error_value()` tests for all mirai execution errors, user interrupts
and timeouts.

[« Back to ToC](#table-of-contents)

### Deferred Evaluation Pipe

`mirai` implements a deferred evaluation pipe `%>>%` for working with
potentially unresolved values.

Pipe a ‘mirai’ or mirai `$data` value forward into a function or series
of functions and initially an ‘unresolvedExpr’ will be returned.

The result may be queried at `$data`, which will return another
‘unresolvedExpr’ whilst unresolved. However when the original value
resolves, the ‘unresolvedExpr’ will simultaneously resolve into a
‘resolvedExpr’, for which the evaluated result will then be available at
`$data`.

A piped expression should be wrapped in `.()` to ensure that the return
value is always an ‘unresolvedExpr’ or ‘resolvedExpr’ as the case may
be.

It is possible to use `unresolved()` around an expression, or its
`$data` element, to test for resolution, as in the example below.

The pipe operator semantics are similar to R’s base pipe `|>`:

`x %>>% f` is equivalent to `f(x)` <br /> `x %>>% f()` is equivalent to
`f(x)` <br /> `x %>>% f(y)` is equivalent to `f(x, y)`

``` r
m <- mirai({nanonext::msleep(500); 1})
b <- .(m %>>% c(2, 3) %>>% as.character)

unresolved(b)
#> [1] TRUE
b
#> < unresolvedExpr >
#>  - $data to query resolution
b$data
#> < unresolvedExpr >
#>  - $data to query resolution

nanonext::msleep(1000)
unresolved(b)
#> [1] FALSE
b
#> < resolvedExpr: $data >
b$data
#> [1] "1" "2" "3"
```

[« Back to ToC](#table-of-contents)

### Integrations with Crew, Targets, Shiny

The [`crew`](https://wlandau.github.io/crew/) package is a distributed
worker-launcher that provides an R6-based interface extending `mirai` to
different distributed computing platforms, from traditional clusters to
cloud services. The
[`crew.cluster`](https://wlandau.github.io/crew.cluster/) package is a
plug-in that enables mirai-based workflows on traditional
high-performance computing clusters using LFS, PBS/TORQUE, SGE and
SLURM.

[`targets`](https://docs.ropensci.org/targets/), a Make-like pipeline
tool for statistics and data science, has integrated and adopted
[`crew`](https://wlandau.github.io/crew/) as its predominant
high-performance computing backend.

`mirai` can also serve as the backend for enterprise asynchronous
[`shiny`](https://cran.r-project.org/package=shiny) applications in one
of two ways:

1.  [`mirai.promises`](https://shikokuchuo.net/mirai.promises/), which
    enables a ‘mirai’ to be used interchangeably with a ‘promise’ in
    [`shiny`](https://cran.r-project.org/package=shiny) or
    [`plumber`](https://cran.r-project.org/package=plumber) pipelines;
    or

2.  [`crew`](https://wlandau.github.io/crew/) provides an interface that
    makes it easy to deploy `mirai` for
    [`shiny`](https://cran.r-project.org/package=shiny). The package
    provides a [Shiny
    vignette](https://wlandau.github.io/crew/articles/shiny.html) with
    tutorial and sample code for this purpose.

[« Back to ToC](#table-of-contents)

### Thanks

We would like to thank in particular:

[William Landau](https://github.com/wlandau/), for being instrumental in
shaping development of the package, from initiating the original request
for persistent daemons, through to orchestrating robustness testing for
the high performance computing requirements of
[`crew`](https://wlandau.github.io/crew/) and
[`targets`](https://docs.ropensci.org/targets/).

[Henrik Bengtsson](https://github.com/HenrikBengtsson/), for valuable
and incisive insights leading to the interface accepting broader usage
patterns.

[Luke Tierney](https://github.com/ltierney/), R Core, for pointing out
the implementation of L’Ecuyer-CMRG streams in R, for ensuring
statistical independence in parallel processing.

[« Back to ToC](#table-of-contents)

### Links

mirai website: <https://shikokuchuo.net/mirai/><br /> mirai on CRAN:
<https://cran.r-project.org/package=mirai>

Listed in CRAN Task View: <br /> - High Performance Computing:
<https://cran.r-project.org/view=HighPerformanceComputing>

nanonext website: <https://shikokuchuo.net/nanonext/><br /> nanonext on
CRAN: <https://cran.r-project.org/package=nanonext>

NNG website: <https://nng.nanomsg.org/><br />

[« Back to ToC](#table-of-contents)

–

Please note that this project is released with a [Contributor Code of
Conduct](https://shikokuchuo.net/mirai/CODE_OF_CONDUCT.html). By
participating in this project you agree to abide by its terms.
