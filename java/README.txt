This directory is needed to pass CRAN checks.

This happens because CRAN regards the contents of the inst/testdata folder as embedded java code and hence
requires a java directory to exist. However the files are testdata and not a core part of the package, just test data
for the vignettes.
