## Java Virtal Machine functions ----

# find java home for JDK and sets system variable
.java_home = function(set = TRUE, quiet = getOption("rmaven.quiet",FALSE), require_jdk = FALSE) {
  jh = getOption("rmaven.java_home",NA)
  if (is.na(jh)) jh = Sys.getenv("JAVA_HOME", unset=NA)
  if (is.na(jh)) {
    try({start_jvm(quiet = TRUE)},silent=TRUE)
    jh = tryCatch({rJava::.jcall( 'java/lang/System', 'S', 'getProperty', 'java.home' )},error = function(e) NA)
  }
  if(is.na(jh)) jh = utils::tail(unlist(stringr::str_split(Sys.getenv("LD_LIBRARY_PATH"),":")),1)
  if(is.na(jh)) stop("Could not determine JAVA_HOME from rJava, LD_LIBRARY_PATH, or Sys.getenv")

  jh_orig = jh
  jh_parent = fs::path_dir(jh)
  while(!.is_jdk_home(jh) && jh_parent != jh) {
    # look for a jdk
    jh = jh_parent
    jh_parent = fs::path_dir(jh)
  }

  if (!.is_jdk_home(jh)) {

    if (require_jdk) stop("Couldn't find 'bin/javac' in any parent directories starting at ",jh_orig,", do you have a JDK installed?")
    # settle for a jre if we can find one
    jh = jh_orig
    jh_parent = fs::path_dir(jh)
    while(!.is_jre_home(jh) && jh_parent != jh) {
      # look for a jdk
      jh = jh_parent
      jh_parent = fs::path_dir(jh)
    }
    stop("Couldn't find 'bin/javac(.exe)' or 'bin/java(.exe)' in any parent directories starting at ",jh_orig,", please set options('rmaven.java_home'=...) to the root of a JDK (the directory above 'bin/javac').")
  }
  if (set) Sys.setenv("JAVA_HOME"=jh)
  return(jh)
}

.is_jdk_home = function(path = .java_home(set=FALSE, quiet=TRUE)) {
  if(.Platform$OS.type == "windows") {
    return(
      fs::file_exists(fs::path(path,"bin/javac.exe"))
      # fs::file_exists(fs::path(path,"bin/javac.cmd")) ||
      # fs::file_exists(fs::path(path,"bin/javac.bin"))
    )
  } else {
    return(fs::file_exists(fs::path(path,"bin/javac")))
  }
}

.is_jre_home = function(path = .java_home(set=FALSE, quiet=TRUE)) {
  if(.Platform$OS.type == "windows") {
    return(fs::file_exists(fs::path(path,"bin/java.exe")))
  } else {
    return(fs::file_exists(fs::path(path,"bin/java")))
  }
}

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
#' start_jvm()
#' # start_jvm(debug = TRUE)
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

#' Find location of all the jars in a particular package
#'
#' @param package_name the R package name
#' @param types the jar types to look for in the package: one of "all","thin-jar","fat-jar","src"
#'
#' @return a vector of package jars
#' @export
#'
#' @examples
#' package_jars("rmaven")
#' package_jars("rmaven","thin-jar")
package_jars = function(package_name, types = c("all","thin-jar","fat-jar","src")) {
  types = match.arg(types)
  pkgloc = system.file(package = package_name)
  if (pkgloc=="") stop("no package found for: ",package_name)
  files = fs::dir_ls(pkgloc,recurse = TRUE)
  if (types == "all") {
    return(files[fs::path_ext(files)=="jar"])
  } else if (types == "thin-jar") {
    return(.unclassified_jars_only(files))
  } else if (types == "fat-jar") {
    return(.classified_jars_only(files,"jar-with-dependencies"))
  } else if (types == "src") {
    return(.classified_jars_only(files,"src"))
  }
  stop("package jars, unknown type: ",types)
}

