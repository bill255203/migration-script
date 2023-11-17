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

# Parse the environment names from the response
environments=($(cat "$DEST_DIR/envs.json" | jq -r '.[]'))

# Loop through each environment and perform GET and POST requests
for environment in "${environments[@]}"; do
  keyvaluemap_names=($(cat "$DEST_DIR/${environment}_keyvaluemaps_details.json" | jq -r '.[]'))

  for keyvaluemap in "${keyvaluemap_names[@]}"; do
    entries=($(cat "$DEST_DIR/${environment}_env_${keyvaluemap}_keyvaluemaps_details.json" | jq -r '.[]'))

    for entrie in "${entries[@]}"; do
        # Create the JSON payload using data from the environment details file
        json_payload=$(cat "$DEST_DIR/${environment}_env_${keyvaluemap}_keyvaluemap_details.json")

        # Make a POST request to create the environment in the destination project
        create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/keyvaluemaps/entries" \
            -H "Authorization: Bearer $DEST_TOKEN" \
            -d "$json_payload" \
            -H "Content-Type: application/json")

        # Save the response for the created environment to a file
        echo "$create_response" > "$DEST_DIR/${environment}_env_${keyvaluemap}_kvm_${entrie}_entrie_response.json"

        echo "Environment $environment created in the destination project."
    done
  done
done

echo "Environment operations completed."
