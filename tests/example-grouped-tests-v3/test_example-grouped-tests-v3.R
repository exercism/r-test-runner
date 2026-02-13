source("./example-grouped-tests-v3.R")

test_that("1. year not divisible by 4: common year", {
  year <- 2015
  expect_equal(leap(year), FALSE)
  year <- 2013
  expect_equal(leap(year), FALSE)
})

test_that("2. year divisible by 4, not divisible by 100: leap year", {
  year <- 2016
  expect_equal(leap(year), TRUE)
  year <- 2020
  expect_equal(leap(year), TRUE)
})
