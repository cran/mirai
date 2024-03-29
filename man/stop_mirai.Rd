% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mirai.R
\name{stop_mirai}
\alias{stop_mirai}
\title{mirai (Stop Evaluation)}
\usage{
stop_mirai(aio)
}
\arguments{
\item{aio}{a 'mirai' object.}
}
\value{
Invisible NULL.
}
\description{
Stop evaluation of a mirai that is in progress.
}
\details{
Stops the asynchronous operation associated with the mirai by
    aborting, and then waits for it to complete or to be completely aborted.
    The mirai is then deallocated and attempting to access the value at
    \code{$data} will result in an error.
}
\examples{
if (interactive()) {
# Only run examples in interactive R sessions

s <- mirai(Sys.sleep(n), n = 5)
stop_mirai(s)

}

}
