library(testthat)

# Creates the `results.json` for the test runner with arguments supplied from `run.sh`.

# Arguments:
# 1: absolute path to exercise `test_slug.R`

# Output:
# Writes the test results to a results.json file in the passed-in file path.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md


test_slug <- commandArgs(trailingOnly = TRUE)
output <- capture.output(testout <- test_file(test_slug, reporter = "list")) # Run `test_slug.R`, get testthat output and capture stdout
output <- substring(paste(output, collapse = "\n"), 1, 5000)               # Trim stdout
test_slug_str <- paste(readLines(test_slug, warn = FALSE), collapse = "\n")      # Read in `test_slug.R` as string
test_matches <- gregexpr("test_that\\([\\s\\S]*?\\n?}\\n?\\)", test_slug_str, perl = TRUE) # Match test sets in `test_slug.R`
test_code <- unlist(regmatches(test_slug_str, test_matches)) # Vector of test set code strings from `test_slug.R`

json_list <- list(
  status = "pass",
  version = 3,
  message = output,
  tests = list()
)

get_name <- function(test_name) { # takes a string test name
  if (grepl("^(\\d+)\\. +", test_name)){  # concept exercise test names are prefixed with number
    matches <- unlist(regmatches(test_name, regexec("^(\\d+)\\. +(.+)$", test_name))) # Get test number and name
    return(c(matches[2], matches[3]))
  }
  c("0", test_name) # practice exercises assigned dummy test number and returned an unmodified name
}

get_status <- function(result) { # takes a result string from testthat reporter, returns JSON test status
  if (result == "success") return("pass")
  if (startsWith(result, "Error")) return("error")
  "fail"
}

tests <- mapply(function(i) { # Outer loop over all named test sets.
  test_name <- testout[[i]]$test[[1]]

  code <- if (i <= length(test_code)) test_code[i] else "" # a likely unnecessary bounds check
  name <- get_name(test_name)

  lapply(seq_along(testout[[i]]$results), function(j) { # Inner loop for test sets with more than one test.
    test_result <- testout[[i]]$results[[j]][[1]]
    test_status <- get_status(test_result)
    if (test_status != "pass") json_list$status <<- "fail" # test "fail" or "error" results in exercise "fail"

    test <- list(name = name[2], 
         	 test_code = code,
                 status = test_status,
                 message = test_result,
                 task_id = as.numeric(name[1]))

    if (test$task_id == 0) test$task_id <- NULL # remove task_id if zero
    test
  })
}, seq_along(testout))

json_list$tests <- tests

if (is.na(testout[[1]]$test[[1]])) { # If test_name is NA, there was a compilation / pretest error
  test_result <- unlist(testout[[1]]$results)$message
  json_list$status <- "error"
  json_list$message <- substring(test_result, 1, 500) # trim stderr for debugging
  json_list$tests <- NULL
}
if (json_list$message == "") json_list$message <- NULL  # remove message key from top level JSON if still empty

to_json <- function(x, i = 0, indent = 4) {
  spaces <- function(n) paste(rep(strrep(" ", indent), n), collapse = "")
  if (is.character(x)) {
    if (length(x) != 1) x <- paste(x, collapse = "")
    return(encodeString(x, quote = '"'))
  }
  if (is.numeric(x)) return(as.character(x))
  if (is.null(names(x))) {
    items <- vapply(x, to_json, "", i = i + 1, indent = indent)
    return(paste0("[\n", paste0(spaces(i + 1), items, collapse = ",\n"), "\n", spaces(i), "]"))
  }
  items <- vapply(seq_along(x), function(j) {
                    paste0(spaces(i + 1), '"', names(x)[j], '": ', to_json(x[[j]], i + 1, indent))
                  }, "")
  paste0("{\n", paste(items, collapse = ",\n"), "\n", spaces(i), "}")
}

cat(to_json(json_list, indent = 4), "\n", sep = "")  # create `results.json`
