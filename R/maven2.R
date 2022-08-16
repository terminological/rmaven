

#' Start an rJava JVM with or without debugging options
#'
#' This does not do anything if the JVM has already been started.
#'
#' @param debug turn on debugging
#' @param quiet don't report messages (defaults to getOption("rmaven.quiet") or FALSE)
#'
#' @return nothing - called for side effects
#' @export
#'
#' @examples
#' start_jvm(TRUE)
start_jvm = function(debug = FALSE, quiet = getOption("rmaven.quiet",FALSE)) {
  tryCatch({
    if (!rJava::.jniInitialized) {
      if (debug) {
      # pass in debug options
        rJava::.jinit(parameters=c(getOption("java.parameters"),"-Xdebug","-Xrunjdwp:transport=dt_socket,address=8998,server=y,suspend=n"), silent = TRUE, force.init = TRUE)
        if(!quiet) message("java debugging initialised on port 8998")
      } else {
        rJava::.jinit(parameters=getOption("java.parameters"),silent = TRUE, force.init = FALSE)
      }
    }
  }, error = function(e) stop("Java cannot be initialised: ",e$message))
}

## File functions ----

# internal function
# all caches are in a subdirectory of the rmaven
.working_dir = function(artifact = "") {
  tmp = path.expand(fs::path(rappdirs::user_cache_dir("rmaven"),artifact))
  fs::dir_create(tmp)
  return(tmp)
}

.working_file = function(path, artifact="") {
  return(fs::path(.working_dir(artifact), path))
}

# internal function
# detect if `test` file exists and is newer that `original`
.is_newer_than = function(test, original) {
  if (!file.exists(original)) stop("source file doesn't exist")
  if (!file.exists(test)) return(FALSE)
  as.POSIXct(file.info(original)$mtime) < as.POSIXct(file.info(test)$mtime)
}

## Maven coordinates functions ----

#' Maven coordinates
#'
#' @param groupId the maven groupId
#' @param artifactId the maven artifactId
#' @param version the maven version (defaults to "LATEST")
#' @param ... other params ignored apart from packaging (jar or ejb) and coordinates (tests, client, sources, javadoc)
#'
#' @return a coordinates object containing the coordinates
#' @export
#'
#' @examples
#' as.coordinates()
as.coordinates = function(groupId, artifactId, version = "LATEST", ...) {
  out = list(
    groupId = groupId,
    artifactId = artifactId,
    version = version,
    packaging = NULL,
    classifier = NULL
  )
  class(out) = c("coordinates",class(out))
  coordinates = rlang::list2(...)
  if (!is.null(coordinates$packaging)) {
    if (!coordinates$packaging %in% c("jar","ejb","pom")) stop('if packaging given it must be one of "jar" or "ejb"')
    out$packaging = coordinates$packaging
    if (!is.null(coordinates$classifier)) {
      if (!coordinates$classifier %in% c("tests", "client", "sources", "javadoc")) stop('if classifier option is given it must be one of "tests", "client", "sources" or "javadoc"')
      out$classifier = coordinates$classifier
    }
  }
  return(out)
}

# internal function
# get maven artifact coordinates from groupId, artifactId, etc.
.artifact = function(coordinates) {
  out = sprintf("%s:%s:%s", coordinates$groupId, coordinates$artifactId, coordinates$version)
  if (!is.null(coordinates$packaging)) {
    if (!coordinates$packaging %in% c("jar","ejb","pom")) stop('if packaging given it must be one of "jar" or "ejb"')
    out = sprintf("%s:%s", out, coordinates$packaging)
    if (!is.null(coordinates$classifier)) {
      if (!coordinates$classifier %in% c("tests", "client", "sources", "javadoc")) stop('if classifier option is given it must be one of "tests", "client", "sources" or "javadoc"')
      out = sprintf("%s:%s", out, coordinates$classifier)
    }
  }
  return(out)
}

# internal function
# coords = .coordinates(artifact="io.github.terminological:r6-generator:main-SNAPSHOT:pom")
.coordinates = function(artifact) {
  pieces = stringr::str_split_fixed(artifact,":",n=Inf)[1,]
  return(as.coordinates(
    groupId = pieces[1],
    artifactId = pieces[2],
    version = if(length(pieces) > 2) pieces[3] else "LATEST",
    packaging = if(length(pieces) > 3) pieces[4] else NULL,
    classifier = if(length(pieces) > 4) pieces[5] else NULL
  ))
}

