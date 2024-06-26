% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/standalone-rmaven.R
\name{.as.coordinates}
\alias{.as.coordinates}
\title{Maven coordinates}
\usage{
.as.coordinates(groupId, artifactId, version, ...)
}
\arguments{
\item{groupId}{the maven \code{groupId}}

\item{artifactId}{the maven \code{artifactId}}

\item{version}{the maven version}

\item{...}{other parameters ignored apart from \code{packaging}
(one of \code{jar},\code{war},\code{pom} or \code{ejb}) and \code{classifier}
(one of \code{tests}, \code{client}, \code{sources}, \code{javadoc}, \code{jar-with-dependencies},
or \code{src})}
}
\value{
a coordinates object containing the Maven artifact coordinates
}
\description{
Maven coordinates
}
\keyword{internal}
