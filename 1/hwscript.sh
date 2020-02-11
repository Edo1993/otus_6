#!/usr/bin/env bash

# Лог последнего запуска
latelog=latest.log
# Общий лог, создаётся сложением latest.log
commlog=common.log
# Логи nginx
logpath=access.log

sorter(){
sort \
| uniq -c \
| sort -nr
}

top5(){
head -5
}

top_ip(){
awk '{print $1}' $logpath | sorter | top5
}

top_request(){
cut -d '"' -f3 $logpath | cut -d ' ' -f2 | sorter | top5
}

url_err(){ghjdthbnm 
awk '{print $9}' $logpath | awk -F '.-' '$1 <= 599 && $1 >= 400' | sorter
}

top_domain(){
awk '{print $13}' $logpath | grep http | awk 'BEGIN { FS = "/" } ; { print $3 }' | awk 'BEGIN { FS = "\"" } ; { print $1 }' | sorter | top5
}

date_end_str(){
awk '{print $4}' $logpath | tail -1 | sed 's/\[//g'
}

get_date_end(){
grep timeend $latelog | sed 's/timeend//g'
}

start_str(){
awk '{print $4}' $logpath | grep -nr get_date_end | cut -d : -f 2
}

end_str(){
wc -l $logpath | awk '{print $1}'
}

range(){
sed -n '$start_str,$end_str_file' $logpath
}

main(){
# Номер последней строки
end_str_file=$(end_str)
# Получить дату из последней строки, добавить для записи в лог как time_end
time_end=$(date_end_str)
# Очистить лог
:> $latelog
# Начать обработку
echo "top ip adresses" >> $latelog
echo range | top_ip >> $latelog
echo "top requests" >> $latelog
echo range | top_request >> $latelog
echo "top domains" >> $latelog
echo range | top_domain >> $latelog
echo "all errors" >> $latelog
echo range | url_err >> $latelog
# Добавить последнюю дату в качестве первой для старта в лог
echo "timestart$time_start" >> $latelog
# Добавить конечную дату
echo "timeend $time_end" >> $latelog
# Добавить контрольный END
echo "END" >> $latelog
}

# Проверить наличие предыдущего лога, сформированного после запуска скрипта
if [ -e $latelog ]
then
    # Если последняя строка END
    if [[ $( tail -1 $latelog) == END ]]
    then
    # Сообщение о корректной работе
    echo "it's ok!"
    # Добавить в общий лог
    cat $latelog >> $commlog
	# Проверяем дату в последней строке
        if [[ $( grep timeend $latelog | awk '{print $1}' ) == timeend ]]
        then
        # Добавить последнюю дату в качестве первой для старта в лог
        time_start=$(get_date_end)
        # Получить номер строки для начала обработки
        start_str_file=$(start_str)
	# Запуск main
	main
        else
        # Присвоить начальный номер, с которого ведется обработка лога nginx, строке
	start_str_file=1
	# Запуск main
	main
        fi
    else
    # Сообщение об ошибке
    echo "error"
    fi
else
# Сообщение о создании файла с логом
echo "create new log"
# Создать лог скрипта
touch $latelog
# Присвоить начальный номер, с которого ведется обработка лога nginx, строке
start_str_file=1
# Запуск main
main
fi

# Отправка почты
cat $latelog | mail -s "Last hour loag" rd4th@mail.ru
