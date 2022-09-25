# rmaven 0.1.0

* Added a `NEWS.md` file to track changes to the package.
* feature complete first version of `rmaven`
* check dependencies of a java library
* fetch jars from maven central
* compile jars from source

# rmaven 0.1.1

* moved default repository location from '~/.m2/repository', which is Java's default location to a CRAN approved location 
( a sub-directory of the 'rmaven' cache - e.g. on 'Linux' this would be '~/.cache/rmaven/.m2/repository')
* rudimentary support for configuration using generated and provided settings.xml file.
* documentation fixes.
* options documentation.
* rmaven cache clear in getting stared vignette. 
* default verbosity level reduced to "quiet" as potential to be used as an end user tool than a developer tool.

# rmaven 0.1.2

* Addressed CRAN regression 
* Improved documentation
* Changed defaults around verbose output plus removed downloading messages
by default
* Re-organised to allow backend to be embedded without relying on CRAN.
* Deployed to 'r-universe'

# rmaven 0.1.2.9000

* Explicit documentation for embedding.
* Fixes for empty or non functional JAVA_HOME specification as ween on windows
hosts with multiarch setup.
* TODO: identify JAVA_HOME in mulitarch systems
* TODO: search for artifact pom in multiple jars