.filename = function(coordinates, type = c("thin-jar","fat-jar","src-jar","src-dir")) {
  type = match.arg(type)
  if(is.null(coordinates$packaging)) coordinates$packaging = "jar"
  if (type == "thin-jar")
    return(sprintf("%s-%s.%s", coordinates$artifactId, coordinates$version, coordinates$packaging))
  else if (type == "fat-jar")
    return(sprintf("%s-%s-jar-with-dependencies.%s", coordinates$artifactId, coordinates$version, coordinates$packaging))
  else if (type == "src-jar")
    return(sprintf("%s-%s-src.%s", coordinates$artifactId, coordinates$version, coordinates$packaging))
  else if (type == "src-dir")
    return(sprintf("%s", coordinates$artifactId, coordinates$version))
  else stop("invalid type")
}

.pom_archive_path = function(coordinates, type = c("thin-jar","fat-jar","src-jar","src-dir")) {
  type = match.arg(type)
  if (type == "thin-jar")
    return(sprintf("META-INF/maven/%s/%s/pom.xml", coordinates$groupId, coordinates$artifactId))
  else if (type == "fat-jar")
    return(sprintf("META-INF/maven/%s/%s/pom.xml", coordinates$groupId, coordinates$artifactId))
  else if (type == "src-jar")
    return(sprintf("%s-%s/pom.xml", coordinates$artifactId, coordinates$version))
  else if (type == "src-dir")
    return("pom.xml")
  else stop("invalid type")
}

## Maven command functions ----

# internal function
# loads a maven wrapper distribution from the internet and unzips it into the package working directory
.load_maven_wrapper = function(quiet = getOption("rmaven.quiet",FALSE)) {
  dir = .working_dir()
  if (!file.exists(.working_file("mvnw"))) {
    destfile = .working_file("wrapper.zip")
    if(!quiet) message("Bootstrapping maven wrapper.")
    utils::download.file(
      "https://repo1.maven.org/maven2/org/apache/maven/wrapper/maven-wrapper-distribution/3.1.1/maven-wrapper-distribution-3.1.1-bin.zip",
      destfile = destfile,
      quiet = TRUE
    )
    utils::unzip(destfile,exdir=dir)
    unlink(destfile)
    if(!file.exists(.working_file("mvnw"))) stop("downloading maven wrapper has not been successful")
  }
  if(.Platform$OS.type == "windows") {
    mvnPath = .working_file("mvnw.cmd")
  } else {
    mvnPath = .working_file("mvnw")
  }
  write(c(
    "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.9/apache-maven-3.3.9-bin.zip",
    "wrapperUrl=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar"
  ), .working_file(".mvn/wrapper/maven-wrapper.properties"))
  Sys.chmod(mvnPath)
  return(mvnPath)
}

# find java home for JDK and sets system variable
.java_home = function(set = TRUE, quiet = getOption("rmaven.quiet",FALSE)) {
  jh = getOption("rmaven.java_home",NA)
  if (is.na(jh)) jh = Sys.getenv("JAVA_HOME", unset=NA)
  if (is.na(jh)) {
    try({start_jvm(quiet = TRUE)},silent=TRUE)
    jh = tryCatch({rJava::.jcall( 'java/lang/System', 'S', 'getProperty', 'java.home' )},error = function(e) NA)
  }
  if(is.na(jh)) jh = tail(unlist(stringr::str_split(Sys.getenv("LD_LIBRARY_PATH"),":")),1)
  if(is.na(jh)) stop("Could not determine JAVA_HOME from rJava, LD_LIBRARY_PATH, or Sys.getenv")
  jh_orig = jh
  jh2 = fs::path_dir(jh)
  while(!fs::file_exists(fs::path(jh,"bin/javac")) && jh2 != jh) {
    jh = jh2
    jh2 = fs::path_dir(jh)
  }
  if (!fs::file_exists(fs::path(jh,"bin/javac"))) stop("Couldn't find 'bin/javac' in any parent directories starting at ",jh_orig,", do you have a JDK installed?")
  Sys.setenv("JAVA_HOME"=jh)
  return(jh)
}

# executes a maven goal plus or minus info or debugging
#' Title
#'
#' @param goal the goal of the mvn command ( can be multiple ) e.g. c("clean","compile")
#' @param opts provided options in the form c("-Doption1=value2","-Doption2=value2")
#' @param pom_path optional. the path to a pom.xml file for goals that operate on one
#' @param quiet should output from maven be suppressed?
#' @param debug should output from maven be verbose?
#' @param ... named parameters are passed to maven as options in the form -Dname=value
#'
#' @return the output of the system2 call. 0 on success.
#' @export
#'
#' @examples
execute_maven = function(goal, opts = c(), pom_path=NULL, quiet=getOption("rmaven.quiet",FALSE), debug=FALSE, ...) {
  mvn_path = .load_maven_wrapper()
  named = rlang::list2(...)
  opts2 = paste0("-D",names(named),"=",unlist(named))
  args = c(goal, opts, opts2) #, paste0("-f '",pomPath,"'"))
  if (quiet) args = c(args, "-q")
  if (debug) args = c(args, "-X")
  .java_home(quiet=TRUE)
  # required due to an issue in Mvnw.cmd on windows.
  wd = getwd()
  if(!is.null(pom_path)) setwd(fs::path_dir(pom_path))
  if (!quiet) message("executing: ",mvn_path," ",paste0(args,collapse=" "))
  out = system2(mvn_path, args)
  setwd(wd)
  return(out)
}