# internal function
.unclassified_jars_only = function(files) {
  files = files[fs::path_ext(files)=="jar"]
  matched = apply(
    matrix(
      sapply(.classifier_opts, function(c) (stringr::str_ends(fs::path_ext_remove(files), c))),
      ncol = length(.classifier_opts)),
    1, any) # collapse rowwise using any()
  files = files[!matched]
  return(files)
}

# internal function
# e.g. classifier = "jar-with-dependencies"
.classified_jars_only = function(files, classifier) {
  files = files[fs::path_ext(files)=="jar"]
  files = files[stringr::str_ends(fs::path_ext_remove(files), classifier)]
  return(files)
}

# internal function
# all caches are in a sub-directory of the rmaven
.working_dir = function(artifact = "", subpath="") {
  artifact = stringr::str_replace_all(artifact,stringr::fixed(":"),"_")
  tmp = fs::path_expand(fs::path(rappdirs::user_cache_dir("rmaven"),artifact, subpath))
  fs::dir_create(tmp)
  return(tmp)
}

# internal function
.working_file = function(path, artifact="", subpath = "") {
  return(fs::path(.working_dir(artifact, subpath=subpath), path))
}

# internal function
# detect if `test` file exists and is newer that `original`
# if original file does not exist then test is always newer.
.is_newer_than = function(test, original) {
  if (!file.exists(original)) return(TRUE)
  if (!file.exists(test)) stop("test file doesn't exist: ",test)
  as.POSIXct(file.info(original)$mtime) < as.POSIXct(file.info(test)$mtime)
}

.copy_jf_newer_than = function(source, destination) {
  if (source %>% .is_newer_than(destination))
    fs::file_copy(source,destination)
}

## Maven coordinates functions ----

.classifier_opts = c("tests", "client", "sources", "javadoc", "jar-with-dependencies", "src")
.packaging_opts = c("jar","ejb","pom","war")


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
print.coordinates = function(x,...) {
  print(.artifact(x))
}

#' Maven coordinates
#'
#' @param groupId the maven groupId
#' @param artifactId the maven artifactId
#' @param version the maven version
#' @param ... other params ignored apart from packaging (jar or ejb) and classifier (tests, client, sources, javadoc)
#'
#' @return a coordinates object containing the coordinates
#' @export
#'
#' @examples
#' as.coordinates("org.junit.jupiter","junit-jupiter-api","4.13.2")
as.coordinates = function(groupId, artifactId, version, ...) {
  out = list(
    groupId = groupId,
    artifactId = artifactId,
    version = version,
    packaging = NULL,
    classifier = NULL
  )
  class(out) = c("coordinates",class(out))
  coordinates = rlang::list2(...)
  if (is.null(coordinates$packaging)) coordinates$packaging = "jar"
  if (!coordinates$packaging %in% .packaging_opts) stop('if packaging given it must be one of ',paste0(.packaging_opts, collapse=", "))
  out$packaging = coordinates$packaging
  if (!is.null(coordinates$classifier)) {
    if (!coordinates$classifier %in% .classifier_opts) stop('if classifier option is given it must be one of',paste0(.classifier_opts, collapse=", "))
    out$classifier = coordinates$classifier
  }
  return(out)
}

# internal function
# get maven artifact coordinates from groupId, artifactId, etc.
.artifact = function(coordinates) {
  out = sprintf("%s:%s:%s", coordinates$groupId, coordinates$artifactId, coordinates$version)
  if (
    # packaging is present
    !is.null(coordinates$packaging) &&
    # unless packaging is "jar" and no classifier.
    !(coordinates$packaging == "jar" && is.null(coordinates$classifier))) {
    out = sprintf("%s:%s", out, coordinates$packaging)
    if (!is.null(coordinates$classifier)) {
      out = sprintf("%s:%s", out, coordinates$classifier)
    }
  }
  return(out)
}

# internal function
# coordinates = .coordinates(artifact="io.github.terminological:r6-generator:main-SNAPSHOT:pom")
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

