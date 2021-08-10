
ngquery='{\n  actor {\n    cloud {\n      linkedAccounts(provider: \"aws\") {\n        authLabel\n        disabled\n id\n        name\n        nrAccountId\n        integrations {\n          id\n          name\n          service {\n            id\n            isEnabled\n            name\n            slug\n          }\n        }\n        disabled\n        externalId\n      }\n    }\n  }\n}\n'
jqservices='.data.actor.cloud.linkedAccounts[] | select(.disabled == false) | . += {"ServiceList": [.integrations[] | select(.service.isEnabled == true) | .name] | join(";")} | . += {"ServiceCount": [.integrations[] | select(.service.isEnabled == true)] | length} | ["authLabel", "disabled", "externalId", "id", "name", "nrAccountId", "ServiceList", "ServiceCount"],[.authLabel, .disabled, .externalId, .id, .name, .nrAccountId, .ServiceList, .ServiceCount] | @csv'

cmd="curl https://api.newrelic.com/graphql -H 'Content-Type: application/json' -H 'API-Key: ${NEW_RELIC_USER_API_KEY}' --data-binary '{\"query\":\"${ngquery}\", \"variables\":\"\"}' -o ./temp.json"

echo $cmd
eval $cmd

cmd="jq  -r '${jqservices}' ./temp.json"
echo $cmd
eval $cmd
