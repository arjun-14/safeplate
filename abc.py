import base64
import requests

# Encode test image
with open("assets/images/7717236.jpg", "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode()
url = "https://8xog6fy6o4.execute-api.us-west-2.amazonaws.com/prod/menu"

resp = requests.post(
    url,
    json={"image_base64": img_b64}
)

print(resp.json())