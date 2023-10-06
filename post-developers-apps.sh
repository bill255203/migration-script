#!/bin/bash

# Import the JSON configuration
CONFIG_FILE="config.json"
if [[ -f "$CONFIG_FILE" ]]; then
  source <(jq -r 'to_entries | .[] | "export \(.key)=\(.value)"' "$CONFIG_FILE")
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# Now you can use the parameters in this script
echo "SOURCE_ORG in env.sh: $SOURCE_ORG"
echo "DEST_ORG in env.sh: $DEST_ORG"
echo "DEST_ACCOUNT in env.sh: $DEST_ACCOUNT"
echo "DEST_DIR in env.sh: $DEST_DIR"

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  # Extract the appIds from the JSON response for this email
  appIds=($(jq -r '.app[].appId' "$DEST_DIR/${email}_apps_info.json"))

  # Loop through the appIds and make GET requests for each app
  for appId in "${appIds[@]}"; do
    echo "Retrieving app information for appId: $appId"
    # Create the JSON payload using data from the environment details file
    json_payload=$(cat "$DEST_DIR/${email}_${appId}_info.json")
    # Echo the JSON payload before making the POST request
    echo "JSON Payload:"
    echo "$json_payload"
    # Make the API call to get detailed information for the app and save it to a file
    post_dev_app_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers/$email/apps"  \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      -H "Content-Type: application/json")
    # Save the response for the app details to a file
    echo "$post_dev_app_response" > "$DEST_DIR/${email}_${appId}_app_details_response.json"

    echo "App details saved to $DEST_DIR/${email}_${appId}_app_details.json"
  done
done

