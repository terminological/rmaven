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

# rmaven 0.1.3

* Explicit documentation for embedding.
* Fixes for empty or non functional JAVA_HOME specification as seen on windows
hosts with multiarch setup.
* Fix maven wrapper auto download to `~/.m2` rather than configured cache 
location

# rmaven 0.1.3.9000

* TODO: identify JAVA_HOME in multiarch systems (?utils::readRegistry)
* HKEY_LOCAL_MACHINE\Software\MyApp\ but when running on 64-bit versions of windows, the value is under 
* HKEY_LOCAL_MACHINE\Software\Wow6432Node\MyApp. But my application still looks for a value in 
* HKEY_LOCAL_MACHINE\Software\MyApp\
* TODO: search for artifact pom in multiple jars
* readlink -f /usr/bin/java
