svc_url=$1
taskId=$2
cmd=$3

triggerurl=$svc_url"/task/trigger"
checkurl=$svc_url"/task/check?taskId=$taskId"

echo "start working ..."
echo "---------------------------------"
echo "taskId:$taskId"
echo "trigger service url: $triggerurl"
echo "check  service url: $checkurl"

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
echo ""

# define a function fpr parsing  json
function getJsonValuesByAwk() {
    awk -v json="$1" -v key="$2" -v defaultValue="$3" 'BEGIN{
        foundKeyCount = 0
        while (length(json) > 0) {
            # pos = index(json, "\""key"\""); ## 这行更快一些，但是如果有value是字符串，且刚好与要查找的key相同，会被误认为是key而导致值获取错误
            pos = match(json, "\""key"\"[ \\t]*?:[ \\t]*");
            if (pos == 0) {if (foundKeyCount == 0) {print defaultValue;} exit 0;}

            ++foundKeyCount;
            start = 0; stop = 0; layer = 0;
            for (i = pos + length(key) + 1; i <= length(json); ++i) {
                lastChar = substr(json, i - 1, 1)
                currChar = substr(json, i, 1)

                if (start <= 0) {
                    if (lastChar == ":") {
                        start = currChar == " " ? i + 1: i;
                        if (currChar == "{" || currChar == "[") {
                            layer = 1;
                        }
                    }
                } else {
                    if (currChar == "{" || currChar == "[") {
                        ++layer;
                    }
                    if (currChar == "}" || currChar == "]") {
                        --layer;
                    }
                    if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
                        stop = currChar == "," ? i : i + 1 + layer;
                        break;
                    }
                }
            }

            if (start <= 0 || stop <= 0 || start > length(json) || stop > length(json) || start >= stop) {
                if (foundKeyCount == 0) {print defaultValue;} exit 0;
            } else {
                print substr(json, start, stop - start);
            }

            json = substr(json, stop + 1, length(json) - stop)
        }
    }'
}

#start to get data
echo "-----start task[$taskId]-------"
triggerdata=$(curl -F "taskId=$taskId" -F "file=@customer_script.zip" $triggerurl --silent)
# echo "get response: "$triggerdata
if ! [[ $triggerdata ]];then
	printf "api address is wrong! Please check api address.\n"
	exit -1
fi
msg=$(getJsonValuesByAwk "$triggerdata" "msg" "NULL")
code=$(getJsonValuesByAwk "$triggerdata" "code" "NULL")
path=$(getJsonValuesByAwk "$triggerdata" "path" "NULL")
# echo "stat code:$code"
printf "$(date):\n$msg \n"
echo ""

if [ $code = "20000" ]; then
	printf "task[%s] fails to start!\n" $taskId
    exit 20000
fi

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
    checkcode=$(getJsonValuesByAwk "$checkdata" "code" "NULL")
    # echo "get stat code:$checkcode"
    msg=$(getJsonValuesByAwk "$checkdata" "msg" "NULL")
    data=$(getJsonValuesByAwk "$checkdata" "data" "NULL")

    if [ $checkcode = "10001" ];then
        echo "task[$taskId] Init!"
    elif [ $checkcode = "10002" ];then 
        echo "task[$taskId] Running!"
    fi    
    printf "$(date):\n$data \n"
    sleep 5s
done

if [ $checkcode = "10000" ];then
    echo -e "\ntask[$taskId] Successed!"
    echo -e "------task[$taskId] finished------"
    exit 0
elif [ $checkcode = "20000" ];then
    echo -e "\ntask[$taskId] Failed!"
    echo -e "------task[$taskId] finished------"
    exit 20000
fi

exit 0