function akill() {
    CMDS=$(adb shell ps | grep $1)
    LINES=$(echo ${CMDS} | wc -l)
    if [ $LINES == 1 ]; then
        adb shell kill $(echo ${CMDS} | awk '{print $2}')
    else
        echo "Command to kill was not found or was ambiguous."
        return 1
    fi
}

function aopen() {
    FILE=$(echo $1 | cut -d: -f1)
    LINE=$(echo $1 | cut -d: -f2 -s)

    if [ "z"$LINE != "z" ]; then
        vi +${LINE} ${FILE}
    else
        vi $@
    fi
}
