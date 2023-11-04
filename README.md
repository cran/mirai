
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai?color=112d4e)](https://CRAN.R-project.org/package=mirai)
[![mirai status
badge](https://shikokuchuo.r-universe.dev/badges/mirai?color=24a60e)](https://shikokuchuo.r-universe.dev/mirai)
[![R-CMD-check](https://github.com/shikokuchuo/mirai/workflows/R-CMD-check/badge.svg)](https://github.com/shikokuchuo/mirai/actions)
[![codecov](https://codecov.io/gh/shikokuchuo/mirai/branch/main/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/mirai)
[![DOI](https://zenodo.org/badge/459341940.svg)](https://zenodo.org/badge/latestdoi/459341940)
<!-- badges: end -->

Minimalist async evaluation framework for R. <br /><br /> Lightweight
parallel code execution and distributed computing. <br /><br /> Designed
for simplicity, a ‘mirai’ evaluates an R expression asynchronously, on
local or network resources, resolving automatically upon completion.
<br /><br /> `mirai()` returns a ‘mirai’ object immediately. ‘mirai’
(未来 みらい) is Japanese for ‘future’. <br /><br /> Features efficient
task scheduling, fast inter-process communications, and TLS over TCP/IP
for remote connections. <br /><br /> {mirai} has a tiny pure R code
base, relying solely on
[`nanonext`](https://doi.org/10.5281/zenodo.7903429), a high-performance
binding for the ‘NNG’ (Nanomsg Next Gen) C library with zero package
dependencies. <br /><br />

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

or the development version from rOpenSci R-universe:

``` r
install.packages("mirai", repos = "https://shikokuchuo.r-universe.dev")
```

### Quick Start

Use `mirai()` to evaluate an expression asynchronously in a separate,
clean R process.

A ‘mirai’ object is returned immediately.

``` r
library(mirai)

m <- mirai(
  {
    res <- rnorm(x) + y ^ 2
    res / rev(res)
  },
  x = 11,
  y = runif(1)
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

To check whether a mirai has resolved:

``` r
unresolved(m)
#> [1] FALSE
```

Upon completion, the ‘mirai’ resolves automatically to the evaluated
result.

``` r
m$data
#>  [1] -0.4189294  0.4175360 -7.1428468 -0.3830076  1.6176787  1.0000000
#>  [7]  0.6181697 -2.6109140 -0.1400002  2.3950031 -2.3870373
```

Alternatively, explicitly call and wait for the result using
`call_mirai()`.

``` r
call_mirai(m)$data
#>  [1] -0.4189294  0.4175360 -7.1428468 -0.3830076  1.6176787  1.0000000
#>  [7]  0.6181697 -2.6109140 -0.1400002  2.3950031 -2.3870373
```

### Vignette

See the [mirai
vignette](https://shikokuchuo.net/mirai/articles/mirai.html) for full
package functionality.

Key topics include:

- Example use cases

- Local daemons - persistent background processes

- Distributed computing - remote daemons

- Secure TLS connections

This may be accessed within R by:

``` r
vignette("mirai", package = "mirai")
```

### Use with Parallel and Foreach

{mirai} provides an alternative communications backend for R’s base
‘parallel’ package.

`make_cluster()` creates a ‘miraiCluster’, a cluster fully compatible
with all ‘parallel’ functions such as:

- `parallel::clusterApply()`
- `parallel::parLapply()`
- `parallel::parLapplyLB()`

[`doParallel`](https://cran.r-project.org/package=doParallel) can also
register a ‘miraiCluster’ for use with the
[`foreach`](https://cran.r-project.org/package=foreach) package.

This functionality fulfils a request from R-Core at R Project Sprint
2023.

### Use with Crew and Targets

The [`crew`](https://cran.r-project.org/package=crew) package is a
distributed worker-launcher extending {mirai} to different distributed
computing platforms, from traditional clusters to cloud services.

[`crew.cluster`](https://cran.r-project.org/package=crew.cluster) is a
plug-in that enables mirai-based workflows on traditional
high-performance computing clusters using:

- LFS
- PBS/TORQUE
- SGE
- SLURM

[`targets`](https://cran.r-project.org/package=targets), a Make-like
pipeline tool for statistics and data science, has integrated and
adopted [`crew`](https://cran.r-project.org/package=crew) as its default
recommended high-performance computing backend.

### Use with Shiny and Plumber

{mirai} serves as a backend for enterprise asynchronous
[`shiny`](https://cran.r-project.org/package=shiny) or
[`plumber`](https://cran.r-project.org/package=plumber) applications.

A ‘mirai’ may be used interchangeably with a ‘promise’ by using the the
promise pipe `%...>%`, or explictly by `promises::as.promise()`,
allowing side-effects to be performed upon asynchronous resolution of a
‘mirai’.

Alternatively, [`crew`](https://cran.r-project.org/package=crew) also
provides an interface that facilitates deploying {mirai} for
[`shiny`](https://cran.r-project.org/package=shiny), and provides a
[Shiny vignette](https://wlandau.github.io/crew/articles/shiny.html)
with tutorial and sample code for this purpose.

### Thanks

We would like to thank in particular:

[William Landau](https://github.com/wlandau/), for being instrumental in
shaping development of the package, from initiating the original request
for persistent daemons, through to orchestrating robustness testing for
the high performance computing requirements of
[`crew`](https://cran.r-project.org/package=crew) and
[`targets`](https://cran.r-project.org/package=targets).

[Henrik Bengtsson](https://github.com/HenrikBengtsson/), for valuable
and incisive insights leading to the interface accepting broader usage
patterns.

[Luke Tierney](https://github.com/ltierney/), R Core, for introducing
R’s implementation of L’Ecuyer-CMRG streams, used to ensure statistical
independence in parallel processing.

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
