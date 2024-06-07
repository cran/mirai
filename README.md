
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai?color=171d41)](https://CRAN.R-project.org/package=mirai)
[![R-universe
status](https://shikokuchuo.r-universe.dev/badges/mirai?color=2dab18)](https://shikokuchuo.r-universe.dev/mirai)
[![R-CMD-check](https://github.com/shikokuchuo/mirai/workflows/R-CMD-check/badge.svg)](https://github.com/shikokuchuo/mirai/actions)
[![codecov](https://codecov.io/gh/shikokuchuo/mirai/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/mirai)
[![DOI](https://zenodo.org/badge/459341940.svg)](https://zenodo.org/badge/latestdoi/459341940)
<!-- badges: end -->

### ミライ

<br /> ( 未来 ) <br /><br /> Minimalist Async Evaluation Framework for R
<br /><br /> High performance parallel code execution and distributed
computing. <br /><br /> Designed for simplicity, a ‘mirai’ evaluates an
R expression asynchronously, on local or network resources, resolving
automatically upon completion. <br /><br /> Modern networking and
concurrency built on [nanonext](https://doi.org/10.5281/zenodo.7903429)
and [NNG (Nanomsg Next Gen)](https://nng.nanomsg.org/) ensures reliable
and efficient scheduling, over fast inter-process communications or
TCP/IP secured by TLS. <br /><br />

> *mirai パッケージを試してみたところ、かなり速くて驚きました*

### Production-Grade Compute

[<img alt="Joe Cheng on mirai with Shiny" src="https://img.youtube.com/vi/GhX0PcEm3CY/hqdefault.jpg" width = "300" height="225" />](https://youtu.be/GhX0PcEm3CY?t=1740)
 
[<img alt="Will Landau on mirai in clinical trials" src="https://img.youtube.com/vi/cyF2dzloVLo/hqdefault.jpg" width = "300" height="225" />](https://youtu.be/cyF2dzloVLo?t=5127)

### Quick Start

Use `mirai()` to evaluate an expression asynchronously in a separate,
clean R process.

A ‘mirai’ object is returned immediately.

``` r
library(mirai)

input <- list(x = 2, y = 5, z = double(1e8))

m <- mirai(
  {
    res <- rnorm(1e6, mean = mean, sd = sd)
    max(res) - min(res)
  },
  mean = input$x,
  sd = input$y
)
```

Above, all `name = value` pairs are passed through to the mirai via the
`...` argument.

Whilst the async operation is ongoing, attempting to access the data
yields an ‘unresolved’ logical NA.

``` r
m
#> < mirai [] >
```

``` r
m$data
#> 'unresolved' logi NA
```

To check whether a mirai has resolved:

``` r
unresolved(m)
#> [1] TRUE
```

To wait for and collect the evaluated result, use the mirai’s `[]`
method:

``` r
m[]
#> [1] 47.60447
```

It is not necessary to wait, as the mirai resolves automatically
whenever the async operation completes, the evaluated result then
available at `$data`.

``` r
m
#> < mirai [$data] >
```

``` r
m$data
#> [1] 47.60447
```

### Daemons

Daemons are persistent background processes created to receive ‘mirai’
requests.

They may be deployed for:

[Local](https://shikokuchuo.net/mirai/articles/mirai.html#daemons-local-persistent-processes)
parallel processing; or

[Remote](https://shikokuchuo.net/mirai/articles/mirai.html#distributed-computing-remote-daemons)
network distributed computing.

[Launchers](https://shikokuchuo.net/mirai/articles/mirai.html#distributed-computing-launching-daemons)
allow daemons to be started both on the local machine and across the
network via SSH etc.

[Secure TLS
connections](https://shikokuchuo.net/mirai/articles/mirai.html#distributed-computing-tls-secure-connections)
can be automatically-configured on-the-fly for remote daemon
connections.

The mirai vignette may be accessed within R by:

``` r
vignette("mirai", package = "mirai")
```

### Integrations

The following core integrations are documented, with usage examples in
the linked vignettes:

[<img alt="R parallel" src="https://www.r-project.org/logo/Rlogo.png" width="40" height="31" />](https://shikokuchuo.net/mirai/articles/parallel.html)
  Provides an alternative communications backend for R, implementing a
low-level feature request by R-Core at R Project Sprint 2023.
‘miraiCluster’ may also be used with `foreach`, which is supported via
`doParallel`.

[<img alt="promises" src="https://docs.posit.co/images/posit-ball.png" width="40" height="36" />](https://shikokuchuo.net/mirai/articles/promises.html)
  Implements the next generation of completely event-driven, non-polling
promises. ‘mirai’ may be used interchageably with ‘promises’, including
with the promise pipe `%...>%`.

[<img alt="Shiny" src="https://github.com/rstudio/shiny/raw/main/man/figures/logo.png" width="40" height="46" />](https://shikokuchuo.net/mirai/articles/shiny.html)
  Asynchronous parallel / distributed backend, supporting the next level
of responsiveness and scalability for Shiny. Launches ExtendedTasks, or
plugs directly into the reactive framework for advanced uses.

[<img alt="Plumber" src="https://rstudio.github.io/cheatsheets/html/images/logo-plumber.png" width="40" height="46" />](https://shikokuchuo.net/mirai/articles/plumber.html)
  Asynchronous parallel / distributed backend, capable of scaling
Plumber applications in production usage.

[<img alt="Arrow" src="https://arrow.apache.org/img/arrow-logo_hex_black-txt_white-bg.png" width="40" height="46" />](https://shikokuchuo.net/mirai/articles/databases.html)
  Allows queries using the Apache Arrow format to be handled seamlessly
over ADBC database connections hosted in daemon processes.

[<img alt="torch" src="https://torch.mlverse.org/css/images/hex/torch.png" width="40" height="46" />](https://shikokuchuo.net/mirai/articles/torch.html)
  Allows Torch tensors and complex objects such as models and optimizers
to be used seamlessly across parallel processes.

### Powering Crew and Targets High Performance Computing

[<img alt="targets" src="https://github.com/ropensci/targets/raw/main/man/figures/logo.png" width="40" height="46" />](https://docs.ropensci.org/targets/)
  Targets, a Make-like pipeline tool for statistics and data science,
has integrated and adopted `crew` as its default high-performance
computing backend.

[<img alt="crew" src="https://github.com/wlandau/crew/raw/main/man/figures/logo.png" width="40" height="46" />](https://wlandau.github.io/crew/)
  Crew is a distributed worker-launcher extending `mirai` to different
distributed computing platforms, from traditional clusters to cloud
services.

[<img alt="crew.cluster" src="https://github.com/wlandau/crew.cluster/raw/main/man/figures/logo.png" width="40" height="46" />](https://wlandau.github.io/crew.cluster/)
  `crew.cluster` enables mirai-based workflows on traditional
high-performance computing clusters using LFS, PBS/TORQUE, SGE and
SLURM.

[<img alt="crew.aws.batch" src="https://github.com/wlandau/crew.aws.batch/raw/main/man/figures/logo.png" width="40" height="46" />](https://wlandau.github.io/crew.aws.batch/)
  `crew.aws.batch` extends `mirai` to cloud computing using AWS Batch.

### Thanks

We would like to thank in particular:

[Will Landau](https://github.com/wlandau/) for being instrumental in
shaping development of the package, from initiating the original request
for persistent daemons, through to orchestrating robustness testing for
the high performance computing requirements of `crew` and `targets`.

[Joe Cheng](https://github.com/jcheng5/) for optimising the `promises`
method to make `mirai` work seamlessly within Shiny, and prototyping
non-polling promises, which is implemented across `nanonext` and
`mirai`.

[Luke Tierney](https://github.com/ltierney/) of R Core, for discussion
on L’Ecuyer-CMRG streams to ensure statistical independence in parallel
processing, and making it possible for `mirai` to be the first
‘alternative communications backend for R’.

[Henrik Bengtsson](https://github.com/HenrikBengtsson/) for valuable
insights leading to the interface accepting broader usage patterns.

[Daniel Falbel](https://github.com/dfalbel/) for discussion around an
efficient solution to serialization and transmission of `torch` tensors.

[Kirill Müller](https://github.com/krlmlr/) for discussion on using
‘daemons’ to host Arrow database connections.

[<img alt="R Consortium" src="https://www.r-consortium.org/wp-content/uploads/sites/13/2016/09/RConsortium_Horizontal_Pantone.png" width="100" height="22" />](https://www.r-consortium.org/) 
for funding work on the TLS implementation in `nanonext`, used to
provide secure connections in `mirai`.

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

Or the development version from R-universe:

``` r
install.packages("mirai", repos = "https://shikokuchuo.r-universe.dev")
```

### Links

◈ mirai R package: <https://shikokuchuo.net/mirai/> <br /> ◈ nanonext R
package: <https://shikokuchuo.net/nanonext/>

mirai is listed in CRAN High Performance Computing Task View: <br />
<https://cran.r-project.org/view=HighPerformanceComputing>

–

Please note that this project is released with a [Contributor Code of
Conduct](https://shikokuchuo.net/mirai/CODE_OF_CONDUCT.html). By
participating in this project you agree to abide by its terms.
