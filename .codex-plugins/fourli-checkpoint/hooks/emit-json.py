#!/usr/bin/env python3
import json
import sys

if len(sys.argv) != 3:
    print("usage: emit-json.py <event-name> <mode>", file=sys.stderr)
    sys.exit(2)

event_name = sys.argv[1]
mode = sys.argv[2]
message = sys.stdin.read()

payload = {"continue": True}

if mode == "additionalContext":
    payload["hookSpecificOutput"] = {
        "hookEventName": event_name,
        "additionalContext": message,
    }
elif mode == "systemMessage":
    payload["systemMessage"] = message
else:
    print("invalid mode: " + mode, file=sys.stderr)
    sys.exit(2)

print(json.dumps(payload, ensure_ascii=False))
