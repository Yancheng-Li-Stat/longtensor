#' clean (internal)
#'
#' clean the given tibble such that it only contains the relevant columns)
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @import tidyr
#' @import dplyr

clean <- function(data, outcome, column, duplicates = "average") {
  if (outcome == "outcome_unweighted_1"){
    unique_combinations <- data %>%
      select(all_of(column)) %>%
      distinct()
    return(unique_combinations)
  }
  else if (duplicates == "most") {
    # Define a mode function to get the most common element (or the first in case of a tie)
    Mode <- function(x) {
      ux <- unique(x)
      ux[which.max(tabulate(match(x, ux)))]
    }

    # First, find the majority store for each product and day combination
    majority_outcome <- data %>%
      group_by(!!!syms(column)) %>%
      summarise(!!outcome := Mode(.data[[outcome]]), .groups = "drop")

    # Now, get all unique combinations of product and day, and join with the majority store
    all_combinations <- data %>%
      distinct(!!!syms(column)) %>%
      left_join(majority_outcome, by = column)

    return(all_combinations)
  }
  else if (duplicates == "average") {
    # Find the average store for each product and day combination
    average_outcome <- data %>%
      group_by(!!!syms(column)) %>%
      summarise(!!outcome := mean(.data[[outcome]], na.rm = TRUE), .groups = "drop")

    # Now, get all unique combinations of product and day, and join with the majority store
    all_combinations <- data %>%
      distinct(!!!syms(column)) %>%
      left_join(average_outcome, by = column)

    return(all_combinations)
  }
  else if (duplicates == "add") {
    # Find the average store for each product and day combination
    sum_outcome <- data %>%
      group_by(!!!syms(column)) %>%
      summarise(!!outcome := sum(.data[[outcome]], na.rm = TRUE), .groups = "drop")

    # Now, get all unique combinations of product and day, and join with the majority store
    all_combinations <- data %>%
      distinct(!!!syms(column)) %>%
      left_join(sum_outcome, by = column)

    return(all_combinations)
  }
}
