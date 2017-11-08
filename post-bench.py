#!/usr/bin/python
import json
import urllib.request
import sys

with open('bench-config.json') as data_file:
    config = json.load(data_file)

def sendMessage(icon, channel, userId, image, message, url):
    color = ""
    payload = {"icon_url": icon,
           "channel": channel,
           "username": userId,
           "attachments": [{
               "color": color,
               "mrkdwn_in": ["pretext", "text", "fields"],
               "fields": [{
                   "short": False,
                   "value": message
               }],
           "image_url" : image,
           "fallback": message
    }]}

    encodedPayload = json.dumps(payload).encode('utf8')

    req = urllib.request.Request(url, data = encodedPayload, headers = {'Content-Type': 'application/json'})
    response = urllib.request.urlopen(req)
    responseContent = response.read()
    print("Mattermost responded with status code {}: {}".format(response.getcode(), responseContent))

if not "mattermost-hook" in config:
  print("No hook supplied, assuming silent mode")
  exit(0)
url = config["mattermost-hook"]
icon = config["bot-avatar"]
channel = config["mattermost-channel"]
userId = config["bot-name"]
message = sys.argv[1]
image = sys.argv[2]

sendMessage(icon, channel, userId, image, message, url)
