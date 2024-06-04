#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "please enter db password "
read mysql_root_password

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs"

id expense  &>>$LOGFILE
if [$? -ne 0]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "CREATING EXPENSE USER"
else
    echo -e "expense user already created...$Y skipping $N"
    fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "creating app directory"   

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
zip
VALIDATE $? 

cd /app
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "extracted backend code"

npm install &>>$LOGFILE
VALIDATE $? "installing nodejs dependencies"

 cp /home/ec2-user/shell-expense/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "copied backend service "

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? " daemon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "starting backend "

systemctl enable backend &>>$LOGFILE
VALIDATE $? "enabling backend"
 
 dnf install mysql -y  &>>$LOGFILE
validate $? "installing mysql client"

mysql -h <> -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "schema loading" 

systemctl restart backend &>>$LOGFILE
VALIDATE $? "restarting backend "
