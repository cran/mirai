
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->
<!-- badges: end -->

Minimalist async evaluation framework for R.

未来 みらい mirai is the Japanese word for future.

An extremely simple and lightweight method for concurrent / parallel
code execution, built on the nanonext R package and NNG (Nanomsg Next
Gen).

### Design Notes

Whilst frameworks for parallelisation exist for R, {mirai} is designed
for simplicity.

The package provides just 2 functions:

-   `eval_mirai()` to evaluate async

-   `call_mirai()` to call the result

Demonstrates the capability of {nanonext} in providing a lightweight and
robust cross-platform concurrency framework.

{mirai} has a tiny pure R code base, relying on a single package -
{nanonext}.

{nanonext} itself is a lightweight wrapper for the NNG C library with
zero package dependencies.

### Installation

Install the latest development version from Github:

``` r
remotes::install_github("shikokuchuo/mirai")
```

### Use Cases

Minimise execution times by performing long-running tasks concurrently
in separate processes.

Ensure execution flow of the main process is not blocked.

``` r
library(mirai)
```

#### Example 1: Compute-intensive Operations

Multiple long computes (model fits etc.) would take more time than if
performed concurrently on available computing cores.

Use `eval_mirai()` to evaluate an expression in a separate R process
asynchronously.

-   All named objects are passed through to a clean environment

A ‘mirai’ object is returned immediately.

``` r
mirai <- eval_mirai(rnorm(n) + m, n = 1e8, m = runif(1))

mirai
#> < mirai >
#>  ~ use call_mirai() to resolve
```

Continue running code concurrent to the async operation.

``` r
# do more...
```

Use `call_mirai()` to retrieve the evaluated result when required.

``` r
call_mirai(mirai)

mirai
#> < mirai >
#>  - $value for evaluated result

str(mirai$value)
#> num [1:100000000] 1.485 -0.804 0.965 -0.128 -0.555 ...
```

#### Example 2: I/O-bound Operations

Processing high-frequency real-time data, writing results to
file/database can be slow and potentially disrupt the execution flow.

Cache data in memory and use `eval_mirai()` to perform periodic write
operations in a separate process.

A ‘mirai’ object is returned immediately.

``` r
mirai <- eval_mirai(write.csv(x, file = file), x = rnorm(1e8), file = tempfile())
```

Use `call_mirai()` to confirm the operation has completed.

-   This will wait for the operation to complete if it is still ongoing

``` r
call_mirai(mirai)$value
#> NULL
```

Above, the return value is called directly. NULL is the expected return
value for `write.csv()`.

### Links

{mirai} website: <https://shikokuchuo.net/mirai/><br />

{nanonext} website: <https://shikokuchuo.net/nanonext/><br /> {nanonext}
on CRAN: <https://cran.r-project.org/package=nanonext>

NNG website: <https://nng.nanomsg.org/><br /> NNG documentation:
<https://nng.nanomsg.org/man/tip/><br />
