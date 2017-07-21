#!/bin/bash
##
# POC around i18n/Localization in a bash script
# Run with
#  i18n-rand.sh
# Or
#  i18n-rand.sh  -lang it IT

#(1)
export TEXTDOMAIN=rand.sh
I18NLIB=i18n-lib.sh
#(2)
# source in I18N library - shown above
if [[ -f $I18NLIB ]]
then
        . $I18NLIB
else
        echo "ERROR - $I18NLIB NOT FOUND"
        exit 1
fi

## Start of example script 
function random {
        typeset low=$1 high=$2
        echo $(( ($RANDOM % ($high - $low) ) + $low ))
}
#(3)
## ALLOW USER TO SET LANG PREFERENCE
## assume lang and country code follows
if [[ "$1" = "-lang" ]]
then
        export LC_ALL="$2_$3.UTF-8"
fi

#(4) 
# Display initial greeting
i18n_display "Greeting"
# ask for input 
low=$(i18n_prompt "Low Number Prompt" )
high=$(i18n_prompt "High Number Prompt" )
# check for error condition and display error if found 
if [[ $low -ge $high ]]
then
        i18n_error "Input Error"
        exit 1
fi
rand=$(random $low $high )
# Log what was just done 
i18n_fileout "/tmp/POC" "Activity Log" "$low / $high $rand (${LOGNAME} / $(date))"
# Display Results 
i18n_display "Result Title" $rand
exit 0
