# Wrapper: load vectra + taxify then run ASAAS validation
setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()
source("tests/e2e/test-asaas-validation.R")
