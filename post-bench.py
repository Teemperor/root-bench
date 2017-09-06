#!/usr/bin/python
import json
import urllib.request
import sys

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

with open('mattermost-hook', 'r') as myfile:
    url=myfile.read().strip()

icon = "https://rigor.com/wp-content/uploads/2016/03/how-fast-is-too-fast.png"
channel = "performance"
userId = "Raphael's benchmark bot"
message = sys.argv[1]
image = sys.argv[2]

sendMessage(icon, channel, userId, image, message, url)
