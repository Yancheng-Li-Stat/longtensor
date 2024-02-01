#' clean (internal)
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
#' @import tidyr
#' @import dplyr

core_tensor <- function(data, right_variables, proj_list, left_variable = NA) {
  core = matrix_to_tensor(tensor_matrix_mult(data, proj_list[[right_variables[1]]], edge_value = left_variable), right_variables[1])

  for (i in seq_along(right_variables)[-1]) {
    mode <- right_variables[i]
    core = matrix_to_tensor(tensor_matrix_mult(core, proj_list[[mode]], edge_value = "core_prob"), mode)
  }

  return(core)
}
