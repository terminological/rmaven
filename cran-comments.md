## R CMD check results

## Test environments

GitHub actions test environments:
* os: macOS Big Sur 11, R: 4.1.0, Java 11
* os: Ubuntu 20.04; R: 4.1.0, Java 11
* os: Ubuntu 20.04, R: 3.6.1, Java 8
* os: Windows Server 2022, R: 4.1.0, Java 11
* os: Ubuntu 20.04, R: 4.2.0, Java 17
* os: Ubuntu 20.04, R: devel, Java 17

## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## CRAN notes justifications

* This project stores configuration data in the `rappsdir::user_cache()` directory in line with CRAN policies

* It executes Java's build tools Apache Maven. These create their own cache in the Java standard location `~/.m2/repository` this is 
a deliberate side effect of the library, enabling users to locally install Java libraries and use them from within R, thus removing the need to
distribute Java `jar` files with R packages, in line with CRAN best practice.

* Maven relies heavily on downloading jar files from the internet. Some examples will take a long time to run on first use and have been surrounded by \donttest. 
This package will not work offline however in general Maven will fail gracefully and retry next time.

* This is a new release.

* This package in a compilation tool. It includes very simple .java, .class and .jar files as testing data in the inst/java directory. These are used during automated testing of the package, 
which checks the package can install these java files, or resolve their dependencies. They are not a functional part of the package, and only get executed in the getting started vignette.
