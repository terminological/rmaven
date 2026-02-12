## Java Virtal Machine functions ----

#' @inherit .start_jvm
#' @export
#'
#' @examples
#' start_jvm()
#' \dontrun{
#' # this may try to rebind debugging port
#' start_jvm(debug = TRUE)
#' }
start_jvm = .start_jvm


#' @inherit .package_jars
#' @export
#'
#' @examples
#' package_jars("rmaven")
#' package_jars("rmaven","thin-jar")
package_jars = .package_jars


#' @inherit .print.coordinates
#'
#' @return nothing. for side effects.
#' @export
#'
#' @examples
#' print(as.coordinates("org.junit.jupiter","junit-jupiter-api","4.13.2"))
print.coordinates = .print.coordinates


#' @inherit .as.coordinates
#'
#' @export
#'
#' @examples
#' as.coordinates("org.junit.jupiter","junit-jupiter-api","4.13.2")
as.coordinates = .as.coordinates


#' @inherit .set_repository_location
#' @export
#'
#' @examples
#' # Setting the repository to be a temp dir as an example:
#' set_repository_location(paste0(tempdir(), "/.m2/repository"))
#' # you would never want to do this in real life as then the maven repository
#' # would be rebuilt on every new R session.
#'
#' # set the repository location to the usual location for Java development
#' # set_repository_location("~/.m2/repository")
#' # We don't run this above example as it creates an empty directory in the
#' # userspace and doing so in an example violates CRAN principles.
#'
#' # set the repository location back to the CRAN approved default location
#' set_repository_location()
set_repository_location = .set_repository_location

#' @inherit .developer_mode
#' @export
#'
#' @examples
#' # set the repository location to the usual location for Java development
#' # developer_mode()
#'
#' # We don't run this above example as it creates an empty directory in the
#' # userspace and doing so in an example violates CRAN principles.
developer_mode = .developer_mode


#' @inherit .get_repository_location
#' @export
#' @examples
#' # the default location:
#' get_repository_location()
#' # change the location to the Java default. This change will not persist between sessions.
#' opt = options("rmaven.m2.repository"=paste0(tempdir(),"/.m2/repository/"))
#' set_repository_location()
#' get_repository_location()
#' # revert to rmaven defaults
#' options(opt)
#' set_repository_location()
get_repository_location = .get_repository_location


#' @inherit .clear_rmaven_cache
#' @export
#'
#' @examples
#' \donttest{
#' # need to set the following option to allow cache to be deleted in non
#' # interactive session
#' opts = options("rmaven.allow.cache.delete"=TRUE)
#' clear_rmaven_cache()
#' options(opts)
#' }
clear_rmaven_cache = .clear_rmaven_cache


#' @inherit .execute_maven
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run on a clean system
#' execute_maven("help:help")
#' }
execute_maven = .execute_maven


#' @inherit .fetch_artifact
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has to
#' # download a lot of plugins, especially on first run
#' fetch_artifact(artifact="com.google.guava:guava:31.1-jre")
#' fetch_artifact(coordinates = as.coordinates("org.junit.jupiter",
#'   "junit-jupiter-api","5.9.0"))
#' }
fetch_artifact = .fetch_artifact


#' @inherit .copy_artifact
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


#' @inherit .resolve_dependencies
#' @export
#'
#' @examples
#' \donttest{
#' # This code can take quite a while to run as has
#' # to download a lot of plugins, especially on first run
#'
#' # classpath would be cached if possible
#' resolve_dependencies(groupId = "commons-io", artifactId = "commons-io",
#'   version="2.11.0")
#'
#' # forcing download and classpath calculation of an artifact
#' resolve_dependencies(artifact = "org.junit.jupiter:junit-jupiter-api:5.9.0",
#'   nocache=TRUE)
#'
#' # find the test jar in this package and calculate its stated dependencies
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT.jar",package="rmaven"))
#'
#' # find the test source code jar in this package and calculate its stated
#' # dependencies
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT-src.jar",
#'   package="rmaven")
#' )
#' }
resolve_dependencies = .resolve_dependencies


#' @inherit .compile_jar
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
