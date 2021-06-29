#!/bin/bash

R -e "shiny::runApp('Dig',display.mode='normal', quiet=TRUE, launch.browser=FALSE, host='0.0.0.0', port=80)"

# while true
# do
#     echo Yawn
#     sleep 10
# done