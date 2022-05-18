#!/bin/bash

(($# != 2)) && echo Missing arguments!
(($# > 2)) && echo Too many arguments!
(($# == 2)) && mkdir -p output && mix run -e "DedupCSV.run(\"${1}\", ${2})"
