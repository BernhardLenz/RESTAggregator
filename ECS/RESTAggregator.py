import requests
import json
from datetime import datetime

response1 = requests.get('http://api.open-notify.org/iss-now.json')
response2 = requests.get('http://api.open-notify.org/astros.json')

result = {}
result['iss_position'] = response1.json()
result['people_in_space'] = response2.json()
result['time'] = datetime.now().strftime("%H:%M:%S")
print(json.dumps(result))

f = open("Result.json", "a")
f.write(json.dumps(result))
f.close()