# internal function
# jar_path = .m2_path(.coordinates(artifact="io.github.terminological:r6-generator-docs:main-SNAPSHOT"))
# coordinates = .coordinates_from_jar(jar_path)
# .m2_path(coordinates) == jar_path
.coordinates_from_jar = function(jar_path) {
  paths = utils::unzip(jar_path, list = TRUE)
  pom_paths = paths$Name[fs::path_file(paths$Name) == "pom.xml"]
  for (pom_path in pom_paths) {
    # pom_path = pom_paths[1]
    utils::unzip(jar_path,junkpaths = TRUE,files = pom_path,exdir = tempdir(),overwrite = TRUE)
    coords = .coordinates_from_pom(fs::path(tempdir(),"pom.xml"))

    # If there is only one pom.xml return that, or if there are multiple, return first that matches the artifactId
    # NB this might under match a bit e.g. r6-generator, could match r6-generator, r6-generator-docs, r6-generator-runtime
    if (length(pom_paths) == 1 || stringr::str_starts(fs::path_file(jar_path), unlist(coords$artifactId))) {

      if (stringr::str_starts(pom_path,"META-INF/maven")) {
        if (stringr::str_ends(jar_path,"jar-with-dependencies.jar")) coords$classifier = "jar-with-dependencies"
      } else if (stringr::str_ends(jar_path,"src.jar")) {
        coords$classifier = "src"
      }

      return(coords)
    }
  }
  stop("multiple poms found and none have artifactId matching jar name.")
}

# internal function
.coordinates_from_pom = function(pom_path) {
  pomxml = xml2::read_xml(pom_path) %>% xml2::as_list()
  coords = as.coordinates(
    groupId = unlist(pomxml$project$groupId),
    artifactId = unlist(pomxml$project$artifactId),
    version = unlist(pomxml$project$version),
    packaging = unlist(pomxml$project$packaging),
    classifier = NULL
  )
  return(coords)
}

# internal function
# this is the filename part of a path from maven coordinates
.filename = function(coordinates) {
  if(is.null(coordinates$classifier)) {
    return(sprintf("%s-%s.%s", coordinates$artifactId, coordinates$version, coordinates$packaging))
  } else {
    return(sprintf("%s-%s-%s.%s", coordinates$artifactId, coordinates$version, coordinates$classifier, coordinates$packaging))
  }
}

# internal function
.pom_archive_path = function(coordinates) {
  if (
    is.null(coordinates$classifier) # a normal jar file
    || coordinates$classifier == "jar-with-dependencies" # a fat jar file
  ) {
    return(sprintf("META-INF/maven/%s/%s/pom.xml", coordinates$groupId, coordinates$artifactId))
  } else if (
    coordinates$classifier == "src" # a maven assembly source archive file
  ) {
    return(sprintf("%s-%s/pom.xml", coordinates$artifactId, coordinates$version))
  } else {
    stop("there is no pom.xml stored in ",sprintf("-%s-%s-%s.%s", coordinates$artifactId, coordinates$version, coordinates$classifier, coordinates$packaging))
  }
}

# internal function
.m2_path = function(coordinates) {
  groupPath = stringr::str_replace_all(coordinates$groupId, stringr::fixed("."), "/")
  repoPath = sprintf("%s/%s/%s/%s",groupPath,coordinates$artifactId,coordinates$version,.filename(coordinates))
  return(fs::path_expand(fs::path("~/.m2/repository/", repoPath)))
}

## Maven command functions ----

# internal function
# loads a maven wrapper distribution from the internet and unzips it into the rmaven working directory
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

    write(c(
      "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.9/apache-maven-3.3.9-bin.zip",
      "wrapperUrl=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar"
    ), .working_file(".mvn/wrapper/maven-wrapper.properties"))

  }
  if(.Platform$OS.type == "windows") {
    mvnPath = .working_file("mvnw.cmd")
  } else {
    mvnPath = .working_file("mvnw")
  }

  Sys.chmod(mvnPath)
  return(mvnPath)
}

