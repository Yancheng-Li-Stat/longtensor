#' make_interaction_model
#'
#' @param fo a formula, like outcome ~ (row_nums & context) * measurement_type.
#' @param tib a tibble that contains the variables in the formula. The only exception is that the left-hand-side can be 1 and this does not need to be in tib.
#' @param dropNA recommended.  This drops rows of tib if there are any NA's among the essential variables.
#'
#' @return a list with four elements.  First, the sparse Matrix A. Second, row_universe which is akin to the row names of A, but in a tidy form.  Thir, column_universe which is like row_universe. Fourth, some settings.
#' @export
#'
#' @examples
#' @importFrom magrittr %>%
make_interaction_model = function(fo, tib, duplicates = "average", parse_text= FALSE, dropNA = TRUE, data_prefix = NULL,...){
  # This returns a list with elements
  #  interaction_tibble: sparse matrix for formula fo on tibble tib.
  #  row_universe: a tibble of distinct row-variable values, with the row_num (i.e. corresponding row number in A)
  #  column_universe: a tibble of distinct column-variable values, with the col_num (i.e. corresponding column number in A)
  #  settings: a bunch of stuff.

  if(parse_text & (duplicates != "add")){
    duplicates = "add"
    warning("duplicates set to `add` because this is text and that's what we do.  ")
  }

  allowed_duplicate_values <- c("most", "add", "average")
  if (!duplicates %in% allowed_duplicate_values) {
    stop("Invalid value for 'duplicates'. Choose either 'most', add' or 'average'.")
  }


  dumb_formula = ~1
  boolean_first_symbol_is_tilde = fo[[1]] == dumb_formula[[1]]
  # if no left hand side in formula, then make it a 1
  if(length(fo)==2 & boolean_first_symbol_is_tilde){
    # fo = update_lhs_to_1(fo, quiet = FALSE)
    fo = stats::as.formula(paste("1", deparse(fo)))
  }


  vars = parse_formula(fo, tib)
  #outcome_column = vars[[1]]
  #row_column = vars[[2]]
  #column_column = vars[[3]]
  target = vars[[1]]
  features = vars[-1]

  # print(column_column)
  if(parse_text){
    # tib =
    if(length(column_column)>1){
      tib = tib %>%
        dplyr::select(all_of(row_column), tidyselect::all_of(column_column)) %>%
        pivot_longer(-all_of(row_column), names_to = "from_text", values_to = "text") %>%
        tidytext::unnest_tokens("token", text) %>%
        dplyr::mutate(outcome_unweighted_1 = 1)
      column_column=c("from_text", "token")
    }
    if(length(column_column)==1){
      tib = tib %>%
        dplyr::select(all_of(row_column), text = tidyselect::all_of(column_column)) %>%
        # pivot_longer(-all_of(row_column), names_to = "from_text", values_to = "text") %>%
        tidytext::unnest_tokens("token", text) %>%
        dplyr::mutate(outcome_unweighted_1 = 1)
      column_column="token"
    }

    data_prefix= "text"
  }

  im =make_interaction_model_from_variables(tib=tib,
                                            target=target,
                                            features=features,
                                            vars=NULL,
                                            dropNA=dropNA,
                                            duplicates=duplicates)

  outcome_aggregation = duplicates
  if(target == "outcome_unweighted_1") outcome_aggregation = "count"

  im$settings = list(fo = fo,
                     data_prefix = data_prefix,
                     outcome_aggregation = outcome_aggregation,
                     target = target,
                     features = features)
  # im = list(interaction_tibble = interaction_tibble_list$interaction_tibble,
  #           row_universe=interaction_tibble_list$row_index,
  #           column_universe = interaction_tibble_list$col_index,
  #           settings = list(fo = fo,
  #                           data_prefix = data_prefix,
  #                           outcome_variables = outcome_column,
  #                           row_variables = row_column,
  #                           column_variables = column_column))
  class(im) = "interaction_model"
  return(im)
}





#' make_interaction_model_from_variables (internal to make_interaction_tibble and text2sparse)
#'
#' @param tib
#' @param row_column
#' @param column_column
#' @param outcome_column
#'
#' @return
#' @export
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate select distinct row_number left_join group_by ungroup summarize n
#' @importFrom stats sd
#' @importFrom tidyr drop_na
#' @importFrom tidyselect all_of
#'
#' @examples
make_interaction_model_from_variables = function(tib, target, features, vars=NULL, dropNA, duplicates){

  cleaned_tibble <- clean(tib, target, unlist(features), duplicates = duplicates) #%>%
  #  rename_with(~paste0(., "_index"), all_of(unlist(features)))

  features_list <- list()

  for (col_name in features) {

      column_extract <- cleaned_tibble %>% select(all_of(col_name))

      column_universe <- expand.grid(lapply(column_extract, unique)) %>%
        mutate(index = row_number())
      column_universe <- as_tibble(column_universe)

      if(length(col_name) >= 2) {
        new_col_name <- paste(col_name, collapse = "_")

        # Perform the join and create new column dynamically
        cleaned_tibble <- cleaned_tibble %>%
          # Perform a left join with small_tibble based on dynamic column names
          left_join(column_universe, by = col_name) %>%
          # Dynamically create a new column that contains the 'index' values
          mutate("{new_col_name}" := index) %>%
          # Remove the original columns used for joining and the 'index' column if no longer needed
          select(-all_of(col_name), -index)

        features_list[[new_col_name]] <- column_universe
      }
      else {
        cleaned_tibble <- cleaned_tibble %>%
          # Join with small_tibble to get corresponding indices
          left_join(column_universe, by = col_name) %>%
          # Replace the original column with its index without changing the column name
          mutate(!!sym(col_name) := index) %>%
          # Remove the temporary 'index' column
          select(-index)

        features_list[[col_name]] <- column_universe
      }

      #features_list[[paste(col_name, "universe", sep = "_")]] <- column_universe
  }

  unfolding_list <- list()

  for (col_name in features) {

    if (length(col_name) >= 2) {
      new_col_name <- paste(col_name, collapse = "_")

      row_extract <- cleaned_tibble %>% select(-all_of(c(new_col_name, target)))

      row_universe <- expand.grid(lapply(row_extract, unique))%>%
        mutate(index = row_number())
      row_universe <- as_tibble(row_universe)

      unfolding_list[[new_col_name]] <- row_universe
    }
    else {
      row_extract <- cleaned_tibble %>% select(-all_of(c(col_name, target)))

      row_universe <- expand.grid(lapply(row_extract, unique))%>%
        mutate(index = row_number())
      row_universe <- as_tibble(row_universe)

      unfolding_list[[col_name]] <- row_universe
    }
  }

  cleaned <- clean(tib, target, unlist(features), duplicates = duplicates)

  result_list <- list(cleaned_tibble = cleaned,
                      interation_tibble = cleaned_tibble,
                      features_universe = features_list,
                      features_unfolding = unfolding_list)
}
