import os, plistlib, base64, sys

ext_dir = sys.argv[1]
if not os.path.isdir(ext_dir):
    sys.exit(0)

data = {}
for root, dirs, files in os.walk(ext_dir):
    for f in files:
        path = os.path.join(root, f)
        rel = os.path.relpath(path, ext_dir)
        with open(path, "rb") as fh:
            data[rel] = base64.b64encode(fh.read()).decode("ascii")

dst = sys.argv[2]
os.makedirs(os.path.dirname(dst), exist_ok=True)
with open(dst, "wb") as fh:
    plistlib.dump(data, fh)

print("Encoded {} .so files to {}".format(len(data), dst))
