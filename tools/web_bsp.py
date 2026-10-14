"""Normalize empty Q3 BSP leaves for the pinned FTE WebAssembly renderer."""
from __future__ import annotations

import struct


def normalize_bsp(payload: bytes) -> tuple[bytes, int]:
    if payload[:4] != b'IBSP' or len(payload) < 8:
        return payload, 0
    if struct.unpack_from('<i', payload, 4)[0] != 46:
        return payload, 0
    header_size = 8 + 17 * 8
    if len(payload) < header_size:
        raise ValueError('Truncated Q3 BSP header')
    offset, length = struct.unpack_from('<ii', payload, 8 + 4 * 8)
    if offset < header_size or length < 0 or length % 48 or offset + length > len(payload):
        raise ValueError('Invalid Q3 BSP leaf lump')
    result = bytearray(payload)
    count = 0
    for pos in range(offset, offset + length, 48):
        cluster, area = struct.unpack_from('<ii', payload, pos)
        if area >= 0:
            continue
        faces = struct.unpack_from('<i', payload, pos + 36)[0]
        if area != -1 or cluster != -1 or faces != 0:
            raise ValueError('Negative Q3 BSP area on a nonempty or invalid leaf')
        struct.pack_into('<i', result, pos + 4, 0)
        count += 1
    return (bytes(result), count) if count else (payload, 0)
