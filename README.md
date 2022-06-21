
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

<br /><br /> Whilst frameworks for parallelisation exist for R, {mirai}
is designed for simplicity.

`mirai()` returns a ‘mirai’ object immediately.

A ‘mirai’ evaluates an arbitrary expression asynchronously, resolving
automatically upon completion. <br /><br /><br />

{mirai} has a tiny pure R code base, relying solely on {nanonext}, a
lightweight binding for the NNG C library with no package dependencies.

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

Multiple long computes (model fits etc.) can be performed in parallel on
available computing cores.

Use `mirai()` to evaluate an expression asynchronously in a separate R
process.

-   All named objects are passed through to a clean environment

A ‘mirai’ object is returned immediately.

``` r
m <- mirai({
  res <- rnorm(n) + m
  res / rev(res)
}, n = 1e8, m = runif(1))

m
#> < mirai >
#>  - $data for evaluated result
```

The ‘mirai’ yields an ‘unresolved’ logical NA value whilst the async
operation is ongoing.

``` r
m$data
#> 'unresolved' logi NA
```

Upon completion, the ‘mirai’ resolves automatically to the evaluated
result.

``` r
m$data |> str()
#>  num [1:100000000] 0.401 1.029 3.28 -0.369 -0.171 ...
```

Alternatively, explicitly call and wait for the result using
`call_mirai()`.

``` r
call_mirai(m)$data |> str()
#>  num [1:100000000] 0.401 1.029 3.28 -0.369 -0.171 ...
```

#### Example 2: I/O-bound Operations

High-frequency real-time data cannot be written to file/database
synchronously without disrupting the execution flow.

Cache data in memory and use `mirai()` to perform periodic write
operations concurrently in a separate process.

A ‘mirai’ object is returned immediately.

``` r
m <- mirai(write.csv(x, file = file), x = rnorm(1e6), file = tempfile())
```

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

### Daemons

Daemons or persistent background processes may be set to receive ‘mirai’
requests.

This is potentially more efficient as new processes no longer need to be
created on an ad hoc basis.

``` r
# create 8 daemons
daemons(8)
#> [1] 8

# view the number of active daemons
daemons("view")
#> [1] 8
```

The current implementation is low-level and ensures tasks are
evenly-distributed amongst daemons without actively managing a task
queue.

This robust and resource-light approach is particularly well-suited to
working with similar-length tasks, or where the number of concurrent
tasks typically does not exceed the number of available daemons.

``` r
# reset to zero
daemons(0)
#> [1] -8
```

Set the number of daemons to zero again to revert to the default
behaviour of creating a new background process for each ‘mirai’ request.

### Deferred Evaluation Pipe

{mirai} implements a deferred evaluation pipe `%>>%` for working with
potentially unresolved values.

Pipe a mirai `$data` value forward into a function or series of
functions and it initially returns an ‘unresolvedExpr’.

The result may be queried at `$data`, which will return another
‘unresolvedExpr’ whilst unresolved. However when the original value
resolves, the ‘unresolvedExpr’ will simultaneously resolve into a
‘resolvedExpr’, for which the evaluated result will be available at
`$data`.

It is possible to use `unresolved()` around a ‘unresolvedExpr’ or its
`$data` element to test for resolution, as in the example below.

The pipe operator semantics are similar to R’s base pipe `|>`:

`x %>>% f` is equivalent to `f(x)` <br /> `x %>>% f()` is equivalent to
`f(x)` <br /> `x %>>% f(y)` is equivalent to `f(x, y)`

``` r
m <- mirai({Sys.sleep(0.5); 1})
b <- m$data %>>% c(2, 3) %>>% as.character()
b
#> < unresolvedExpr >
#>  - $data to query resolution
b$data
#> < unresolvedExpr >
#>  - $data to query resolution
Sys.sleep(1)
b$data
#> [1] "1" "2" "3"
b
#> < resolvedExpr: $data >
```

### Links

{mirai} website: <https://shikokuchuo.net/mirai/><br /> {mirai} on CRAN:
<https://cran.r-project.org/package=mirai>

{nanonext} website: <https://shikokuchuo.net/nanonext/><br /> {nanonext}
on CRAN: <https://cran.r-project.org/package=nanonext>

NNG website: <https://nng.nanomsg.org/><br />

–

Please note that this project is released with a [Contributor Code of
Conduct](https://shikokuchuo.net/mirai/CODE_OF_CONDUCT.html). By
participating in this project you agree to abide by its terms.
