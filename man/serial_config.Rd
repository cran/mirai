% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/daemons.R
\name{serial_config}
\alias{serial_config}
\title{Create Serialization Configuration}
\usage{
serial_config(class, sfunc, ufunc, vec = FALSE)
}
\arguments{
\item{class}{character string of the class of object custom serialization
functions are applied to, e.g. 'ArrowTabular' or 'torch_tensor'.}

\item{sfunc}{a function that accepts a reference object inheriting from
\code{class} (or a list of such objects) and returns a raw vector.}

\item{ufunc}{a function that accepts a raw vector and returns a reference
object (or list of such objects).}

\item{vec}{[default FALSE] whether or not the serialization functions are
vectorized. If FALSE, they should accept and return reference objects
individually e.g. \code{arrow::write_to_raw} and \code{arrow::read_ipc_stream}. If
TRUE, they should accept and return a list of reference objects, e.g.
\code{torch::torch_serialize} and \code{torch::torch_load}.}
}
\value{
A list comprising the configuration. This should be passed to the
\code{serial} argument of \code{\link[=daemons]{daemons()}}.
}
\description{
Returns a serialization configuration, which may be set to perform custom
serialization and unserialization of normally non-exportable reference
objects, allowing these to be used seamlessly between different R sessions.
This feature utilises the 'refhook' system of R native serialization. Once
set, the functions apply to all mirai requests for a specific compute
profile.
}
\examples{
cfg <- serial_config("test_cls", function(x) serialize(x, NULL), unserialize)
cfg

}
