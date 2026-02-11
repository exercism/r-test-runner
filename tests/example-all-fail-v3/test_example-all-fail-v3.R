source("./example-all-fail-v3.R")
library(testthat)

test_that("1. year not divisible by 4: common year", {
  year <- 2015
  expect_equal(leap(year), FALSE)
})

test_that("2. year divisible by 4, not divisible by 100: leap year", {
  year <- 2016
  expect_equal(leap(year), TRUE)
})