#' Fetch an artifact from a repository into the local .m2 cache
#'
#' @param repoUrl the URLs of the repositories to check (defaults to maven central)
#' @param ... can express the coordinates as groupId, artifactId and version strings, plus optionally packaging and coordinates
#' @param coordinates optional, coordinates as a coordinates object (see as.coordinates())
#' @param artifact optional, coordinates as an artifact string groupId:artifactId:version[:packaging[:classifier]] string
#'
#' @return the output of the system2 call. 0 on success.
#' @export
#'
#' @examples
#' tmp = fetch_artifact(artifact="io.github.terminological:r6-generator:main-SNAPSHOT:pom")
fetch_artifact = function(
    repoUrl = c("https://repo1.maven.org/maven2/","https://s01.oss.sonatype.org/content/repositories/snapshots/"),
    ...,
    coordinates = as.coordinates(...),
    artifact = .artifact(coordinates)
  ) {
  return(execute_maven(
    goal = "org.apache.maven.plugins:maven-dependency-plugin:3.3.0:get",
    remoteRepositories = paste0(repoUrl,collapse = ","),
    artifact = artifact
  ))
}

#' Fetch an artifact from a repository to a local directory
#'
#' @param repoUrl the URLs of the repositories to check (defaults to maven central & sonatype snaphots)
#' @param ... can express the coordinates as groupId, artifactId and version strings, plus optionally packaging and coordinates
#' @param coordinates optional, coordinates as a coordinates object (see as.coordinates())
#' @param artifact optional, coordinates as an artifact string groupId:artifactId:version[:packaging[:classifier]] string
#' @param outputDirectory optional path, defaults to the package working directory
#'
#' @return the output of the system2 call. 0 on success.
#' @export
#'
#' @examples
#' tmp = copy_artifact(artifact="io.github.terminological:r6-generator:main-SNAPSHOT:pom")
copy_artifact = function(
    repoUrl = c("https://repo1.maven.org/maven2/","https://s01.oss.sonatype.org/content/repositories/snapshots/"),
    ...,
    coordinates = as.coordinates(...),
    artifact = .artifact(coordinates),
    outputDirectory = .working_dir(artifact)
) {
  fetch_artifact(artifact=artifact)
  execute_maven(
    goal = "org.apache.maven.plugins:maven-dependency-plugin:3.3.0:copy",
    artifact = artifact,
    outputDirectory = outputDirectory
  )
  coords = .coordinates(artifact)
  return(fs::path(outputDirectory,.filename(coords)))
}

# Sonatype snapshots: https://s01.oss.sonatype.org/content/repositories/snapshots/
# github: https://maven.pkg.github.com/OWNER/REPOSITORY
# Jitpack: https://jitpack.io

