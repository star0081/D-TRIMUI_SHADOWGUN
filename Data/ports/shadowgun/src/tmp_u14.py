import struct

path = r"D:\SHADOWGUN\Data\ports\shadowgun\gamefiles\android-libs\libunity.so"
with open(path, "rb") as f:
    data = f.read()


def b_target(pc, word):
    top = word >> 24
    if top not in (0xEA, 0xEB, 0x1A, 0x0A, 0xBA, 0xBB):
        return None
    imm24 = word & 0xFFFFFF
    if imm24 & 0x800000:
        imm24 -= 0x1000000
    return (pc + 8 + (imm24 << 2)) & 0xFFFFFFFF


print("=== libunity 0x4c9650 ===")
for addr in range(0x4C9600, 0x4C9720, 4):
    w = struct.unpack_from("<I", data, addr)[0]
    t = b_target(addr, w)
    extra = ""
    if t is not None:
        extra = " -> %08x" % t
    # blx rm
    if (w & 0x0FFFFFF0) == 0x012FFF30:
        extra = " blx r%d" % (w & 15)
    # bx rm
    if (w & 0x0FFFFFF0) == 0x012FFF10:
        extra = " bx r%d" % (w & 15)
    mark = " <== LR" if addr == 0x4C9698 else (" <== LR-4" if addr == 0x4C9694 else "")
    print("%08x  %08x%s%s" % (addr, w, extra, mark))
