## Java Virtal Machine functions ----

#' Start an `rJava` `JVM` with or without debugging options
#'
#' This does not do anything if the `JVM` has already been started. Otherwise starts the JVM via `rJava` with a set of options
#' Additional JVM options (beyond debugging) can be set with the `options("java.parameters"=c("-Xprof","-Xrunhprof"))`
#'
#' @param debug turn on debugging
#' @param quiet don't report messages (defaults to `getOption("rmaven.quiet")` or TRUE)
#' @param max_heap optional. if a string like `"2048m"` the `-Xmx` option value to start the `JVM` - if a string like `"75%"` the `-XX:MaxRAMPercentage`, if a numeric - number of megabytes.
#' @param thread_stack optional. sensible values range from '1m' to '128m' (max is '1g'). Can be important with deeply nested structures.
#' @param ... any other named parameters are passes as `-name` or `-name=value` if value is a character
#'
#' @return nothing - called for side effects
#' @export
#'
#' @examples
#' start_jvm()
#' \dontrun{
#' # this may try to rebind debugging port
#' start_jvm(debug = TRUE)
#' }
start_jvm = .start_jvm
## File functions ----

#' Find location of all the jars in a particular package.
#'
#' @param package_name the R package name
#' @param types the jar types to look for in the package: one of `all`,`thin-jar`,`fat-jar`,`src`
#'
#' @return a vector of paths to jar files in the package
#' @export
#'
#' @examples
#' package_jars("rmaven")
#' package_jars("rmaven","thin-jar")
package_jars = .package_jars


#' Prints a coordinates object
#'
#' @param x a maven coordinates object
#' @param ... ignored
#'
#' @return nothing. for side effects.
#' @export
#'
#' @examples
#' print(as.coordinates("org.junit.jupiter","junit-jupiter-api","4.13.2"))
print.coordinates = .print.coordinates

#' Maven coordinates
#'
#' @param groupId the maven `groupId`
#' @param artifactId the maven `artifactId`
#' @param version the maven version
#' @param ... other parameters ignored apart from `packaging` (one of `jar`,`war`,`pom` or `ejb`) and `classifier` (one of `tests`, `client`, `sources`, `javadoc`, `jar-with-dependencies`, `src`)
#'
#' @return a coordinates object containing the Maven artifact coordinates
#' @export
#'
#' @examples
#' as.coordinates("org.junit.jupiter","junit-jupiter-api","4.13.2")
as.coordinates = .as.coordinates

#' Sets the local maven repository location
#'
#' This writes a maven repository location to a temporary `settings.xml` file which persists only for the R session.
#' The location of the maven repository is either specified here, or can be defined by the `options("rmaven.m2.repository"=...)` option.
#' If neither of these is provided, the location will revert to a default location within the `rmaven` cache. (Approved by CRAN for a local cache location)
#' e.g. on 'Linux' this will default to `~/.cache/rmaven/.m2/repository/`
#'
#' @param repository_location a file path (which will be expanded to a full path) where the repository should be based, e.g. `~/.m2/repository/`. Defaults to a sub-directory of the `rmaven` cache.
#' @param settings_path the file path of the settings.xml to update (generally the supplied default is what you want to use)
#'
#' @return the new repository location (expanded)
#' @export
#'
#' @examples
#' # Setting the repository to be a temp dir as an example:
#' set_repository_location(paste0(tempdir(), "/.m2/repository"))
#' # you would never want to do this in real life as then the maven repository would be rebuilt on every new R session.
#'
#' # set the repository location to the usual location for Java development
#' # set_repository_location("~/.m2/repository")
#' # We can't run this above example as it creates an empty directory in the user space and doing so in an example violates CRAN principles.
#'
#' # set the repository location back to the CRAN approved default location
#' set_repository_location()
set_repository_location = .set_repository_location