# verbosity settings
.quietly = function(verbose = "normal") {
  if (verbose == "quiet") return(TRUE)
  if (verbose == "debug") return(FALSE)
  return(getOption("rmaven.quiet",FALSE))
}

# verbosity settings
.debug = function(verbose = "normal") {
  if (verbose == "debug") return(TRUE)
  if (verbose == "quiet") return(FALSE)
  return(getOption("rmaven.debug",FALSE))
}

#' Executes a maven goal
#'
#' Maven goals may be executed with or without a pom.xml file. Some maven goals (e.g. compilation)
#' require the use of a JDK. Goals can be
#'
#' @param goal the goal of the mvn command ( can be multiple ) e.g. c("clean","compile")
#' @param opts provided options in the form c("-Doption1=value2","-Doption2=value2")
#' @param pom_path optional. the path to a pom.xml file for goals that operate on one
#' @param quiet should output from maven be suppressed? (-q flag)
#' @param debug should output from maven be verbose? (-X flag)
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#' @param require_jdk does the goal you are executing require a jdk (e.g. compilation)
#' @param ... named parameters are passed to maven as options in the form -Dname=value
#'
#' @return nothing, invisibly
#' @export
#'
#' @examples
#' execute_maven("help:system")
execute_maven = function(goal, opts = c(), pom_path=NULL, quiet=.quietly(verbose), debug=.debug(verbose), verbose = c("normal","debug","quiet"), require_jdk=FALSE, ...) {
  verbose = match.arg(verbose)
  mvn_path = .load_maven_wrapper()
  named = rlang::dots_list(..., .homonyms = "error")
  # filter out unnamed
  # named = list(1,x=2,y="",z=NULL)
  if (length(named) > 0) {
    named = named[!unlist(lapply(named, is.null))]
    named = named[unlist(named) != ""]
    named = named[names(named) != ""]
    opts2 = paste0("-D",names(named),"=",unlist(named))
  } else {
    opts2 = NULL
  }
  args = c(goal, opts, opts2) #, paste0("-f '",pomPath,"'"))
  if (quiet) args = c(args, "-q")
  if (debug) args = c(args, "-X")
  .java_home(quiet=TRUE)
  # changing the wd is required due to an issue in Mvnw.cmd on windows.
  wd = getwd()

    # if (Platform.os == "windows") {
    # wrapper_props = fs::path(fs::path_dir(pom_path),".mvn/wrapper/maven-wrapper.properties")
    # # Windows mvnw.cmd looks for this in the directory the pom is in.
    # if (!file.exists(wrapper_props)) {
    #   write(c(
    #     "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.9/apache-maven-3.3.9-bin.zip",
    #     "wrapperUrl=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar"
    #   ), wrapper_props)
    # }
    # }

  # change the working directory
  if(!is.null(pom_path)) {
    setwd(fs::path_dir(pom_path))
  } else {
    setwd(fs::path_dir(mvn_path))
  }

  if (!quiet) message("executing: ",mvn_path," ",paste0(args,collapse=" "))
  out = system2(mvn_path, args, stdout = TRUE)
  if (!quiet) cat(paste0(c(out,""),collapse="\n"))
  setwd(wd)
  invisible(NULL)
}

#' Fetch an artifact from a repository into the local .m2 cache
#'

