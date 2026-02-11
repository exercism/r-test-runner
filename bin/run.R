library(testthat)
library(jsonlite)

# Creates the `results.json` for the test runner with arguments supplied from `run.sh`.

# Arguments:
# 1: exercise `test_slug.R`
# 2: absolute path to `results.json` in output directory

# Output:
# Writes the test results to a results.json file in the passed-in file path.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md


args <- commandArgs(trailingOnly = TRUE) # args[1] = `test_slug.R`, args[2] = file path for `results.json`
output <- capture.output(testout <- test_file(args[1], reporter = "list")) # Run `test_slug.R`, get testthat output and capture stdout
output <- substring(paste(output, collapse = "\n"), 1, 5000)               # Trim stdout
test_slug <- paste(readLines(args[1], warn = FALSE), collapse = "\n")      # Read in `test_slug.R`
test_matches <- gregexpr("test_that\\([\\s\\S]*?\\n?}\\n?\\)", test_slug, perl = TRUE) # Match test sets in `test_slug.R`
test_code <- unlist(regmatches(test_slug, test_matches)) # Vector of test set code strings from `test_slug.R`

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

n <- 1 # number of test being added to `json_list$tests`
for (i in seq_along(testout)) { # Outer loop over all named test sets.
  test_name <- testout[[i]]$test[[1]]

  if (is.na(test_name)) { # If test_name is NA, there was an error before any test was run (e.g. compilation error)
    test_result <- unlist(testout[[i]]$results)$message
    json_list$status <- "error"
    json_list$message <- substring(test_result, 1, 500) # trim stderr for debugging
    next
  }

  code <- ""
  if (i <= length(test_code)) code <- test_code[i] # a likely unnecessary bounds check
  name <- get_name(test_name)

  for (j in seq_along(testout[[i]]$results)) { # Inner loop for test sets with more than one test.
    test_result <- testout[[i]]$results[[j]][[1]]
    test_status <- get_status(test_result)
    if (test_status != "pass") json_list$status <- "fail" # test "fail" or "error" results in exercise "fail"

    json_list$tests[[n]] <- list(name = name[2], 
                                 test_code = code,
                                 status = test_status,
                                 message = test_result,
                                 task_id = as.numeric(name[1]))
    
    if (json_list$tests[[n]]$task_id == 0) json_list$tests[[n]]$task_id <- NULL # remove task_id if zero
    n <- n + 1
  }
}
if (json_list$message == "") json_list$message <- NULL  # remove message key from top level JSON if still empty

cat(toJSON(json_list, pretty = 4), "\n", file = args[2], sep = "")  # write `results.json`
