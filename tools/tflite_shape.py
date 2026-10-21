"""Minimal TFLite flatbuffer reader: subgraph tensor names + shapes.

Avoids needing tensorflow in this env. Verifies the bundled model's
input/output contract against the app's expectations.

Usage: python tools/tflite_shape.py <model.tflite>
"""

import struct
import sys

PATH = sys.argv[1] if len(sys.argv) > 1 else "app/assets/models/baseline.tflite"
data = open(PATH, "rb").read()

assert data[4:8] == b"TFL3", f"not a tflite file: {data[4:8]!r}"

u16 = lambda o: struct.unpack_from("<H", data, o)[0]
u32 = lambda o: struct.unpack_from("<I", data, o)[0]
i32 = lambda o: struct.unpack_from("<i", data, o)[0]


def table_at(off):
    """Return field(fid) -> absolute field slot offset (or None)."""
    vt = off - i32(off)
    vtsize = u16(vt)

    def field(fid):
        vo = 4 + fid * 2
        if vo + 2 > vtsize:
            return None
        rel = u16(vt + vo)
        return None if rel == 0 else off + rel

    return field


def indirect(slot):
    """Follow a uoffset stored at `slot` -> target absolute offset."""
    return slot + u32(slot)


def vec_len(start):
    return u32(start)


def vec_elem(start, i, size):
    return start + 4 + i * size


def read_str(slot):
    start = indirect(slot)
    n = u32(start)
    return data[start + 4 : start + 4 + n].decode("utf-8", "replace")


root = u32(0)
root_fields = table_at(root)

# Model: 0=version 1=operator_codes 2=subgraphs 3=description 4=buffers
#        5=metadata_buffer 6=metadata 7=signature_defs
subgraphs = indirect(root_fields(2))
n_sub = vec_len(subgraphs)
assert n_sub >= 1, f"no subgraphs (got {n_sub})"

sg = indirect(vec_elem(subgraphs, 0, 4))
sg_fields = table_at(sg)

# SubGraph: 0=tensors 1=inputs 2=outputs 3=operators 4=name
tensors = indirect(sg_fields(0))
inputs = indirect(sg_fields(1))
outputs = indirect(sg_fields(2))

n_tensors = vec_len(tensors)


def tensor_info(i):
    t = indirect(vec_elem(tensors, i, 4))
    f = table_at(t)
    shape_off = f(0)
    shape = []
    if shape_off is not None:
        shape_start = indirect(shape_off)
        n = vec_len(shape_start)
        shape = [i32(vec_elem(shape_start, k, 4)) for k in range(n)]
    name_off = f(3)
    name = read_str(name_off) if name_off is not None else f"tensor_{i}"
    type_off = f(1)
    ttype = data[type_off] if type_off is not None else -1
    return name, shape, ttype


def read_indices(vec_start):
    n = vec_len(vec_start)
    return [i32(vec_elem(vec_start, k, 4)) for k in range(n)]


print(f"file    : {PATH}")
print(f"tensors : {n_tensors}")
for label, vec_start in (("INPUT", inputs), ("OUTPUT", outputs)):
    for idx in read_indices(vec_start):
        name, shape, ttype = tensor_info(idx)
        print(f"  {label:<7}: {name}  shape={shape}  type={ttype}")
