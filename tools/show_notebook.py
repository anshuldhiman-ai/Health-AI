import json
import sys

sys.stdout.reconfigure(encoding="utf-8")
path = sys.argv[1] if len(sys.argv) > 1 else "ml/notebooks/train_on_colab_2.ipynb"
with open(path, encoding="utf-8") as handle:
    nb = json.load(handle)
print(f"{path}: {len(nb['cells'])} cells")
for i, c in enumerate(nb["cells"]):
    src = "".join(c["source"])
    first = src.strip().split("\n")[0][:72] if src.strip() else "(empty)"
    print(f"  {i:>2} {c['cell_type']:<8} {first}")
