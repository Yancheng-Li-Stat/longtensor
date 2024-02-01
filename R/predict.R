#' @import tidyr
#' @import dplyr
NULL

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

extract <- function(new_data, proj, column) {

  long_format <- proj %>%
    pivot_longer(
      cols = -all_of(column),
      names_to = "temp",
      values_to = "core_prob"
    )

  temp_values <- long_format %>%
    filter(get(column) == new_data[[column]]) %>%
    select(-all_of(column)) %>%
    dplyr::rename(!!column := temp)

  return(temp_values)
}

#' predict
#'
#' Description of what your function does. This part can span multiple lines
#' and will appear in the Details section of the documentation.
#'
#' @param param1 Description of the first parameter.
#' @param param2 Description of the second parameter.
#' @return What the function returns.
#' @examples
#' testfunction(1,2) # An example of how to use the function.
#' @import tidyr
#' @import dplyr
#' @export

predict <- function(embed, new_data) {
  columns <- names(new_data)
  core <- embed$core

  for (col in columns) {
    extract <- extract(new_data, embed[[col]], col)

    core <- core %>%
      left_join(extract, by = col, suffix = c("_core", "_test")) %>%
      mutate(core_prob = core_prob_core * core_prob_test) %>%
      select(-starts_with("core_prob_"))
  }

  return(sum(core$core_prob, na.rm = TRUE))
}
