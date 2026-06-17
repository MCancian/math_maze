import socket
import json
import time
import base64

def send_command(s, cmd, params=None):
    if params is None: params = {}
    req = {"command": cmd, "params": params}
    s.sendall((json.dumps(req) + "\n").encode('utf-8'))
    buf = ""
    while True:
        chunk = s.recv(4096).decode('utf-8')
        if not chunk:
            break
        buf += chunk
        if "\n" in buf:
            break
    line = buf.split("\n")[0]
    return json.loads(line)

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", 9090))
    print("Connected to Godot MCP Server!")

    # 1. Take initial screenshot
    res = send_command(s, "screenshot")
    if "data" in res:
        with open("screen1.png", "wb") as f:
            f.write(base64.b64decode(res["data"]))
        print("Saved screen1.png")
    else:
        print("Screenshot failed:", res)

    # 2. Walk backward a bit to see the key? Actually the key is at z=-5, player is at z=0. Forward is -z. So walk forward.
    print("Walking forward for 1.5 seconds...")
    send_command(s, "key_press", {"action": "move_forward", "pressed": True})
    time.sleep(1.5)
    send_command(s, "key_press", {"action": "move_forward", "pressed": False})

    # 3. Interact with the key
    print("Pressing Interact (E)...")
    send_command(s, "key_press", {"action": "interact", "pressed": True})
    time.sleep(0.5)

    # 4. Check UI to see the math problem
    res = send_command(s, "get_ui_elements")
    print("\n--- UI Elements ---")
    for el in res.get("elements", []):
        print(f"{el.get('name')}: {el.get('text', '')}")

    s.close()
except Exception as e:
    print("Error:", e)
