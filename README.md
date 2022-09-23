# rmaven

<!-- badges: start -->
[![R-CMD-check](https://github.com/terminological/rmaven/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/terminological/rmaven/actions/workflows/R-CMD-check.yaml)
[![DOI](https://zenodo.org/badge/525325654.svg)](https://zenodo.org/badge/latestdoi/525325654)
[![rmaven status badge](https://terminological.r-universe.dev/badges/rmaven)](https://terminological.r-universe.dev)
<!-- badges: end -->

Execute Java's build tools, Apache Maven, from within R. This enables users to locally install Java libraries and use them from within R, and compile Java code from source, all as part
of R package development.

## Installation

Released versions of `rmaven` are available on r-universe.

```r
# Enable repository from terminological r-universe
options(repos = c(
  terminological = 'https://terminological.r-universe.dev',
  CRAN = 'https://cloud.r-project.org'))
  
install.packages("rmaven")
```

The unstable development version is available from [GitHub](https://github.com/)
with:

``` r
# install.packages("devtools")
devtools::install_github("terminological/rmaven")
```

The package assumes a `Java` installation is present, which is required for
`Maven` to run. The location of the `Java` installation should be detected
automatically, however if not if can be set as an option: e.g.
`options("rmaven.java_home"="/usr/lib/jvm/java-9-oracle")`.

## Example

When using `rmaven` the work-flow involved in using a Java library in R is to
first fetch it from the Maven repositories. The second step is to add jars from
the local Maven repository to the `rJava` class path, and third using `rJava`,
create an R interface to the Java class you want to use (in this case the
`StringUtils` class). Finally you can call the static Java method, using
`rJava`, in this case `StringUtils.rotate(String s, int distance)`.

```R
library(rmaven)
start_jvm()

# step 1
dynamic_classpath = resolve_dependencies(
  groupId = "org.apache.commons", 
  artifactId = "commons-lang3", 
  version="3.12.0"
)

# step 2
rJava::.jaddClassPath(dynamic_classpath)

# step 3
StringUtils = rJava::J("org.apache.commons.lang3.StringUtils")

# step 4devtoo
StringUtils$rotate("ABCDEF",3L)
```

Check [the documentation](https://terminological.github.io/rmaven/) for more
examples.