#' @param groupId optional, the maven groupId,
#' @param artifactId optional, the maven artifactId,
#' @param version optional, the maven version,
#' @param ... other maven coordinates such as classifier or packaging
#' @param coordinates optional, coordinates as a coordinates object,
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param repoUrl the URLs of the repositories to check (defaults to maven central)
#' @param coordinates optional, but if not supplied groupId and artifactId must be, coordinates as a coordinates object (see as.coordinates())
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param nocache normally artifacts are only fetched if required, nocache forces fetching
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return the .m2 path of the artifact
#' @export
#'
#' @examples
#' fetch_artifact(artifact="io.github.terminological:r6-generator:main-SNAPSHOT:pom")
#' fetch_artifact(coordinates = as.coordinates("org.junit.jupiter","junit-jupiter-api","5.9.0"))
fetch_artifact = function(
    groupId = NULL,
    artifactId = NULL,
    version = NULL,
    ...,
    coordinates = NULL,
    artifact = NULL,
    repoUrl = getOption("rmaven.default_repos"),
    nocache = FALSE,
    verbose = c("normal","quiet","debug")
) {
  if ((is.null(groupId) || is.null(artifactId) || is.null(version)) && is.null(coordinates) && is.null(artifact)) {
    stop("one of groupId,artifactId + version or coordinates or artifact must be given")
  }

  if (!is.null(coordinates)) {
    artifact = .artifact(coordinates)
  } else if (!is.null(artifact)) {
    coordinates = .coordinates(artifact)
  } else {
    coordinates = as.coordinates(groupId, artifactId, version, ...)
    artifact = .artifact(coordinates)
  }

  verbose = match.arg(verbose)
  if(is.null(coordinates)) coordinates = .coordinates(artifact)
  target = .m2_path(coordinates)
  if (nocache) unlink(target)
  if (!fs::file_exists(target)) {
    execute_maven(
      goal = "org.apache.maven.plugins:maven-dependency-plugin:3.3.0:get",
      remoteRepositories = paste0(repoUrl,collapse = ","),
      artifact = artifact,
      verbose = verbose,
      require_jdk = FALSE
    )
  }
  if (!fs::file_exists(target)) stop("did not sucessfully fetch artifact: ",target)
  return(target)
}



#' Copy an artifact from a repository to a local directory
#'
#' @param groupId optional, the maven groupId,
#' @param artifactId optional, the maven artifactId,
#' @param version optional, the maven version,
#' @param ... other maven coordinates such as classifier or packaging
#' @param coordinates optional, coordinates as a coordinates object,
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param repoUrl the URLs of the repositories to check (defaults to maven central & sonatype snaphots)
#' @param outputDirectory optional path, defaults to the rmaven cache directory
#' @param nocache normally artifacts are only fetched if required, nocache forces fetching
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return the output of the system2 call. 0 on success.
#' @export
#'
#' @examples
#' tmp = copy_artifact("org.junit.jupiter","junit-jupiter-api","5.9.0")
#' print(tmp)
copy_artifact = function(
    groupId = NULL,
    artifactId = NULL,
    version = NULL,
    ...,
    coordinates = NULL,
    artifact = NULL,
    outputDirectory = .working_dir(artifact),
    repoUrl = getOption("rmaven.default_repos"),
    nocache = FALSE,
    verbose = c("normal","quiet","debug")
) {
  verbose = match.arg(verbose)

  if ((is.null(groupId) || is.null(artifactId) || is.null(version)) && is.null(coordinates) && is.null(artifact)) {
    stop("one of groupId,artifactId + version or coordinates or artifact must be given")
  }

  if (!is.null(coordinates)) {
    artifact = .artifact(coordinates)
  } else if (!is.null(artifact)) {
    coordinates = .coordinates(artifact)
  } else {
    coordinates = as.coordinates(groupId, artifactId, version, ...)
    artifact = .artifact(coordinates)
  }

  target = fs::path(outputDirectory,.filename(coordinates))
  if (nocache) unlink(target)
  if (!fs::file_exists(.m2_path(coordinates))) {
    fetch_artifact(artifact=artifact, verbose = verbose)
  }
  if (!fs::file_exists(.m2_path(coordinates))) {
    execute_maven(
      goal = "org.apache.maven.plugins:maven-dependency-plugin:3.3.0:copy",
      artifact = artifact,
      outputDirectory = outputDirectory,
      require_jdk = FALSE,
      verbose = verbose
    )
    if (!fs::file_exists(target)) stop("Couldn't copy artifact from local .m2 repo or from repositories")
  } else {
    fs::file_copy(
      .m2_path(coordinates),
      target,
      overwrite = TRUE
    )
  }
  return(target)
}

