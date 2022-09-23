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

* This project stores configuration data in the `rappsdir::user_cache()`
directory in line with CRAN policies.

* Maven relies heavily on downloading jar files from the internet. Some examples
will take a long time to run on first use and have been surrounded by `\donttest`.
This package will not work offline however in general Maven will fail gracefully
and retry next time.

* This is a new release.

* This package in a compilation tool. It includes very simple .java, .class and
.jar files as testing data in the `inst/testdata` directory. These are used
during automated testing, and vignettes of the package, which checks the package
can install these java files, and resolve their dependencies. They are not a
functional part of the package, and only get executed in the getting started
vignette.

5 Sept 2022

CRAN feedback:
  Thanks, we see this creates ~/.m2, i.e. touches the user filespace.
  Hence rejected, see the CRAN policies.
  Please fix and resubmit.

* This package executes Java's build tool, Apache Maven, which will download and
cache Java library files. After this initial feedback from CRAN, the package has
been configured to use the `rmaven` package cache directory
`rappsdir::user_cache()/rmaven/.m2/respository/` rather than the Java standard
location (`~/.m2/repository`) as the maven cache location. 

* This enables users to locally install Java libraries from the central
repositories and use them from within R, thus removing the need to distribute
Java `jar` files with R packages, in line with CRAN best practice.

* By moving from the Java default location to the CRAN approved location, there
may be wasted bandwidth and disk-space on the users computer duplicating any
Java libraries that have already been cached in the Java standard location, by
Java IDEs for example. This will be more of an issue for Java developers
building R packages that use `rmaven` than users of an R package relying on
`rmaven`, and is a unavoidable result of this CRAN policy. I have built the
option for users to reconfigure the cache directory back to the Java standard
location should they wish to.

17 Sept 2022

CRAN feedback:
  Thanks, but really, form my last comment syou should have learned that things
  like
  
    .vignettes/rmaven.Rmd:options("rmaven.m2.repository"="~/.m2/repository")
  
  are absolutely unacceptable. And I already pointed you to the CRAN policies
  you agreed to. No more submissions in the next 6 weeks, please.

  Running R CMD check leaves files within the user filespace behind, but you
  must not write in the user filespace.

* The vignette line mentioned is documentation of an option that is provided to
the user in a fenced code block that is not executed. It is not the source of
any user filespace manipulation. I have rewritten this part of the vignette to
make this completely explicit. I have also addressed an issue with the very 
verbose output of Maven, when the cache is being populated for the first time
was hiding the details of the vignette.

* There was a regression in the examples for the functions
`set_repository_location(...)` and `get_repository_location(...)` which were
introduced to address the previous issue. Unfortunately these created an
empty directory `"~/.m2/repository"` as part of running the examples. These examples
have been re-written to avoid this. As far as we are aware there are no further
examples or vignettes that touch the user filespace, and no `~/.m2/repository`
is seen on this machine after a `R CMD check`. If the user wishes to
configure `rmaven` to cache in the Java default location, thus touching their
own filespace I have provided instructions and caveats.

* The CRAN policies you refer to
(https://cran.r-project.org/web/packages/policies.html) state: "The code and
examples provided in a package should never do anything which might be regarded
as malicious or anti-social. The following are illustrative examples from past
experience...", and, "Packages should not write in the user’s home filespace
...". I interpreted this in the context of RFC-2119
(https://www.rfc-editor.org/rfc/rfc2119) in which the words "ILLUSTRATIVE
EXAMPLES" and "SHOULD" is interpreted as "there may exist valid reasons in
particular circumstances to ignore a particular item, but the full implications
must be understood and carefully weighed before choosing a different course.". I
note that the CRAN package `rappsdir` which we import touches the user filespace
on linux systems by writing to sub-directories of `~/.cache`, so there is 
precedent for the more permissive interpretation. I note `R CMD check` does not 
produce a warning or note for packages that touch the user filespace. 

* I believed my initial submission complied with CRAN policies, as it did not do
anything which could be regarded as malicious or anti-social, and my second
submission also complied, as in normal use the package would not touch the user
filespace. It was unfortunate that the regression mentioned above created the
empty directory whilst running the example code. I understand that your
interpretation of this particular aspect of CRAN policy is very different, and I
have identified and fixed the regression to match your interpretation.

* The implication that I was deliberately doing something unacceptable, and the
knee jerk reaction of banning submission for 6 weeks was unhelpful, and
discourages me from future CRAN submission.
