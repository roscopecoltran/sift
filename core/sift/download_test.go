package utils

import (
    "testing"
    "os"
    "io/ioutil"
)

func TestDownload(t *testing.T) {
    file, err := ioutil.TempFile(os.TempDir(), "testDownloadNut")
    defer os.Remove(file.Name())

    err = Wget("https://raw.githubusercontent.com/matthieudelaro/nutfile_go1.5/master/nut.yml", file.Name())
    if err != nil {
        t.Error(
            err,
        )
    }
}
