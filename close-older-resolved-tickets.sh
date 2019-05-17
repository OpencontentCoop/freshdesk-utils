#!/usr/bin/env bash

[[ $TRACE == 1 ]] && set -x

# ------------------------------------------------------------
# Copyright 2017 Opencontent scarl.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------


# check parameters
if [[ -z $FRESHDESK_DOMAIN ]]; then
	echo "Error, missing freshdesk domain, please set environment variable FRESHDESK_DOMAIN"
	exit 1
fi

if [[ -z $FRESHDESK_API_KEY ]]; then
	echo "Error, missing freshdesk api key, please set environment variable FRESHDESK_API_KEY"
	exit 1
fi

# get optional settings from environment
maxTicketAge=${TICKET_MAX_AGE:=30}
batchSize=${BATCH_SIZE:=5}
slackChannel=${SLACK_CHANNEL:=freshdesk}

if [[ -n $SLACK_WEBHOOK ]]; then
	echo "webhook_url=$SLACK_WEBHOOK" >> ~/.slacktee
fi

fd::ticket::get_link()
{
	local id=$1
	echo "https://${FRESHDESK_DOMAIN}.freshdesk.com/a/tickets/$id"
}	

page=1
toBeClosed=0

declare -A ticketsMissingType
declare -A ticketsClosed

while true; do
{

	echo "===> Checking tickets page $page "

	api_result=$(http --json --auth $FRESHDESK_API_KEY:x \
		"https://${FRESHDESK_DOMAIN}.freshdesk.com/api/v2/search/tickets?page=$page&query=\"status:4\"" 2>/dev/null)

	if [[ $? -gt 0 ]]; then
		echo "Error in http GET"
		break
	fi

	tickets=$(echo $api_result | jq "[  .results[] | { id: .id, updated_at: .updated_at, created_at: .created_at, subject: .subject, type: .type } ]" 2>/dev/null)
	if [[ $? -gt 0 ]]; then
		echo "Error parsing response"
		break
	fi

	# get the json results as single row and encode in base64
	for row in $(echo $tickets | jq -r '.[] | @base64'); do
		# the following function get the single field from the json row
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		id=$(_jq '.id')
		updated_at=$(_jq '.updated_at')
		created_at=$(_jq '.created_at')
		subject=$(_jq '.subject')
		ticketStatus=$(_jq '.type')

		#echo "- Checking ticket $id"
		time_limit="$maxTicketAge days ago"	# this is a string for the date function
		# convert dates in epoch
		updated_at_epoch=$(date --date "$updated_at" +'%s')
		time_limit_epoch=$(date --date "$time_limit" +'%s')

		if [[ $updated_at_epoch -lt $time_limit_epoch ]]; then

			echo -e "\tTicket $id updated at $updated_at has been updated more than $time_limit: type is '$ticketStatus'"
			toBeClosed=$((toBeClosed + 1))

			if [[ $ticketStatus == "null" ]]; then
				# il ticket sarebbe da chiudere ma non ha impostata la categoria, aspettiamo
				if [[ ${#ticketsMissingType[@]} -lt $batchSize ]]; then
					# non facciamo liste troppo lunghe
					ticketsMissingType+=([$id]=$subject)
				fi
			else
				close_result=$(http --json --auth $FRESHDESK_API_KEY:x \
					PUT https://${FRESHDESK_DOMAIN}.freshdesk.com/api/v2/tickets/$id status:=5)
				if [[ $? -gt 0 ]]; then
					echo "Error closing ticket #${id}"
				else
					echo "Closed ticket #${id}"
					ticketsClosed+=([$id]=$subject)
				fi
			fi

		fi
		if [[ ${#ticketsClosed[@]} -ge $batchSize ]]; then
			echo "Reached max batch size"
			break 2
		fi
	done

	((page++))

}
done

summary="Ciao, sto facendo manutenzione sul nostro FreshDesk\nAlmeno *${toBeClosed}* tickets possono essere chiusi, si trovano in stato _Risolto_ da piu' di $maxTicketAge giorni"
if [[ ${#ticketsClosed[@]} -gt 0 ]]; then
	summary="$summary\n\nHo chiuso i ticket che seguono:"
	for index in "${!ticketsClosed[@]}"; do
		link=$(fd::ticket::get_link $index)
		summary="$summary\n* <$link|#$index> _${ticketsClosed[$index]}_"
	done
else
	summary="$summary\n\nNon riesco a chiudere nessun ticket purtroppo, probabilmente sono tutti senza categoria"
fi

if [[ ${#ticketsMissingType[@]} -gt 0 ]]; then
	summary="$summary\n\nCi sarebbero i seguenti ticket che potrei chiudere ma gli manca una categoria, ci riguardo più tardi:"
	for index in "${!ticketsMissingType[@]}"; do
		link=$(fd::ticket::get_link $index)
		summary="$summary\n* <$link|#$index> _${ticketsMissingType[$index]}_"
	done
fi

if [[ -n $slackChannel ]]; then
	echo -e $summary | slacktee --plain-text --no-output --channel $slackChannel
else
	echo -e $summary
fi

echo "Finished!"


