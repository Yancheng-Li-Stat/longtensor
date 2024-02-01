#' extract (internal)
#'
#' extract
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @import tidyr
#' @import dplyr
#' @import foreach
#' @import doParallel
#' @export

accuracy <- function(embed, test_set, outcome) {
  # Ask the user if they want to enable parallel processing
  enable_parallel <- tolower(readline(prompt = "Enable parallel processing? (yes/no): ")) == "yes"

  # Initialize the number of cores variable
  num_cores <- 1

  # If parallel processing is enabled, ask for the number of cores
  if (enable_parallel) {
    num_cores <- as.integer(readline(prompt = "Enter the number of cores to use: "))
    # Load the necessary packages for parallel processing
    require(doParallel)
    require(foreach)

    # Register the parallel backend
    registerDoParallel(cores = num_cores)
  }

  ss_res <- foreach(i = 1:nrow(test_set), .combine = '+', .packages = c('dplyr', 'tidyr')) %dopar% {
    single_row_tibble <- test_set %>%
      dplyr::slice(i)  %>%
      dplyr::select(-all_of(outcome))

    prediction <- predict(embed, single_row_tibble)

    actual <- test_set[i, ][[outcome]]

    squared <- (prediction - actual)^2

    return(squared)
  }

  # Calculate R-squared value
  actual <- test_set[[outcome]]
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - ss_res / ss_tot

  # If parallel processing was enabled, stop the parallel backend
  if (enable_parallel) {
    stopImplicitCluster()
  }

  return(r_squared)
}
