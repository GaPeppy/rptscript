#!/bin/bash

API_KEY=$NEW_RELIC_USER_API_KEY
target_url='https://api.newrelic.com/graphql'
DONE=0
CNTR=0
NEXT_CURSOR=''
initquery="'"'{"query":"{\n  actor {\n    entitySearch(queryBuilder: {type: APPLICATION, domain: APM}) {\n      results {\n        entities {\n          tags {\n            key\n            values\n          }\n          name\n          accountId\n        }\n        nextCursor\n      }\n    }\n  }\n}\n", "variables":""}'"'"
jqasv="jq -r '.data.actor.entitySearch.results.entities[] | .tags[].key |= ascii_downcase | .asv = first((.tags[] | select(.key == \"asv\").values[0]),\"BLANK\")|[.accountId,.name,.asv] | @csv'"
reportfile="results$(date '+%Y%m%d').csv"

#init output reportfile with header row
printf "\"NrAccountId\",\"AppName\",\"ASV\"\n" > $reportfile

while [[ $DONE -ne 1 ]]; do
  CNTR=$(($CNTR + 1))
  printf "\n~~~~~~~~\nworking on pass [$CNTR]\n~~~~~~~~"
  if [[ "$NEXT_CURSOR" == "" ]]; then
    #First Pass
    cmd="curl $target_url -s -S -H 'Content-Type: application/json' -H \"Api-Key: $API_KEY\" --data-binary ${initquery} -o ./temp.json"
    printf "\n=========================\n==>$cmd"
    eval $cmd
    cmd="$jqasv ./temp.json >> $reportfile"
    printf "\n=========================\n==>$cmd"
    eval $cmd
  else
    #all subsequent Passes
    nextquery="'"'{"query":"{\n  actor {\n    entitySearch(queryBuilder: {type: APPLICATION, domain: APM}) {\n      results(cursor: \"'$NEXT_CURSOR'\")\n {\n        entities {\n          tags {\n            key\n            values\n          }\n          name\n          accountId\n        }\n        nextCursor\n      }\n    }\n  }\n}\n", "variables":""}'"'"
    cmd="curl $target_url -s -S -H 'Content-Type: application/json' -H \"Api-Key: $API_KEY\" --data-binary ${nextquery} -o ./temp.json"
    printf "\n=========================\n==>$cmd"
    eval $cmd
    cmd="$jqasv ./temp.json >> $reportfile"
    printf "\n=========================\n==>$cmd"
    eval $cmd
  fi


  NEXT_CURSOR=$(jq --raw-output '.data.actor.entitySearch.results.nextCursor' ./temp.json)
  #debug line
  #cat ./temp.json | jq

  if [[ "$NEXT_CURSOR" == "null" ]]; then
    DONE=1
  fi
done
