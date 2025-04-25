#!/usr/bin/env python3
# Utilized CHATGPT based on my use case 

import sys
import re
from datetime import datetime
from collections import defaultdict

# ✅ Phrases to limit after 5 matches
hidden_phrases = [
    "Canceling the limit order",
    # Add more phrases here if needed
]

def parse_log_timestamp(line):
    match = re.match(r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3}', line)
    if match:
        try:
            return datetime.strptime(match.group(1), "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return None
    return None

def format_gap(delta_seconds):
    minutes, seconds = divmod(int(delta_seconds), 60)
    return f"\n... after {minutes}min {seconds}sec\n" if delta_seconds else ""

def read_logs(filepath, search_term, time_gap_sec=30):
    try:
        with open(filepath, "r") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"❌ File not found: {filepath}")
        sys.exit(1)

    # 🟦 Banner header
    print(f"\n###### Script: read_logs.py v1 - CHATGPT ######\n")
    print(f"- File   : {filepath}")
    print(f"- Keyword: {search_term}\n")

    last_time = None
    phrase_count = defaultdict(int)
    phrase_hidden = defaultdict(bool)
    max_visible = 5
    output = []

    for line in lines:
        if search_term not in line:
            continue

        matched_phrase = next((phrase for phrase in hidden_phrases if phrase in line), None)
        should_print = False

        if matched_phrase:
            phrase_count[matched_phrase] += 1
            if phrase_count[matched_phrase] <= max_visible:
                should_print = True
            elif not phrase_hidden[matched_phrase]:
                phrase_hidden[matched_phrase] = True
        else:
            should_print = True

        if should_print:
            current_time = parse_log_timestamp(line)
            if current_time and last_time:
                delta = (current_time - last_time).total_seconds()
                if delta > time_gap_sec:
                    output.append(format_gap(delta))
            if current_time:
                last_time = current_time
            output.append(line)

    # ⏹️ Print all skipped summary after finishing lines
    for phrase in hidden_phrases:
        total = phrase_count[phrase]
        if total > max_visible:
            output.append(
                f'Skipped more lines containing: "{phrase}" (already shown {max_visible} from {total} occurrences): please check the log file instead\n'
            )

    if output:
        print("".join(output))
    else:
        print(f"🔍 No matches found for '{search_term}'")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: readlogs.py <logfile> <search_term>")
        sys.exit(1)

    logfile = sys.argv[1]
    search_string = sys.argv[2]

    read_logs(logfile, search_string)
