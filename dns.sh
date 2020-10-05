#!/bin/bash
#####
#Change DNS Settings in cloudflare for "nex.zone" like dyndns
#####

sleep 5

cd /opt/app/DynDNS/

source ./dns.conf

#Dynamic IP Change

if [ $cip = $(cat $dns_ip_file) ]; then
  echo "No IP changes found"
else
  echo -e "IP Changed! $(cat $dns_ip_file) -> $cip" | tee $dns_log
  curl --silent -X GET "${api_host_dns}?type=A&content=$(cat $dns_ip_file)" -H "$ca_mail" -H "$ca_key1" -H "$ca_ct" > $dns_file
  for api_id in $(cat $dns_file | jq '.result | .[].id' | sed 's/\"//g'); do
    api_name="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.name" | sed 's/\"//g' )"
    api_proxy="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.proxied" | sed 's/\"//g' )"
    api_ttl="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.ttl" | sed 's/\"//g' )"
    curl --silent -X PUT "${api_host_dns}/${api_id}" -H "$ca_mail" -H "$ca_key1" -H "$ca_ct" \
      --data "{\"type\":\"A\",\"name\":\"${api_name}\",\"content\":\"${cip}\",\"ttl\":${api_ttl},\"proxied\":${api_proxy}}" | tee $dns_log | jq
  done
  echo "Update $dns_ip_file"
  echo "$cip" > $dns_ip_file
fi

#Set Dummy IP to Current IP
curl --silent -X GET "${api_host_dns}?type=A&content=1.1.1.1" -H "$ca_mail" -H "$ca_key1" -H "$ca_ct" > $dns_file

if [ $(grep "zone_id" $dns_file | wc -l) -ge 1 ]; then
  echo "Found dummy entrie(s)!"
  for api_id in $(cat $dns_file | jq '.result | .[].id' | sed 's/\"//g'); do
    api_name="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.name" | sed 's/\"//g' )"
    api_proxy="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.proxied" | sed 's/\"//g' )"
    api_ttl="$(cat $dns_file| jq ".result |.[]|select(.id==\"$api_id\")|.ttl" | sed 's/\"//g' )"
    curl --silent -X PUT "${api_host_dns}/${api_id}" -H "$ca_mail" -H "$ca_key1" -H "$ca_ct" \
      --data "{\"type\":\"A\",\"name\":\"${api_name}\",\"content\":\"${cip}\",\"ttl\":${api_ttl},\"proxied\":${api_proxy}}" | tee $dns_log | jq
 done
else
  echo "No dummy record found!"
fi

rm $dns_file
