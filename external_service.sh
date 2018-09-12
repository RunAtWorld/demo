svc_url=$1
taskId=$2
cmd=$3

triggerurl=$svc_url"/task/trigger"
checkurl=$svc_url"/task/check?taskId=$taskId"

echo "trigger_service_url: $triggerurl"
echo "check_service_url: $checkurl"
echo -e "start working ...\ntaskId:$taskId"

#comprise all file to 
# echo "start to comprise files into script.zip ..."
tmpDir=$taskId"tmp"
if [ ! -d ./$tmpDir ]
then
	mkdir $tmpDir
fi

echo $cmd > customer_cmd.txt
mv $(ls | grep -v out_service.sh | grep -v customer_cmd.txt | grep -v $tmpDir) ./$tmpDir/
mv $tmpDir script
zip -q customer_script.zip -r ./

# define a function fpr parsing  json
function getJsonValueByPython() {
    if [[ $(which python) ]]; then
        local key="$1"
        python -c "import json,sys; sys.stdout.write(json.dumps(json.load(sys.stdin).get('$key')));sys.stdout.write('\n');"
        return 0
    else
        return 1
    fi
}

#start to get data
triggerdata=$(curl -F "taskId=$taskId" -F "file=@customer_script.zip" $triggerurl --silent)
# echo "get response: "$triggerdata
if ! [[ $triggerdata ]];then
	printf "api address is wrong! Please check api address.\n"
	exit -1
fi

msg=$(echo "$triggerdata" | getJsonValueByPython "msg")
code=$(echo "$triggerdata" | getJsonValueByPython "code")
printf "$(date): $msg \n"

if [ $code = "20000" ]; then
	printf "task[%s] fails to start!\n" $taskId
    exit 20000
fi

echo -e "-----start task[$taskId]-------\n"
checkcode="00000"
# echo "-----check task stat-------"
cnt=0
until (test $checkcode = "10000" || test $checkcode = "20000")
do
    ((cnt++))
    checkdata=$(curl --get --silent $checkurl)
    # echo "get response: "$checkdata
	if ! [[ $checkdata ]];then
		printf "api address is wrong! Please check api address.\n"	
		exit -1
	fi    
    # echo "$cnt times check state of task[$taskId]: "
    checkcode=$(echo "$checkdata" | getJsonValueByPython "code")
    # echo "get stat code:$checkcode"
    msg=$(echo "$checkdata" | getJsonValueByPython "msg")
    data=$(echo "$checkdata" | getJsonValueByPython "data")

    if [ $checkcode = "10001" ];then
        echo "task[$taskId] Init!"
    elif [ $checkcode = "10002" ];then 
        echo "task[$taskId] Running!"
    fi    
    printf "$(date):\n$data \n" | sed 's/^\"//g' | sed 's/\"$//g'
    sleep 5s
done

echo -e "------task[$taskId] Finished------"
if [ $checkcode = "10000" ];then
    echo -e "\ntask[$taskId] Succeeded!"
    exit 0
elif [ $checkcode = "20000" ];then
    echo -e "\ntask[$taskId] Failed!"
   
    exit 20000
fi

exit 0
