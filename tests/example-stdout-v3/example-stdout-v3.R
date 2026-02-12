leap <- function(year) {
  print(paste0("Hello, World in ", year, "!"))
  year %% 400 == 0 || (year %% 100 != 0 & year %% 4 == 0)
}
