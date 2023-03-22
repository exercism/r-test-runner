library(tidyverse)
library(dplyr)

leap <- function(year) {
  dplyr::select(mtcars, cyl)
  year %% 400 == 0 || (year %% 100 != 0 & year %% 4 == 0)
}
