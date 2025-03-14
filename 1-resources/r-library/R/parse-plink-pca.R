#' Function to instantiate new plink_pca_parser
#'
#' @param eigenval_path Path to PLINK output with .eigenval extension
#' @param eigenvec_path Path to PLINK output with .eigenvec extension
#' @param id_name Name to use for sample ID column in output
#'
#' @returns An object of class plink_pca_parser
#'
#' @import R6
#' @import readr
#' @import dplyr
#'
parse_plink_pca <- function(eigenval_path, eigenvec_path, id_name = "ID") {
  parser <- plink_pca_parser$new(eigenval_path, eigenvec_path, id_name)
  return(parser)
}

#' Class for parsing results of PLINK PCA
#'
#' @field eigenvalues Private field holding eigenvalues
#' @field eigenvectors Private field holding eigenvector (PC) matrix and sample IDs
#'
plink_pca_parser <- R6::R6Class(

  classname = "PLINK PCA Parser",

  public = list(

    #' Initialize by parsing PCA output files from PLINK
    #'
    #' @param eigenval_path Path to PLINK output with .eigenval extension
    #' @param eigenvec_path Path to PLINK output with .eigenvec extension
    #' @param id_name Name to use for sample ID column in output
    #'
    #' @returns Void.
    #'
    initialize = function(eigenval_path, eigenvec_path, id_name) {
      private$eigenvalues <- private$load_eigenvalues(eigenval_path)
      private$eigenvectors <- private$load_eigenvectors(eigenvec_path) |>
        private$parse_eigenvectors(id_name)
    },

    #' Calculate variance explained by any / all principal component(s)
    #'
    #' @param pc Vector of which principal components to return for
    #' @param signif Number of significant figures
    #' @param as_percent Logical. Return as percent (default) or fraction?
    #'
    #' @returns A vector of variances explained per principal component
    #'
    get_variance_explained = function(pc, signif = 3, as_percent = TRUE) {
      variance_explained <- private$eigenvalues / sum(private$eigenvalues)
      variance_explained <- signif(variance_explained, signif)
      if (as_percent) variance_explained <- variance_explained * 100
      return(variance_explained[pc])
    },

    #' Get coordinate matrix
    #'
    #' @param pc Vector of which principal components to return
    #'
    #' @returns A tibble of sample IDs and principal component coordinates
    #'
    get_coordinates = function(pc = c(1, 2)) {
      ID_INDEX <- 1
      return_columns <- c(ID_INDEX, pc + ID_INDEX)
      return(private$eigenvectors[return_columns])
    }

  ),

  active = list(

    #' Active field with sample IDs
    #'
    #' @returns A vector of all sample IDs from private eigenvector table
    #'
    sample_ids = function() {
      sample_ids <- private$eigenvectors[[1]]
      return(sample_ids)
    }

  ),

  private = list(

    eigenvalues = NULL,
    eigenvectors = NULL,

    #' Load and parse a PLINK .eigenval file
    #'
    #' @param file_path Path to PLINK output with .eigenval extension
    #'
    #' @returns A vector of eigenvalues for each principal component
    #'
    load_eigenvalues = function(file_path) {
      eigenvalues <- scan(file_path, quiet = TRUE)
      return(eigenvalues)
    },

    #' Load a PLINK .eigenvec file
    #'
    #' @param file_path Path to PLINK output with .eigenvec extension
    #'
    #' @returns A tibble containing sample IDs and eigenvector values
    #'
    load_eigenvectors = function(file_path) {
      eigenvectors <- readr::read_table(file_path, col_names = FALSE, show_col_types = FALSE) |>
        dplyr::as_tibble()
      return(eigenvectors)
    },

    #' Parse a PLINK .eigenvec file
    #'
    #' @param eigenvectors A tibble of sample and family IDs and principal component coordinates
    #' @param id_name Name to assign sample ID column
    #'
    #' @returns The input tibble, parsed. The family ID column is removed, the sample ID column
    #' renamed, and the principal component coordinate columns renamed as "PC1", "PC2", etc.
    #'
    parse_eigenvectors = function(eigenvectors, id_name) {
      ID_INDEX <- 1
      FAMILY_ID_INDEX <- 2

      eigenvectors <- eigenvectors[-FAMILY_ID_INDEX]
      pc_count <- ncol(eigenvectors[-ID_INDEX])
      pc_columns <- seq(from = ID_INDEX, to = pc_count) + 1
      pc_names <- paste("PC", seq(pc_count), sep = "")
      names(eigenvectors)[ID_INDEX] <- id_name
      names(eigenvectors)[pc_columns] <- pc_names

      return(eigenvectors)
    }

  )
)
