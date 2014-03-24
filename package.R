#' Simplified loading and installing of packages
#'
#' This is a wrapper to \code{\link{require}} and \code{\link{install.packages}}.
#' Specifically, this will first try to load the package(s) and if not found
#' it will install then load the packages. Additionally, if the 
#' \code{update=TRUE} parameter is specified it will check the currently 
#' installed package version with what is available on CRAN (or mirror) and 
#' install the newer version.
#' 
#' @param pkgs a character vector with the names of the packages to load.
#' @param install if TRUE (default), any packages not already installed will be.
#' @param update if TRUE, this function will install a newer version of the
#'        package if available.
#' @param quiet if TRUE (default), package startup messages will be suppressed.
#' @param verbose if TRUE (default), diagnostic messages will be printed.
#' @param ... other parameters passed to \code{\link{require}}, 
#'            \code{\link{install.packages}}, and 
#'            \code{\link{available.packages}}.
#' @return a data frame with four columns and rownames corresponding to the
#'         packages to be loaded. The four columns are: loaded (logical 
#'         indicating whether the package was successfully loaded), installed 
#'         (logical indicating that the package was installed or updated), 
#'         loaded.version (the version string of the installed package), and 
#'         available.version (the version string of the package currently 
#'         available on CRAN). Note that this only reflects packages listed in 
#'         the \code{pkgs} parameter. Other packages may be loaded and/or 
#'         installed as necessary by \code{install.packages} and \code{require}.
#'         If \code{verbose=FALSE} the data frame will be returned using 
#'         \code{\link{invisible}}.
#' @export
#' @example
#' \dontrun{
#' package(c('devtools','lattice','ggplot2','psych'))
#' }
package <- function(pkgs, install=TRUE, update=FALSE, quiet=TRUE, verbose=TRUE, ...) {
	myrequire <- function(package, ...) {
		result <- FALSE
		if(quiet) { 
			suppressMessages(suppressWarnings(result <- require(package, ...)))
		} else {
			result <- suppressWarnings(require(package, ...))
		}
		return(result)
	}
	mymessage <- function(msg) {
		if(verbose) {
			message(msg)
		}
	}
	
 	installedpkgs <- installed.packages()
	availpkgs <- available.packages(...)[,c('Package','Version')]
	if(nrow(availpkgs) == 0) {
		warning(paste0('There appear to be no packages available from the ',
					   'repositories. Perhaps you are not connected to the ',
					   'Internet?'))
	}
	# It appears that hyphens (-) will be replaced with dots (.) in version
	# numbers by the packageVersion function
	availpkgs[,'Version'] <- gsub('-', '.', availpkgs[,'Version'])
	results <- data.frame(loaded=rep(FALSE, length(pkgs)),
						  installed=rep(FALSE, length(pkgs)),
						  loaded.version=rep(as.character(NA), length(pkgs)),
						  available.version=rep(as.character(NA), length(pkgs)),
						  stringsAsFactors=FALSE)
	row.names(results) <- pkgs
	for(i in pkgs) {
		needInstall <- FALSE
		if(i %in% row.names(installedpkgs)) {
			v <- as.character(packageVersion(i))
			if(i %in% row.names(availpkgs)) {
				if(v != availpkgs[i,'Version']) {
					if(!update) {
						mymessage(paste0('A newer version of ', i, 
										 ' is available ', '(current=', v, 
										 '; available=',
									   availpkgs[i,'Version'], ')'))
					}
					needInstall <- update
				}
				results[i,]$available.version <- availpkgs[i,'Version']
			} else {
				mymessage(paste0(i, ' is not available on the repositories.'))
			}
		} else {
			if(i %in% row.names(availpkgs)) {
				needInstall <- TRUE & install
				results[i,]$available.version <- availpkgs[i,'Version']
			} else {
				warning(paste0(i, ' is not available on the repositories and ',
							   'is not installed locally'))
			}
		}
		if(needInstall | !myrequire(i, character.only=TRUE, ...)) {
			install.packages(pkgs=i, quiet=quiet, ...)
			if(!myrequire(i, character.only=TRUE, ...)) {
				warning(paste0('Error loading package: ', i))
			} else {
				results[i,]$installed <- TRUE
				results[i,]$loaded <- TRUE
				results[i,]$loaded.version <- as.character(packageVersion(i))
			}
		} else {
			results[i,]$loaded <- TRUE
			results[i,]$loaded.version <- as.character(packageVersion(i))
		}
	}
	if(verbose) {
		return(results)
	} else {
		invisible(results)
	}
}