# # gets the pom.xml file for ${model.getMavenCoordinates()} from a thin jar
.extract_pom = function(
    coordinates,
    path = .m2_path(coordinates),
    artifact = .artifact(coordinates),
    nocache=FALSE,
    verbose = c("normal","quiet","debug")
) {
  verbose = match.arg(verbose)
  dir = .working_dir(artifact)
  target = .working_file("pom.xml", artifact)
  if (nocache) unlink(target)

  if (fs::is_dir(path)) {
    pom_path = fs::path(path,"pom.xml")
    if(!fs::file_exists(pom_path)) stop("no pom found at: ",pom_path)
    # we assume in this case that the path is to a source directory
    pom_path %>% .copy_jf_newer_than(target)
    return(target)
  }

  if (coordinates$packaging == "pom") {
    # this is a direct link to a pom file
    if(!fs::file_exists(path)) stop("no pom found at: ",path)
    fs::path(path) %>% .copy_jf_newer_than(target)
    return(target)
  }

  # does this refer to something that has not yet been downloaded
  if (path == .m2_path(coordinates) && !fs::file_exists(path)) {
    fetch_artifact(coordinates=coordinates, verbose = verbose)
  }

  # this is a jar file (or war, or ejb)
  if (path %>% .is_newer_than(target)) {
    # .pom_archive_path will detect the different types of jar files
    suppressWarnings(try({utils::unzip(path, files = .pom_archive_path(coordinates), junkpaths = TRUE, exdir = dir)},silent = TRUE))
    unzipped_pom = fs::path(dir,fs::path_file(.pom_archive_path(coordinates)))
    if (!fs::file_exists(unzipped_pom)) {
      # stop("couldn't extract pom from presumed jar file: ",path)
      coordinates$packaging = "pom"
      return(.extract_pom(coordinates,artifact = artifact))
      # this is a good idea bu the pom here is only a stub.
    }
    if (unzipped_pom != target) { fs::file_move(unzipped_pom,target) } # I don't see why this should even happen. Only if the pom is not called pom.xml
  }
  return(target)
}

.classpath_file_to_string = function(path) {
  if(.Platform$OS.type == "windows") {
    classpath_string = unique(scan(path, what = "character", sep=";", quiet=TRUE))
  } else {
    classpath_string = unique(scan(path, what = "character", sep=":", quiet=TRUE))
  }
  return(classpath_string)
}

