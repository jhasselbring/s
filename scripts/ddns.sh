#!/bin/bash

#Variable Declaration - Change These
HOSTED_ZONE_ID="Z0355347H9AKH679DQ1O"
NAME="gate.toolbox.plus."
TYPE="A"
TTL=1

# get stored IP
STORED_IP=$(cat STORED_IP)

#get current IP address
NEW_IP=$(curl http://checkip.amazonaws.com/)

#validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
if [[ ! $NEW_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Error retrieving new IP"
    exit 1
fi

#get current
echo "$STORED_IP"
echo "$NEW_IP"
if [[ "$NEW_IP" == "$STORED_IP" ]]
then
    echo "IP is still $STORED_IP"
 
else
    echo "IP Changed to $NEW_IP, Updating Records"
    echo $NEW_IP >| /opt/ddns/STORED_IP
    #prepare route 53 payload
cat >/tmp/route53_changes.json <<EOF
    {
      "Comment":"Updated From DDNS Shell Script",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$NEW_IP"
              }
            ],
            "Name":"$NAME",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF

#update records
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/route53_changes.json >>/dev/null

