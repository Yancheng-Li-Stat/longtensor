#' @import tidyr
#' @import dplyr
NULL

#' tensor-vector multiplication
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @param param4 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @export

tensor_vector_mult <- function(edges, vector, edge_value = NA, irrelevant = NA) {

  if (is.na(edge_value)) {
    join_cols <- intersect(names(edges), names(vector))
    mode <- setdiff(names(edges), c(names(vector), irrelevant))
    value_temp <- setdiff(names(vector), names(edges))[1]

    result <- edges %>%
      left_join(vector, by = join_cols) %>%
      group_by(across(all_of(mode))) %>%
      summarize(value_temp = sum(!!sym(value_temp), na.rm = TRUE), .groups = "drop")

    return(result)
  } else {
    join_cols <- intersect(names(edges), names(vector))
    mode <- setdiff(names(edges), c(names(vector), edge_value, irrelevant))
    value_temp <- setdiff(names(vector), names(edges))[1]

    result <- edges %>%
      left_join(vector, by = join_cols) %>%
      group_by(across(all_of(mode))) %>%
      summarize(value_temp = sum(!!sym(value_temp) * !!sym(edge_value), na.rm = TRUE), .groups = "drop")

    return(result)
  }
}

#' tensor-matrix multiplication
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @param param4 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @export

tensor_matrix_mult <- function(edges, matrix, edge_value = NA, irrelevant = NA) {

  value_temp <- setdiff(names(matrix), names(edges))

  if (is.na(edge_value)) {
    join_cols <- intersect(names(edges), names(matrix))
    mode <- setdiff(names(edges), c(names(matrix), irrelevant))

    result <- edges %>%
      left_join(matrix, by = join_cols) %>%
      group_by(across(all_of(mode))) %>%
      summarize(across(all_of(value_temp), ~sum(.x, na.rm = TRUE)), .groups = "drop")

    return(result)
  } else {
    join_cols <- intersect(names(edges), names(matrix))
    mode <- setdiff(names(edges), c(names(matrix), edge_value, irrelevant))

    result <- edges %>%
      left_join(matrix, by = join_cols) %>%
      group_by(across(all_of(mode))) %>%
      summarize(across(all_of(value_temp), ~sum(.x * .data[[edge_value]], na.rm = TRUE)), .groups = "drop")

    return(result)
  }
}

#' Transfer a matrix to a tensor (internal)
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.

matrix_to_tensor <- function(matrix, name) {
  # Convert the original tibble to long format
  long_tibble <- matrix %>%
    pivot_longer(
      cols = starts_with(paste0(name, "_")),  # Select columns that start with "value"
      names_to = name,        # This will hold the names "value_1", "value_2"
      values_to = "core_prob"           # This will hold the numerical values
    )

  return(long_tibble)
}

#' vector-vector multiplication (internal)
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @param param4 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.

vector_vector_mult <- function(vector1, vector2, value1, value2) {

  vector2 <- vector2 %>%
    rename_with(~paste0(.x, "_tmp"), all_of(value2))
  value2 <- paste0(value2, "_tmp")

  row <- setdiff(names(vector1), value1)
  col <- setdiff(names(vector2), value2)

  result <- vector1 %>%
    crossing(vector2) %>%
    mutate(value = !!sym(value1) * !!sym(value2)) %>%
    select(all_of(row), all_of(col), value) %>%
    rename_with(~gsub("_tmp$", "", .x))

  return(result)
}