#' Resolve the classpath for an artifact
#'
#' This calculates the dependencies for an artifact which may be specified either as a set of maven coordinates (in which case the
#' artifact is downloaded) or as a path to a jar file containing a pom.xml (e.g. a compiled jar file, a compiled jar-with-dependencies, or a assembled src jar)
#' The resulting file paths which will be in the maven local cache are checked on the filesystem.
#'
#' @param groupId the maven groupId, optional
#' @param artifactId the maven artifactId, optional
#' @param version the maven version, optional
#' @param ... passed on to as.coordinates()
#' @param coordinates the maven coordinates, optional (either groupId,artifactId and version must be specified, or coordinates, or artifact)
#' @param artifact optional, coordinates as an artifact string `groupId:artifactId:version[:packaging[:classifier]]` string
#' @param path the path to the source directory, pom file or jar file. if blank the
#' @param include_self do you want include this path in the classpath. optional, if missing the path will be included if it is a regular jar, or a fat jar, otherwise not.
#' @param nocache do not used cached version, by default we use a cached version of the classpath unless the pom.xml is newer that the cached classpath.
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#'
#' @return a character vector of the classpath jar files (including the current one if appropriate)
#' @export
#'
#' @examples
#'
#' resolve_dependencies(groupId = "commons-io", artifactId = "commons-io", version="2.11.0")
#'
#' resolve_dependencies(artifact = "org.junit.jupiter:junit-jupiter-api:5.9.0")
#'
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT.jar",package="rmaven"))
#'
#' resolve_dependencies(path=
#'   system.file("testdata/test-project-0.0.1-SNAPSHOT-src.jar",package="rmaven"))
#'
resolve_dependencies = function(
    groupId = NULL,
    artifactId = NULL,
    version = NULL,
    ...,
    coordinates = NULL,
    artifact = NULL,
    path = NULL,
    include_self = NULL,
    nocache = FALSE,
    verbose = c("normal","quiet","debug")
) {
  verbose = match.arg(verbose)

  if ((is.null(groupId) || is.null(artifactId) || is.null(version)) && is.null(coordinates) && is.null(artifact)) {
    if (is.null(path) || fs::path_ext(path) != "jar") stop("if neither of groupId + artifactId + version or coordinates or artifact is given, path must point to a jar file containing a pom.xml")
    coordinates = .coordinates_from_jar(path)
  }

  if (!is.null(coordinates)) {
    artifact = .artifact(coordinates)
  } else if (!is.null(artifact)) {
    coordinates = .coordinates(artifact)
  } else {
    coordinates = as.coordinates(groupId, artifactId, version, ...)
    artifact = .artifact(coordinates)
  }

  if (is.null(path)) {
    path = .m2_path(coordinates)
    if (!file.exists(path)) fetch_artifact(coordinates, nocache = nocache, verbose = verbose)
  }

  include_self = (coordinates$packaging == "jar" && (is.null(coordinates$classifier) || coordinates$classifier == "jar-with-dependencies"))

  dir = .working_dir(artifact = .artifact(coordinates))
  classpath_path = .working_file("classpath.txt",artifact = .artifact(coordinates))
  pom_path = .extract_pom(coordinates, path, nocache = nocache, verbose = verbose)

  if (nocache) unlink(classpath_path)

  # If the classpath file is already there we need to check that the entries on the class path are indeed available on this machine
  # as they may have been moved or deleted
  if(file.exists(classpath_path)) {
    classpath_string = .classpath_file_to_string(classpath_path)
    if (!all(file.exists(classpath_string))) {
      # we need to rebuild the classpath file anyway as some dependencies are not available
      unlink(classpath_path)
    }
  }

  if(pom_path %>% .is_newer_than(classpath_path)) {
    if (.quietly(verbose)) message("Calculating classpath and updating dependencies, please be patient.")
    execute_maven(
      pom_path = pom_path,
      goal = "dependency:build-classpath",
      mdep.outputFile="classpath.txt",
      includeScope="runtime",
      verbose = verbose,
      require_jdk = FALSE
    )
  }

  if (!fs::file_exists(classpath_path)) stop("classpath not created")
  classpath_string = .classpath_file_to_string(classpath_path)
  if (include_self) classpath_string = c(path,classpath_string)

  if (!all(file.exists(classpath_string)))
    stop("some classpath dependencies are not resolveable:\n",paste0(classpath_string[!file.exists(classpath_string)],collapse = "\n"))
  return(unique(classpath_string))
}

# Compilation ----

# path is a directory or a -src.jar file
# here::i_am("R/maven.R")
# path = here::here("inst/testdata/test-project-0.0.1-SNAPSHOT-src.jar")
# path = here::here("inst/testdata/test-project")
# .extract_source_code
.extract_source_code = function(path) {

  if (fs::is_dir(path)) {
    # an un jarred source directory
    pom_path = fs::path(path,"pom.xml")
    if (!fs::file_exists(pom_path)) stop("we didn't find a pom.xml file at ",pom_path)
    coordinates = .coordinates_from_pom(pom_path)
    versioned = sprintf("%s-%s", coordinates$artifactId, coordinates$version)
    copy_dir = .working_dir(.artifact(coordinates), subpath = versioned)
    # overwrite = TRUE means the directory contents pf 'path' are directly written into 'copy_dir' rather than as a subdirectory
    fs::dir_copy(path, copy_dir,overwrite = TRUE)
  } else {
    if (!fs::file_exists(path) || fs::path_ext(path) != "jar") stop("we didn't find a jar file at ",path)
    coordinates = .coordinates_from_jar(path)
    if (coordinates$classifier != "src") stop("this routine only works for '...-src.jar' files of the type created by mvn assembly plugin")
    unzip_dir = .working_dir(.artifact(coordinates))
    utils::unzip(path, exdir = unzip_dir,overwrite = TRUE)
    versioned = sprintf("%s-%s", coordinates$artifactId, coordinates$version)
  }

  new_pom_path = .working_file("pom.xml", .artifact(coordinates), subpath = versioned)
  if (!fs::file_exists(new_pom_path)) stop("cannot find pom.xml from extracted source code")
  return(new_pom_path)

}

