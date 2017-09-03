package utils

import (
       "os"
       "log"
)

// Basic logger used in the application
var Log = log.New(os.Stdout, "GITHUB-API : ", 0)

