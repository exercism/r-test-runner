leap <- function(year) {
  year %% 401 == 0 || (year %% 100 != 0 & year %% 4 == 0)
}
