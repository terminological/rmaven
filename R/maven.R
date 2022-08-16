.loadMavenWrapper = function(dir = rappdirs::user_cache_dir("testRapi")) {
  dir = path.expand(dir)
  if (!file.exists(paste0(dir,"/mvnw"))) {
    destfile = paste0(dir,"/wrapper.zip")
    warning("downloading maven plugin wrapped")
    download.file(
      "https://repo1.maven.org/maven2/org/apache/maven/wrapper/maven-wrapper-distribution/3.1.1/maven-wrapper-distribution-3.1.1-bin.zip",
      destfile = destfile,
      quiet = TRUE
    )
    unzip(destfile,exdir=dir)
    unlink(destfile)
    if(!file.exists(paste0(dir,"/mvnw"))) stop("downloading maven wrapper has not been successful")
  }
  if(.Platform$OS.type == "windows") {
    mvnPath = paste0(dir,"/mvnw.cmd")
  } else {
    mvnPath = paste0(dir,"/mvnw")
  }
  write(c(
    "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.9/apache-maven-3.3.9-bin.zip",
    "wrapperUrl=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar"
  ), paste0(dir,"/.mvn/wrapper/maven-wrapper.properties"))
  Sys.chmod(mvnPath)
  return(mvnPath)
}

.here = function(paths) {
  path.expand(system.file(paths, package="testRapi"))
}

.fileNewer = function(original, test) {
  if (!file.exists(original)) stop("source file doesn't exist")
  if (!file.exists(test)) return(FALSE)
  as.POSIXct(file.info(original)$mtime) < as.POSIXct(file.info(test)$mtime)
}

.extractPom = function(groupId, artifactId, dir = rappdirs::user_cache_dir("testRapi")) {
  dir = path.expand(dir)
  jarLoc = list.files(.here(c("inst/java","java")), pattern = paste0(".*",artifactId,".*","jar"), full.names = TRUE)
  if (length(jarLoc)==0) stop("couldn't find jar for artifact: ",artifactId)
  jarLoc = jarLoc[[1]]
  pomPath = paste0(dir,"/pom.xml")
  if (!.fileNewer(jarLoc, pomPath)) {
    unzip(jarLoc, files = paste0("META-INF/maven/",groupId,"/",artifactId,"/pom.xml"), junkpaths = TRUE, exdir = dir)
    if (!file.exists(pomPath)) stop("couldn't extract pom.xml from ",jarLoc)
  }
  return(path.expand(paste0(dir,"/pom.xml")))
}

.resolveDependencies = function(pomPath, mvnPath = .loadMavenWrapper()) {
  classpathLoc = path.expand(paste0( rappdirs::user_cache_dir("testRapi"), "/classpath.txt" ))
  if(!.fileNewer(pomPath,classpathLoc)) {
    warning("updating project dependencies")
    system2(mvnPath, args = c(
      "dependency:build-classpath",
      paste0("-f ",pomPath), 
      paste0("-Dmdep.outputFile='",classpathLoc,"'"),
      paste0("-Dmdep.pathSeparator='\n'"),
      paste0("-DincludeScope=runtime"),
      "-q"
    ))
  }
  classpathString = readLines(classpathLoc,warn = FALSE)
  return(classpathString)
}

pomPath = .extractPom("io.github.terminological","r6-generator-docs")
print(.resolveDependencies(pomPath))

## Find JAVA_HOME
tail(unlist(stringr::str_split(Sys.getenv("LD_LIBRARY_PATH"),":")),1)
# up 2 levels but does not exist in windows
# mvn -v