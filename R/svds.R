#' tensor-vector multiplication
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @param param3 Description of the first parameter.
#' @param param4 Description of the second parameter.
#' @param param5 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @import tidyr
#' @import dplyr
#' @import RSpectra
#' @export

tensor_svds <- function(edges, mode, edge_value = NA, irrelevant = NA, dim = c(1, 1, 1)) {

  diff = setdiff(names(edges), c(mode, edge_value, irrelevant))

  edges_right = edges %>% select(all_of(diff))

  edges_left = edges %>% select(all_of(mode))

  vector_right = expand.grid(lapply(edges_right, unique))

  vector_left = expand.grid(lapply(edges_left, unique))

  right_multiply <- function(x, args) {
    vector_right$value <- x
    vector_left <- left_join(vector_left, tensor_vector_mult(args, vector_right, edge_value, irrelevant), by = mode)
    return(vector_left$value)
  }

  left_multiply <- function(x, args) {
    vector_left$value <- x
    vector_right <- left_join(vector_right, tensor_vector_mult(args, vector_left, edge_value, irrelevant), by = diff)
    return(vector_right$value)
  }

  result <- svds(right_multiply, dim[1], nu = dim[2], nm = dim[3], Atrans = left_multiply, dim = c(nrow(vector_left), nrow(vector_right)), args = edges)

  u <- result$u
  new_col_names_left <- paste(mode, 1:dim[2], sep = "_")
  colnames(u) <- new_col_names_left
  u_tibble <- as_tibble(u)
  u_combine <- bind_cols(vector_left, u_tibble)

  return(u_combine)
}
