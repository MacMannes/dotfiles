#!/bin/bash

# Pretty format an XML file in place
# Usage: ./format-xml.sh <file.xml>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <xml-file>"
    exit 1
fi

XML_FILE="$1"

if [ ! -f "$XML_FILE" ]; then
    echo "Error: File '$XML_FILE' not found"
    exit 1
fi

# Use xmllint to pretty format the XML file
# --format: Format the output with proper indentation
# --output: Write the result back to the same file
xmllint --format "$XML_FILE" --output "$XML_FILE"

if [ $? -eq 0 ]; then
    echo "Successfully formatted: $XML_FILE"
else
    echo "Error: Failed to format XML file"
    exit 1
fi
