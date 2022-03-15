
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai?color=112d4e)](https://CRAN.R-project.org/package=mirai)
[![mirai status
badge](https://shikokuchuo.r-universe.dev/badges/mirai?color=ddcacc)](https://shikokuchuo.r-universe.dev)
[![R-CMD-check](https://github.com/shikokuchuo/mirai/workflows/R-CMD-check/badge.svg)](https://github.com/shikokuchuo/mirai/actions)
<!-- badges: end -->

Minimalist async evaluation framework for R.

未来 みらい mirai is Japanese for ‘future’.

Extremely simple and lightweight method for concurrent / parallel code
execution, built on ‘nanonext’ and ‘NNG’ (Nanomsg Next Gen) technology.

\~\~

Whilst frameworks for parallelisation exist for R, {mirai} is designed
for simplicity.

Use:    `mirai()` to return a ‘mirai’ object immediately.

A ‘mirai’ evaluates an arbitrary expression asynchronously, resolving
automatically upon completion.

\~\~

{mirai} has a tiny code base, relying solely on {nanonext}, a
lightweight wrapper for the NNG C library with no package dependencies.

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

or the development version from rOpenSci R-universe:

``` r
install.packages("mirai", repos = "https://shikokuchuo.r-universe.dev")
```

### Demonstration

Use cases:

-   minimise execution times by performing long-running tasks
    concurrently in separate processes
-   ensure execution flow of the main process is not blocked

``` r
library(mirai)
```

#### Example 1: Compute-intensive Operations

Multiple long computes (model fits etc.) would take more time than if
performed concurrently on available computing cores.

Use `mirai()` to evaluate an expression in a separate R process
asynchronously.

-   All named objects are passed through to a clean environment

A ‘mirai’ object is returned immediately.

``` r
m <- mirai({
  res <- rnorm(n) + m
  res / rev(res)
}, n = 1e8, m = runif(1))
m
#> < mirai >
#>  - $value for evaluated result
m$value
#> 'unresolved' logi NA
```

The ‘mirai’ yields an ‘unresolved’ logical NA value whilst the async
operation is still ongoing.

``` r
# continue running code concurrently...
```

Upon completion, the ‘mirai’ automatically resolves to the evaluated
result.

``` r
m$value |> str()
#> num [1:100000000] 2.263 -2.907 0.365 0.522 -0.229 ...
```

Alternatively, explicitly call and wait for the result (blocking) using
`call_mirai()`.

``` r
call_mirai(m)$value |> str()
#> num [1:100000000] 2.263 -2.907 0.365 0.522 -0.229 ...
```

#### Example 2: I/O-bound Operations

Processing high-frequency real-time data, writing results to
file/database can be slow and potentially disrupt the execution flow.

Cache data in memory and use `mirai()` to perform periodic write
operations in a separate process.

A ‘mirai’ object is returned immediately.

``` r
m <- mirai(write.csv(x, file = file), x = rnorm(1e8), file = tempfile())
```

Auxiliary function `unresolved()` may be used in control flow statements
to perform actions which depend on resolution of the ‘mirai’, both
before and after. This means there is no need to actually wait (block)
for a ‘mirai’ to resolve, as the example below demonstrates.

``` r
# unresolved() queries for resolution itself so no need to use it again within the while loop

while (unresolved(m)) {
  # do stuff before checking resolution again
  cat("while unresolved\n")
}
#> while unresolved
#> while unresolved
#> while unresolved

# perform actions which depend on the 'mirai' value outside the while loop
m$value
#> NULL
```

Here the resolved value is `NULL`, the expected return value for
`write.csv()`. Now actions which depend on this confirmation may be
processed, for example the next write.

### Daemons

Daemons or persistent background processes may be set to receive ‘mirai’
requests.

Setting a positive number of daemons provides a potentially more
efficient solution for ‘mirai’ requests as new processes no longer need
to be created on an ad hoc basis.

``` r
# create 8 daemons
daemons(8)
#> [1] 8

# query the number of active daemons
daemons("view")
#> [1] 8
```

The current implementation is low-level and ensures tasks are
evenly-distributed amongst daemons without actively managing a task
queue. This robust and resource-light approach is particularly
well-suited to working with similar-length tasks, or where the number of
concurrent tasks typically does not exceed the number of available
daemons.

Set the number of daemons to zero again to revert to the default
behaviour of creating a new background process for each ‘mirai’ request.

``` r
# reset to zero
daemons(0)
#> [1] -8
```

### Links

{mirai} website: <https://shikokuchuo.net/mirai/><br /> {mirai} on CRAN:
<https://cran.r-project.org/package=mirai>

{nanonext} website: <https://shikokuchuo.net/nanonext/><br /> {nanonext}
on CRAN: <https://cran.r-project.org/package=nanonext>

NNG website: <https://nng.nanomsg.org/><br /> NNG documentation:
<https://nng.nanomsg.org/man/tip/><br />