#' Get the location of the Maven repository
#'
#' In general this function is mainly for internal use but maybe handy for debugging.
#' The maven repository location can be defined by `set_repository_location(...)` or through the option
#' `options("rmaven.m2.repository"=...)` option but defaults to a `.m2/repository` directory in the `rmaven` cache directory.
#' This is not the default location for Maven when used from Java writing to the default Maven directory in user space is
#' forbidden by CRAN policies. The result of this is that `rmaven` will have to unnecessarily download additional copies of java
#' libraries, onto the users computer and cannot re-use already cached copies. This is more of an issue for developers rather
#' than users.
#'
#' @param settings_path the file path of the `settings.xml` to update (generally the supplied default is what you want to use)
#' @export
#'
#' @examples
#' # the default location:
#' get_repository_location()
#' # change the location to the Java default. This change will not persist between sessions.
#' opt = options("rmaven.m2.repository"="~/.m2/repository/")
#' set_repository_location()
#' get_repository_location()
#' # revert to rmaven defaults
#' options(opt)
#' set_repository_location()
get_repository_location = .get_repository_location

#' Clear out the `rmaven` cache
#'
#' Deletes all content in the `rmaven` cache. This should not be necessary, but never
#' say never, and if there is really a problem with the cache, then deleting it may be the
#' best thing. This will wait for confirmation from the user. If running unattended the
#' `options("rmaven.allow.cache.delete"=TRUE)` must be set for the action to occur, otherwise
#' it will generate a warning and do nothing.
#'
#' @return nothing, called for side effects
#' @export
#'
#' @examples
#' \donttest{
#' # need to set the following option to allow cache to be deleted in non interactive session
#' opts = options("rmaven.allow.cache.delete"=TRUE)
#' clear_rmaven_cache()
#' options(opts)
#' }
clear_rmaven_cache = .clear_rmaven_cache

#' Executes a maven goal
#'
#' Maven goals are defined either as life-cycle goals (e.g. "clean", "compile") or as plugin goals (e.g. "help:system"). Some Maven goals may be executed without a `pom.xml` file, others require one.
#' Some maven goals (e.g. compilation) require the use of a `JDK`.
#'
#' @param goal the goal of the `mvn` command ( can be multiple ) e.g. `c("clean","compile")`
#' @param opts provided options in the form `c("-Doption1=value2","-Doption2=value2")`
#' @param pom_path optional. the path to a `pom.xml` file for goals that need one.
#' @param quiet should output from maven be suppressed? (`-q` flag)
#' @param debug should output from maven be verbose? (`-X` flag)
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#' @param require_jdk does the goal you are executing require a `JDK` (e.g. compilation does, fetching artifacts and calculating class path does not)
#' @param settings the path to a `settings.xml` file controlling Maven. The default is a configuration with a local repository in the `rmaven` cache directory (and not the Java maven repository).
#' @param ... non-empty named parameters are passed to maven as options in the form `-Dname=value`
#'
#' @return nothing, invisibly
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run on a clean system
#' execute_maven("help:system")
#' }
execute_maven = .execute_maven

