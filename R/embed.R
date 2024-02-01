#' embedding with a tensor
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @param param4 Description of the second parameter.
#' @param param5 Description of the first parameter.
#' @param param6 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @import tidyr
#' @import dplyr
#' @export

embed <- function(interaction_model, k, max_iter = 100, tol = 1e-3) {

  # I need to change this to work with interaction_mdoel
  formula <- interaction_model$settings$fo
  # I need to change this to work with interaction_mdoel
  data <- interaction_model$cleaned_tibble
  # I need to change this to work with interaction_mdoel
  type = "weighted_graph"

  # Function to extract the response variable or return NA for one-sided formulas
  get_response_variable <- function(frm) {
    # Check if the formula has a response variable
    if (attr(terms(frm), "response") == 1) {
      # Extract the response variable name
      return(all.vars(frm)[1])
    } else {
      return(NA)
    }
  }

  # Extract variables from formula
  left_variable <- get_response_variable(formula)
  right_variables <- attr(terms(formula), "term.labels")

  # Check if the input is a single number (not a vector)
  if (!is.vector(k) || length(k) == 1) {
    # If it's a single number, repeat it to create a vector of the specified length
    k = rep(k, length(right_variables))
  }

  # Different behavior based on type
  if (is.na(left_variable) && type == "unweighted_graph") {
    new_tibble <- clean(data, NA, right_variables)
    proj_list <- list()

    for (i in seq_along(right_variables)) {
      mode <- right_variables[i]
      dim <- k[i]
      print(paste0("Initializing ", mode))
      proj <- tensor_svds(new_tibble, mode, dim = c(dim, dim, 0))
      proj_list[[mode]] <- proj
    }

    iter <- 0
    dist <- 100000
    core_norm_old <- 0

    while (iter < max_iter && dist > tol) {
      iter <- iter + 1
      for (i in seq_along(right_variables)) {
        mode <- right_variables[i]
        dim <- k[i]
        core <- core_tensor(new_tibble, right_variables[-i], proj_list)
        proj_list[[mode]] <- tensor_svds(core, mode, edge_value = "core_prob", dim = c(dim, dim, 0))
      }
      core <- core_tensor(new_tibble, right_variables, proj_list)
      core_norm <- sum(core$core_prob, na.rm = TRUE)
      dist <- abs(core_norm - core_norm_old)
      print(paste0("Iteration ", iter, " completed. Distance is ", dist))
      core_norm_old <- core_norm
    }

    core <- core_tensor(new_tibble, right_variables, proj_list)
    result_list <- c(proj_list, list(core = core))
    return(result_list)

  } else if (type == "unweighted_graph") {
    stop("To be completed.")

  } else if (type == "weighted_graph") {
    new_tibble <- clean(data, left_variable, right_variables)
    proj_list <- list()

    for (i in seq_along(right_variables)) {
      mode <- right_variables[i]
      dim <- k[i]
      print(paste0("Initializing ", mode))
      proj <- tensor_svds(new_tibble, mode, edge_value = left_variable, dim = c(dim, dim, 0))
      proj_list[[mode]] <- proj
    }

    iter <- 0
    dist <- 100000
    core_norm_old <- 0

    while (iter < max_iter && dist > tol) {
      iter <- iter + 1
      for (i in seq_along(right_variables)) {
        mode <- right_variables[i]
        dim <- k[i]
        core <- core_tensor(new_tibble, right_variables[-i], proj_list, left_variable = left_variable)
        proj_list[[mode]] <- tensor_svds(core, mode, edge_value = "core_prob", dim = c(dim, dim, 0))
      }
      core <- core_tensor(new_tibble, right_variables, proj_list, left_variable = left_variable)
      core_norm <- sum(core$core_prob, na.rm = TRUE)
      dist <- abs(core_norm - core_norm_old)
      print(paste0("Iteration ", iter, " completed. Distance is ", dist))
      core_norm_old <- core_norm
    }

    core <- core_tensor(new_tibble, right_variables, proj_list, left_variable = left_variable)
    result_list <- c(proj_list, list(core = core))
    return(result_list)

  } else if (type == "censored_data") {
    stop("To be completed.")

  } else {
    stop("Invalid type specified.")
  }
}
