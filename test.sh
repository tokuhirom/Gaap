#!/bin/bash
for x in test_*.rb
do
    ruby $x
    if [ $? -ne 0 ];then
        echo "FAIL!"
        exit 0
    fi
done

