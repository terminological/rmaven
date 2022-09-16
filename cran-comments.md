## R CMD check results

## Test environments

GitHub actions test environments:
* os: macOS Big Sur 11, R: 4.1.0, Java 11
* os: Ubuntu 20.04; R: 4.1.0, Java 11
* os: Ubuntu 20.04, R: 3.6.1, Java 8
* os: Windows Server 2022, R: 4.2.0, Java 11
* os: Ubuntu 20.04, R: 4.2.0, Java 17
* os: Ubuntu 20.04, R: devel, Java 17

## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## CRAN notes justifications

* This project stores configuration data in the `rappsdir::user_cache()` directory in line with CRAN policies

* Maven relies heavily on downloading jar files from the internet. Some examples will take a long time to run on first use and have been surrounded by \donttest. 
This package will not work offline however in general Maven will fail gracefully and retry next time.

* This is a new release.

* This package in a compilation tool. It includes very simple .java, .class and .jar files as testing data in the 
`inst/testdata` directory. These are used during automated testing, and vignettes of the package, which checks the package can 
install these java files, and resolve their dependencies. They are not a functional part of the package, and only get executed in the getting started vignette.

5 Sept 2022

CRAN feedback:
Thanks, we see this creates ~/.m2, i.e. touches the user filespace.
Hence rejected, see the CRAN policies.
Please fix and resubmit.

* This package executes Java's build tool, Apache Maven, which will download and cache Java library files. 
After this initial feedback from CRAN, the package has been configured to use the rmaven package cache directory `rappsdir::user_cache()/rmaven/.m2/respository/` 
rather than the Java standard location (`~/.m2/repository`) as the maven cache location. This enables users to locally install Java libraries from the central repositories and use them from within R, thus 
removing the need to distribute Java `jar` files with R packages, in line with CRAN best practice. By moving from the Java default
location to the CRAN approved location, there may be wasted bandwidth and disk-space on the users computer duplicating any Java libraries that have already been
cached in the Java standard location, by Java IDEs for example. This will be more of an issue for Java developers building R packages that use `rmaven` than 
users of an R package relying on `rmaven`, and is a unavoidable result of this CRAN policy. I have built the option for users to reconfigure the
cache directory back to the Java standard location should they wish to.
