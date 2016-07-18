#!/bin/bash

waitforit localhost:3306 -t 5 -- ./init-wordpress.sh