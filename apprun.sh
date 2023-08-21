#!/bin/sh

USAGE="Usage: $0 <start|stop>"
START_MODULES="eureka-server api-gateway config-server greeting-micro-service"
STOP_MODULES="config-server greeting-micro-service api-gateway eureka-server"

start_app() {
   echo "Starting $1 ..."
   cd $1
   mvn spring-boot:start
   cd ..
}

stop_app() {
   echo "Stopping $1 ..."
   cd $1
   mvn spring-boot:stop
   cd ..
}

start_proj() {
   for M in $START_MODULES
   do
      start_app $M
   done
   xdg-open http://localhost:8761/
   xdg-open http://localhost:8080/greeting
}

stop_proj() {
   for M in $STOP_MODULES
   do
      stop_app $M
   done
}

[ $# -eq 0 ] && {
   echo $USAGE
} || {
   case $1 in
      start )
          start_proj ;;
       stop )
          stop_proj ;;
         * ) 
          echo $USAGE ;;
   esac
}
