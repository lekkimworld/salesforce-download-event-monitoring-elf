# Download Salesforce Event Monitoring ELF's
Scripts for downloading Salesforce Event Monitoring data using `sf` CLI.

## Running
1. Set a default org
	1. Log into a new org and set as default
	```bash
	sf org login web --instance-url="https://mydomain.my.salesforce.com" --set-default
	```
	2. Set default org from existing
	```bash
	sf config set target-org=<org alias or username>
	```
2. Get the types of `Daily` Event Log File types we have
```bash
sf data query -q "SELECT EventType, COUNT(Id) FROM EventLogFile WHERE Interval='Daily' \
	GROUP BY EventType" --json > event_types.json
```
3. Loop event types and get log files per event type
```bash
jq -r '.result.records[].EventType' ./event_types.json | while read -r event; do
    echo "Getting Daily log files for : $event"
    sf data query -q "SELECT LogDate, LogFile FROM EventLogFile WHERE Interval='Daily' \
		AND EventType='$event' AND LogDate >= 2026-02-01T00:00:00.000Z AND \
		LogDate <= 2026-03-31T00:00:00.0000Z" --json > ${event}_logfiles.json
done
```
4. Download log files
	1. For a particular event type
	```bash
	export SF_EVENT_NAME=<event name i.e. UniqueQuery>
	jq -r '.result.records[] | "\(.LogFile)\t\(.LogDate| sub("\\.[0-9]+\\+[0-9]+$"; "Z") | fromdateiso8601 | strftime("%Y-%m-%d") )" ' "./${SF_EVENT_NAME}_logfiles.json" | while IFS=$'\t' read -r logfile strdate; do
		echo "Downloading ${logfile} for ${SF_EVENT_NAME} (${strdate})"
		sf request api rest $logfile --stream-to-file="${SF_EVENT_NAME}_${strdate}.csv"
	done
	```
	2. For all event types
	```bash
	jq -r '.result.records[].EventType' ./event_types.json | while read -r SF_EVENT_NAME; do
		jq -r '.result.records[] | "\(.LogFile)\t\(.LogDate| sub("\\.[0-9]+\\+[0-9]+$"; "Z") | fromdateiso8601 | strftime("%Y-%m-%d") )" ' "./${SF_EVENT_NAME}_logfiles.json" | while IFS=$'\t' read -r logfile strdate; do
			echo "Downloading ${logfile} for ${SF_EVENT_NAME} (${strdate})"
			sf request api rest $logfile --stream-to-file="${SF_EVENT_NAME}_${strdate}.csv"
		done
	done
