#!/bin/bash

function random {
        typeset low=$1 high=$2
        echo $(( ($RANDOM % ($high - $low) ) + $low ))
}

# (1)
echo  "Hello, I can generate a random number between 2 numbers that you provide"
#(2)
echo -n "What is your low number? "
read low
#(3) 
echo -n "What is your high number? "
read high

if [[ $low -ge $high ]]
then
        #(4)
        echo "1st number should be lower than the second - leaving early." >&2
        exit 1
fi

rand=$(random $low $high )
#(5)
echo "from/to generated (by/at):  $low / $high $rand (${LOGNAME} / $(date))" >> /tmp/POC
#(6)
echo "Your Random Number Is: $rand "

exit 0
