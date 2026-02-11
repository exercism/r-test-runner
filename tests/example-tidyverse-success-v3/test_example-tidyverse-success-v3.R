source("./example-tidyverse-success-v3.R")

test_that("1. year not divisible by 4: common year", {
  year <- 2015
  expect_equal(leap(year), FALSE)
})

test_that("2. year divisible by 4, not divisible by 100: leap year", {
  year <- 2016
  expect_equal(leap(year), TRUE)
})

test_that("3. year divisible by 100, not divisible by 400: common year", {
  year <- 2100
  expect_equal(leap(year), FALSE)
})

test_that("4. year divisible by 400: leap year", {
  year <- 2000
  expect_equal(leap(year), TRUE)
})