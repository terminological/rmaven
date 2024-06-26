% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zz-cran-interface.R
\name{package_jars}
\alias{package_jars}
\title{Find location of some or all of the jars in a particular package.}
\usage{
package_jars(
  package_name,
  types = c("all", "thin-jar", "fat-jar", "shaded", "src")
)
}
\arguments{
\item{package_name}{the R package name}

\item{types}{the jar types to look for in the package: one of
\code{all},\code{thin-jar},\code{fat-jar},\code{shaded},\code{src}}
}
\value{
a vector of paths to jar files in the package
}
\description{
Find location of some or all of the jars in a particular package.
}
\examples{
package_jars("rmaven")
package_jars("rmaven","thin-jar")
}
