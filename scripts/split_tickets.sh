#!/bin/bash

input_file="tickets/database_tickets.md"
output_dir="tickets"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Read the header (everything before the first ---)
header=""
reading_header=true
current_section=""
current_ticket=""

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$reading_header" == true ]]; then
        if [[ "$line" == "---" ]]; then
            reading_header=false
            header+=$'\n'"$line"
        else
            header+=$'\n'"$line"
        fi
    else
        if [[ "$line" =~ ^##\ DB-[0-9]{3} ]]; then
            # Extract ticket number
            ticket_number=$(echo "$line" | grep -oP 'DB-\K[0-9]{3}')
            # Save previous section if exists
            if [[ -n "$current_ticket" ]]; then
                echo "$header" > "$output_dir/$current_ticket.md"
                echo "$current_section" >> "$output_dir/$current_ticket.md"
            fi
            current_ticket="DB-$ticket_number"
            current_section="$line"
        elif [[ "$line" == "---" ]]; then
            current_section+=$'\n'"$line"
        else
            current_section+=$'\n'"$line"
        fi
    fi
done < "$input_file"

# Save the last section
if [[ -n "$current_ticket" ]]; then
    echo "$header" > "$output_dir/$current_ticket.md"
    echo "$current_section" >> "$output_dir/$current_ticket.md"
fi