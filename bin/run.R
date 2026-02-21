library(testthat)

# Creates the `results.json` for the test runner with `test_slug.R` supplied from `run.sh`.

# Arguments:
# 1: absolute path to exercise `test_slug.R`

# Output:
# Returns a JSON of the testing summary.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md


test_slug <- commandArgs(trailingOnly = TRUE)

test_slug_str <- paste(readLines(test_slug, warn = FALSE), collapse = "\n")                # Read in `test_slug.R` as string
test_matches <- gregexpr("test_that\\([\\s\\S]*?\\n?}\\n?\\)", test_slug_str, perl = TRUE) # Match test sets in `test_slug.R`
code_run <- unlist(regmatches(test_slug_str, test_matches))                                # Vector of test set code strings from `test_slug.R`

stdout <- capture.output(testout <- test_file(test_slug, reporter = "list")) # Run `test_slug.R`, get testthat output and capture stdout
stdout <- substring(paste(stdout, collapse = "\n"), 1, 500)                  # Trim stdout

json_list <- list(
  status = "pass",
  version = 3
)

get_name <- function(test_name) { # takes a string of test name
  if (grepl("^(\\d+)\\. +", test_name)){  # concept exercise test names are prefixed with number
    matches <- unlist(regmatches(test_name, regexec("^(\\d+)\\. +(.+)$", test_name))) # Get test number and name
    return(c(matches[2], matches[3]))
  }
  c("0", test_name) # practice exercises assigned dummy test number and returned an unmodified name
}

if (is.na(testout[[1]]$test[[1]])) { # If test_name is NA, there was a compilation / pretest error
  stderr <- unlist(testout[[1]]$results)$message
  json_list$status <- "error"
  json_list$message <- substring(stderr, 1, 5000) # trim stderr for debugging
} else { # add tests if no compilaton / pretest error
  tests <- lapply(seq_along(testout), function(i) { # Outer loop over all named test sets.
    test_name <- testout[[i]]$test[[1]]

    test_code_run <- if (i <= length(code_run)) code_run[i] else "" # a likely unnecessary bounds check
    num_name <- get_name(test_name)

    lapply(testout[[i]]$results, function(result) { # Inner loop for test sets with more than one test.
      test_result <- result[[1]]
      test_status <- if (test_result == "success") {
                       "pass"
                     } else if (startsWith(test_result, "Error")) {
                       "error"
                     } else {
                       "fail"
                     }
    
      if (test_status != "pass") json_list$status <<- "fail" # test "fail" or "error" results in exercise "fail"

      test <- list(name = num_name[2],
                   test_code = test_code_run,
                   status = test_status)

      if (test$status != "pass") test$message <- test_result           # add message if not passing
      if (stdout != "" && test$status != "pass") test$output <- stdout # need for output in these cases
      if (num_name[1] != "0") test$task_id <- as.numeric(num_name[1])  # add task_id if nonzero

      test
    })
  })
  
  json_list$tests <- unlist(tests, recursive = FALSE)
}

spaces <- function(n, indt) paste(rep(strrep(" ", indt), n), collapse = "") # helper function for `to_json`

to_json <- function(x, i = 0, indent = 4) {
  if (is.character(x)) return(encodeString(paste(x, collapse = ""), quote = '"'))
  if (is.numeric(x)) return(as.character(x))
  if (is.null(names(x))) {
    items <- vapply(x, to_json, "", i = i + 1, indent = indent)
    return(paste0("[\n", paste0(spaces(i + 1, indent), items, collapse = ",\n"), "\n", spaces(i, indent), "]"))
  }
  items <- vapply(seq_along(x), function(j) {
                    paste0(spaces(i + 1, indent), '"', names(x)[j], '": ', to_json(x[[j]], i + 1, indent))
                  }, "")
  paste0("{\n", paste(items, collapse = ",\n"), "\n", spaces(i, indent), "}")
}

cat(to_json(json_list), "\n", sep = "")  # create `results.json`
