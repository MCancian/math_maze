import urllib.request
import json
import os

assets = {
    "wall": "castle_brick_02_white",
    "floor": "cobblestone_floor_05",
    "orb": "container_side"
}

maps = ["Diffuse", "nor_gl", "Rough"]

os.makedirs("textures", exist_ok=True)

for name, asset_id in assets.items():
    print(f"Fetching metadata for {asset_id}...")
    req = urllib.request.Request(f"https://api.polyhaven.com/files/{asset_id}", headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        
        for map_type in maps:
            if map_type in data:
                # Get the 2k jpg URL
                if "2k" in data[map_type] and "jpg" in data[map_type]["2k"]:
                    url = data[map_type]["2k"]["jpg"]["url"]
                    filename = f"textures/{name}_{map_type.lower()}.jpg"
                    print(f"Downloading {url} to {filename}...")
                    urllib.request.urlretrieve(url, filename)
                else:
                    print(f"Could not find 2k jpg for {asset_id} {map_type}")
            else:
                print(f"Could not find {map_type} map for {asset_id}")

print("Done downloading textures.")
