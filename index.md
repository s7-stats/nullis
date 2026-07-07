# nullis ![](reference/figures/logo.png)

**`statim` Extension for Nonparametric Statistics**

## Installation

The package is not yet on CRAN.

``` r

# Stable version (not yet released)
install.packages("nullis")
```

You can install the development version from GitHub. Note that
[nullis](https://github.com/s7-stats/nullis) depends on
[statim](https://github.com/s7-stats/statim), which is not yet on CRAN.
Fortunately, [pak](https://pak.r-lib.org/) resolves this easily and
automatically via the `Remotes` field in `DESCRIPTION`, so a single
command handles both:

``` r

# install.packages("pak")
pak::pak("s7-stats/nullis")
```

## License

MIT + file LICENSE

## Contributing

We are sincerely grateful for contributions; they are beneficial for the
project and for us as maintainers. Please read
[CONTRIBUTING.md](https://s7-stats.github.io/nullis/CONTRIBUTING.md) for
development setup, pull request guidelines, and workflow notes.

## Code of Conduct

Please note that the nullis project is released with a [Contributor Code
of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