.do_compile = function(goal, opts, path, classifier = NULL, nocache = FALSE, verbose = c("normal", "quiet", "debug"), ...) {

  verbose = match.arg(verbose)

  if (!fs::file_exists(path)) stop("we didn't something to compile at ",path)

  if (fs::path_ext(path) == "xml") {
    pom_path = path
  } else {
    pom_path = .extract_source_code(path)
  }

  coordinates = .coordinates_from_pom(pom_path)
  project_dir = fs::path_dir(pom_path)

  if (is.null(classifier)) {
    target_jar = fs::path(project_dir,"target",sprintf("%s-%s.jar", coordinates$artifactId, coordinates$version))
  } else {
    target_jar = fs::path(project_dir,"target",sprintf("%s-%s-%s.jar", coordinates$artifactId, coordinates$version, classifier))
  }

  if (nocache) unlink( fs::path(project_dir,"target"), recursive = TRUE)

  if (pom_path %>% .is_newer_than(target_jar)) {
    if (.quietly(verbose)) message("Compiling Java library, please be patient.")
    execute_maven(
      pom_path,
      goal = goal,
      opts = opts,
      verbose = verbose,
      require_jdk = TRUE
    )
  }

  if(!file.exists(target_jar)) stop("could not compile java and assemble file: ",fs::path_file(target_jar))

  return(target_jar)
}


#' Compile and package Java code
#'
#' Compilation will package the Java source code in to a Jar file for further use. It will resolve dependencies and
#' optionally package them into a single 'uber' jar (using maven assembly).
#'
#' @param path the path to - a source code directory contining a pom.xml file, a ...-src.jar assembled by the maven assembly plugin, or a pom.xml file
#' @param nocache normally compilation is only performed if the input has changed. nocache forces recompilation
#' @param verbose how much output from maven, one of "normal", "quiet", "debug"
#' @param with_dependencies compile the Java code to a ...-jar-with-dependencies.jar including transitive dependencies which is easier to embed
#'
#' @return the path to the compiled jar file.
#' @export
#'
#' @examples
#' path = package_jars("rmaven","src")
#' compile_jar(path,nocache=TRUE)
#' path2 = system.file("testdata/test-project",package = "rmaven")
#' compile_jar(path2,nocache=TRUE,with_dependencies=TRUE)
compile_jar = function(path, nocache = FALSE, verbose = c("normal", "quiet", "debug"), with_dependencies = FALSE) {

  verbose = match.arg(verbose)

  if (with_dependencies) {
    target_jar = .do_compile(
      goal = c("compile","assembly:single","package"),
      opts = c(
        "-DdescriptorId=jar-with-dependencies",
        "-Dmaven.test.skip=true"
      ),
      path = path,
      classifier = "jar-with-dependencies",
      nocache = nocache,
      verbose = verbose
    )
  } else {
    target_jar = .do_compile(
      goal = c("compile","package"),
      opts = c(),
      path = path,
      nocache = nocache,
      verbose = verbose
    )
  }

  return(target_jar)
}


options("rmaven.default_repos" = c(
  "https://repo1.maven.org/maven2/",
  "https://s01.oss.sonatype.org/content/repositories/snapshots/",
  "https://jitpack.io"
))