#' Fetch an artifact from a remote repository into the local .m2 cache
#'
#' @param groupId optional, the maven `groupId`,
#' @param artifactId optional, the maven `artifactId`,
#' @param version optional, the maven version,
#' @param ... other maven coordinates such as classifier or packaging
#' @param coordinates optional, coordinates as a coordinates object,
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param repoUrl the URLs of the repositories to check (defaults to Maven central, 'Sonatype' snapshots and 'jitpack', defined in `options("rmaven.default_repos"))`
#' @param coordinates optional, but if not supplied `groupId` and `artifactId` must be, coordinates as a coordinates object (see `as.coordinates()`)
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param nocache normally artifacts are only fetched if required, `nocache` forces fetching
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return the path of the artifact within the local maven cache
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run
#' fetch_artifact(artifact="com.google.guava:guava:31.1-jre")
#' fetch_artifact(coordinates = as.coordinates("org.junit.jupiter","junit-jupiter-api","5.9.0"))
#' }
fetch_artifact = .fetch_artifact

#' Copy an artifact from a repository to a local directory
#'
#' This essentially runs a `maven-dependency-plugin:copy` goal to copy a JAR file from a remote repository to a local directory.
#'
#' @param groupId optional, the maven `groupId`,
#' @param artifactId optional, the maven `artifactId`,
#' @param version optional, the maven version,
#' @param ... other maven coordinates such as classifier or packaging
#' @param coordinates optional, coordinates as a coordinates object,
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param repoUrl the URLs of the repositories to check (defaults to maven central, `Sonatype snaphots` and `jitpack`)
#' @param outputDirectory optional path, defaults to the `rmaven` cache directory
#' @param nocache normally artifacts are only fetched if required, `nocache` forces fetching
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return the output of the system2 call. 0 on success.
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run
#' tmp = copy_artifact("org.junit.jupiter","junit-jupiter-api","5.9.0")
#' print(tmp)
#' }
copy_artifact = .copy_artifact

#' Resolve the `classpath` for an artifact
#'
#' This calculates the dependencies for an artifact which may be specified either as a set of maven coordinates (in which case the
#' artifact is downloaded, and included in the `classpath`) or as a path to a jar file containing a pom.xml (e.g. a compiled jar file,
#' a compiled jar-with-dependencies, or a assembled `...-src.jar`)
#' The resulting file paths which will be in the maven local cache are checked on the file system.
#'
#' @param groupId the maven `groupId`, optional
#' @param artifactId the maven `artifactId`, optional
#' @param version the maven version, optional
#' @param ... passed on to as.coordinates()
#' @param coordinates the maven coordinates, optional (either `groupId`,`artifactId` and 'version' must be specified, or 'coordinates', or 'artifact')
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param path the path to the source directory, pom file or jar file. if not given `rmaven` will get the artifact from the maven central repositories
#' @param include_self do you want include this path in the `classpath`. optional, if missing the path will be included if it is a regular jar, or a fat jar, otherwise not.
#' @param nocache do not used cached version, by default we use a cached version of the `classpath` unless the `pom.xml` is newer that the cached `classpath`.
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return a character vector of the `classpath` jar files (including the current one if appropriate)
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has
#' # to download a lot of plugins, especially on first run
#'
#' # classpath would be cached if possible
#' resolve_dependencies(groupId = "commons-io", artifactId = "commons-io", version="2.11.0")
#'
#' # forcing download and classpath calculation of an artifact
#' resolve_dependencies(artifact = "org.junit.jupiter:junit-jupiter-api:5.9.0", nocache=TRUE)
#'
#' # find the test jar in this package and calculate its stated dependencies
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT.jar",package="rmaven"))
#'
#' # find the test source code jar in this package and calculate its stated dependencies
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT-src.jar",package="rmaven"))
#' }
resolve_dependencies = .resolve_dependencies

#' Compile and package Java code
#'
#' Compilation will package the Java source code in to a Jar file for further use. It will resolve dependencies and
#' optionally package them into a single `uber jar` (using maven assembly).
#'
#' @param path the path to - either a java source code directory containing a `pom.xml` file, the `pom.xml` file itself, or a `...-src.jar` assembled by the maven assembly plugin,
#' @param nocache normally compilation is only performed if the input has changed. `nocache` forces recompilation
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#' @param with_dependencies compile the Java code to a '...-jar-with-dependencies.jar' including transitive dependencies which may be easier to embed into R code
#' as does not need a class path (however may be large if there are a lot of dependencies)
#' @param ... passed to `execute_maven(...)`, e.g. could include `settings` parameter
#'
#' @return the path to the compiled 'jar' file. If this is a fat jar this can be passed straight to `rJava`, otherwise an additional `resolve_dependencies(...)` call is required
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run
#' path = package_jars("rmaven","src")
#' compile_jar(path,nocache=TRUE)
#' path2 = system.file("testdata/test-project",package = "rmaven")
#' compile_jar(path2,nocache=TRUE,with_dependencies=TRUE)
#' }
compile_jar = .compile_jar
