# rmaven

<!-- badges: start -->
[![R-CMD-check](https://github.com/terminological/rmaven/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/terminological/rmaven/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Execute Java's build tools, Apache Maven, from within R. This enables users to locally install Java libraries and use them from within R, and compile Java code from source, all as part
of R package development.

## Installation

`rmaven` is in early development. It is not yet available on CRAN.

The development version is available from [GitHub](https://github.com/)
with:

``` r
# install.packages("devtools")
devtools::install_github("terminological/rmaven")
```

## Example

When using `rmaven` the work-flow involved in using a Java library in R is to first fetch it from the Maven repositories. 
The second step is to add jars from the local `.m2` repository to the `rJava` class path, and 
third using `rJava`, create an R interface to the Java class you want to use (in this case the `StringUtils` class). 
Finally you can call the static Java method, using `rJava`, in this case `StringUtils.rotate(String s, int distance)`.

```R
library(rmaven)
start_jvm()

dynamic_classpath = resolve_dependencies(
  groupId = "org.apache.commons", 
  artifactId = "commons-lang3", 
  version="3.12.0"
)

rJava::.jaddClassPath(dynamic_classpath)
StringUtils = rJava::J("org.apache.commons.lang3.StringUtils")

StringUtils$rotate("ABCDEF",3L)
```

Check [the documentation](https://terminological.github.io/rmaven/) for more examples.
