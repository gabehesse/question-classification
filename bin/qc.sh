#!/bin/bash

#Find the script file parent directory (project home)
pushd . > /dev/null
SCRIPT_DIRECTORY="${BASH_SOURCE[0]}"
while([ -h "${SCRIPT_DIRECTORY}" ])
do
  cd "`dirname "${SCRIPT_DIRECTORY}"`"
  SCRIPT_DIRECTORY="$(readlink "`basename "${SCRIPT_DIRECTORY}"`")"
done
cd "`dirname "${SCRIPT_DIRECTORY}"`" > /dev/null
SCRIPT_DIRECTORY="`pwd`"
popd  > /dev/null
APP_HOME="`dirname "${SCRIPT_DIRECTORY}"`"


num_of_arg=$#
stanford_ner_port=9199


if [ ${num_of_arg} -eq 0 ]
then
  echo "At least one argument required. Following are the expected arguments:-"
  echo "1. pre-process (to only split the raw data and their classes in different text file)"
  echo "2. nlp (to complete all the NLP operations)"
else
  if [ ${1} == "nlp" ]
  then
    # remove the previous `stanfordNER.log` as to avoid confusion from previous executions
    if [ -f "${APP_HOME}/stanfordNER.log" ]
    then
      rm ${APP_HOME}/stanfordNER.log
    fi
    # end of if to check and delete `stanfordNER.log` file
    # command to start StanfordNER java process
    nohup java -Djava.ext.dirs=${APP_HOME}/resources/lib \
    -cp ${APP_HOME}/resources/lib/stanford-ner.jar edu.stanford.nlp.ie.NERServer \
    -port ${stanford_ner_port} \
    -loadClassifier ${APP_HOME}/resources/external_classifiers/english.all.3class.distsim.crf.ser.gz > stanfordNER.log &
    # capture the ner process id
    ner_pid=$!
    # start the python process
    python -m qc.nlp "${APP_HOME}"
    # kill the StanfordNER server
    kill -15 "${ner_pid}"
  elif [ ${1} == "train" ]
  then
    if [ ${num_of_arg} -eq 2 ]
    then
      # start the python process
      python -m qc.ml "train" "${2}" "${APP_HOME}"
    else
      echo "Command 'train' expects one argument. Model: The class of model. e.g 'train ml' or 'train lr'"
    fi
  elif [ ${1} == "test" ]
  then
    if [ ${num_of_arg} -eq 2 ]
    then
      # start the python process
      python -m qc.ml "test" "${2}" "${APP_HOME}"
    else
      echo "Command 'test' expects one argument. Model: The class of model. e.g 'test ml' or 'test lr'"
    fi
  else
    echo "Invalid first argument. ${1} as first argument is unexpected."
  fi
fi