# # https://stackoverflow.com/questions/1895492/how-can-i-download-a-specific-maven-artifact-in-one-command-line
#
# .checkDependencies = function(path, type = c("fat-jar","thin-jar","src-jar","src-dir"), ...) {
#   type = match.arg(type)
#   # Java dependencies
#   <#if model.getConfig().preCompileBinary()>
#     <#if model.getConfig().packageAllDependencies()>
#     # all java library code and dependencies have already been bundled into a single fat jar
#     # compilation was done on the library developers machine and has no external dependencies
#     classpath = NULL
#     <#else>
#       # the main java library has been compiled but external dependencies must be resolved by maven
#       # successful resolution of the classpath libraries depends on the runtime machine and requires
#       # access to the internet at a minimum.
#       pomLoc = .extractPom()
#       classpath = .resolveDependencies(pomLoc, ...)
#       </#if>
#         <#else>
#         # this is a sources only distribution. The java code must be compiled from the source (distributed in this package as a ${model.getConfig().getPackageName()}-${model.getConfig().getVersion()}-src.jar)
#         # all the dependencies are resolved and packaged into a single fat jar on compilation
#         # N.b. successful compilation is a machine specific thing as the dependencies may have been installed into maven locally
#         pomLoc = .extractSources()
#       .compileFatJar(pomLoc, ...)
#       classpath = NULL
#       </#if>
#
#         # find the jars that come bundled with the library:
#         jars = list.files(.here("java"), pattern=".*\\.jar", full.names = TRUE)
#       jars = jars[!endsWith(jars,"sources.jar") & !endsWith(jars,"javadoc.jar") & !endsWith(jars,"src.jar")]
#
#       # and add any that have been resolved and downloaded by maven:
#       jars = unique(c(jars,classpath))
#       return(jars)
# }
#
# # package working directory
#
#
# # package installation directory
# .here = function(paths) {
#   path.expand(system.file(paths, package="${model.getConfig().getPackageName()}"))
# }
#
#
#
#
#
# # gets the pom.xml file for ${model.getMavenCoordinates()} from a thin jar
# .extractPom = function() {
#   dir = .workingDir()
#   jarLoc = list.files(.here(c("inst/java","java")), pattern = "${model.getArtifactId()}-${model.getMavenVersion()}\\.jar", full.names = TRUE)
#   if (length(jarLoc)==0) stop("couldn't find jar for artifact: ${model.getArtifactId()}-${model.getMavenVersion()}")
#   jarLoc = jarLoc[[1]]
#   pomPath = paste0(dir,"/pom.xml")
#   if (!.fileNewer(jarLoc, pomPath)) {
#     utils::unzip(jarLoc, files = "META-INF/maven/${model.getGroupId()}/${model.getArtifactId()}/pom.xml", junkpaths = TRUE, exdir = dir)
#     if (!file.exists(pomPath)) stop("couldn't extract META-INF/maven/${model.getGroupId()}/${model.getArtifactId()}/pom.xml from ",jarLoc)
#   }
#   return(pomPath)
# }
#
# # gets the pom.xml file for ${model.getMavenCoordinates()} which is the library version we exepct to be bundled in the
# .extractSources = function() {
#   dir = .workingDir()
#   jarLoc = list.files(.here(c("inst/java","java")), pattern = "${model.getArtifactId()}-${model.getMavenVersion()}-src\\.jar", full.names = TRUE)
#   if (length(jarLoc)==0) stop("couldn't find jar for artifact: ${model.getArtifactId()}-${model.getMavenVersion()}-src.jar")
#   jarLoc = jarLoc[[1]]
#   pomPath = paste0(dir,"/${model.getArtifactId()}-${model.getMavenVersion()}/pom.xml")
#   if (!.fileNewer(jarLoc, pomPath)) {
#     utils::unzip(jarLoc, exdir = dir)
#     if (!file.exists(pomPath)) stop("couldn't extract source files from ",jarLoc)
#   }
#   return(pomPath)
# }
#
# # executes maven assembly plugin and relocates resulting fat jar into java library directory
# .compileFatJar = function(pomPath, ...) {
#   fatJarFinal = fs::path(.here("java"),"${model.getArtifactId()}-${model.getMavenVersion()}-jar-with-dependencies.jar")
#   if (!.fileNewer(pomPath, fatJarFinal)) {
#     message("Compiling java library and downloading dependencies, please be patient.")
#     .executeMaven(
#       pomPath,
#       goal = c("compile","assembly:assembly"),
#       opts = c(
#         "-DdescriptorId=jar-with-dependencies",
#         "-Dmaven.test.skip=true"
#       ),
#       ...
#     )
#     message("Compilation complete")
#     fatJar = fs::path_norm(fs::path(pomPath, "../target/${model.getArtifactId()}-${model.getMavenVersion()}-jar-with-dependencies.jar"))
#     fs::file_move(fatJar, fatJarFinal)
#   }
#   return(fatJarFinal)
# }
#
# # execute a `dependency:build-classpath` maven goal on the `pom.xml`
# .resolveDependencies = function(pomPath, ...) {
#   classpathLoc = paste0(.workingDir(), "/classpath.txt" )
#   # If the classpath file is already there we need to check that the entries on the class path are indeed available on this machine
#   # as they may have been moved or deleted
#   if(file.exists(classpathLoc)) {
#     classpathString = unique(readLines(classpathLoc,warn = FALSE))
#     if (!all(file.exists(classpathString))) {
#       # we need to rebuild the classpath file as some dependencies are not available
#       unlink(classpathLoc)
#     }
#   }
#   if(!.fileNewer(pomPath,classpathLoc)) {
#     message("Calculating classpath and updating dependencies, please be patient.")
#     .executeMaven(
#       pomPath,
#       goal = "dependency:build-classpath",
#       opts = c(
#         paste0("-Dmdep.outputFile=classpath.txt"),
#         paste0("-DincludeScope=runtime")
#       ),
#       ...
#     )
#     message("Dependencies updated")
#   }
#
#   if(.Platform$OS.type == "windows") {
#     classpathString = unique(scan(classpathLoc, what = "character", sep=";", quiet=TRUE))
#   } else {
#     classpathString = unique(scan(classpathLoc, what = "character", sep=":", quiet=TRUE))
#   }
#
#   if (!all(file.exists(classpathString)))
#     stop("For some inexplicable reason, Maven cannot determine the classpaths of the dependencies of this library on this machine. You can try ${model.getConfig().getPackageName()}::JavaApi$rebuildDependencies()")
#   return(classpathString)
# }
#

