#!/usr/bin/env python3
"""Read this project's BIFF8 food database without a spreadsheet dependency.

This narrow importer reads CFB streams, SST/CONTINUE and LABELSST/NUMBER
records. It rejects other cell value records instead of silently omitting them.
The original XLS is kept unchanged; this is not a general Excel editor.
"""
from __future__ import annotations
import argparse, collections, csv, io, json, struct
from pathlib import Path

U32 = lambda data, offset=0: struct.unpack_from('<I', data, offset)[0]


def workbook_stream(path: Path) -> bytes:
    data = path.read_bytes()
    if data[:8] != bytes.fromhex('d0cf11e0a1b11ae1'):
        raise ValueError('Expected an OLE compound document')
    size = 1 << struct.unpack_from('<H', data, 30)[0]
    def sector(n: int) -> bytes:
        result = data[(n + 1) * size:(n + 2) * size]
        if len(result) != size:
            raise ValueError('Truncated OLE sector')
        return result
    difat = list(struct.unpack_from('<109I', data, 76))
    next_difat = U32(data, 68)
    for _ in range(U32(data, 72)):
        entries = struct.unpack('<%dI' % (size // 4), sector(next_difat))
        difat.extend(entries[:-1]); next_difat = entries[-1]
    fat = []
    for n in [x for x in difat if x < 0xFFFFFFFA][:U32(data, 44)]:
        fat.extend(struct.unpack('<%dI' % (size // 4), sector(n)))
    def chain(n: int) -> bytes:
        out, seen = [], set()
        while n < 0xFFFFFFFA:
            if n in seen or n >= len(fat):
                raise ValueError('Invalid or cyclic OLE stream')
            seen.add(n); out.append(sector(n)); n = fat[n]
        return b''.join(out)
    directory = chain(U32(data, 48))
    for i in range(0, len(directory), 128):
        entry = directory[i:i + 128]
        if len(entry) < 128:
            break
        name_len = struct.unpack_from('<H', entry, 64)[0]
        name = entry[:max(0, name_len - 2)].decode('utf-16le')
        if name in ('Workbook', 'Book'):
            length = struct.unpack_from('<Q', entry, 120)[0]
            if length < U32(data, 56):
                raise ValueError('Mini-stream workbook is not supported')
            return chain(U32(entry, 116))[:length]
    raise ValueError('No Workbook stream')


class Segments:
    def __init__(self, blocks: list[bytes]):
        self.blocks, self.block, self.pos = blocks, 0, 0

    def advance(self) -> None:
        self.block += 1; self.pos = 0
        if self.block >= len(self.blocks):
            raise ValueError('Truncated shared-string table')

    def read(self, n: int) -> bytes:
        out = bytearray()
        while n:
            available = len(self.blocks[self.block]) - self.pos
            if not available:
                self.advance(); continue
            take = min(n, available)
            out.extend(self.blocks[self.block][self.pos:self.pos + take])
            self.pos += take; n -= take
        return bytes(out)

    def chars(self, n: int, wide: bool) -> str:
        parts = []
        while n:
            available = len(self.blocks[self.block]) - self.pos
            if not available:
                self.advance()
                wide = bool(self.read(1)[0] & 1)
                available = len(self.blocks[self.block]) - self.pos
            take = min(n, available // (2 if wide else 1))
            if not take:
                raise ValueError('BIFF string splits a code unit')
            raw = self.read(take * (2 if wide else 1))
            parts.append(raw.decode('utf-16le' if wide else 'latin-1'))
            n -= take
        return ''.join(parts)


def read_cells(path: Path) -> dict[tuple[int, int], str | float]:
    stream = workbook_stream(path)
    records = []
    p = 0
    while p + 4 <= len(stream):
        code, length = struct.unpack_from('<HH', stream, p)
        if p + 4 + length > len(stream):
            raise ValueError('Truncated BIFF record')
        records.append((code, stream[p + 4:p + 4 + length]))
        p += 4 + length
    strings = []
    for i, (code, block) in enumerate(records):
        if code != 0xFC:
            continue
        blocks = [block]
        j = i + 1
        while j < len(records) and records[j][0] == 0x3C:
            blocks.append(records[j][1]); j += 1
        r = Segments(blocks)
        _, unique = struct.unpack('<II', r.read(8))
        for _ in range(unique):
            length, flags = struct.unpack('<HB', r.read(3))
            rich = struct.unpack('<H', r.read(2))[0] if flags & 8 else 0
            ext = U32(r.read(4)) if flags & 4 else 0
            strings.append(r.chars(length, bool(flags & 1)))
            r.read(rich * 4 + ext)
        break
    cells = {}
    for code, b in records:
        if code == 0xFD:
            row, col, _, s = struct.unpack('<HHHI', b)
            cells[row, col] = strings[s]
        elif code == 0x203:
            row, col, _, value = struct.unpack('<HHHd', b)
            cells[row, col] = value
        elif code == 0x27E:  # RK number: integer or truncated IEEE double
            row, col, _, raw = struct.unpack('<HHHI', b)
            if raw & 2:
                value = struct.unpack('<i', struct.pack('<I', raw))[0] >> 2
            else:
                value = struct.unpack('<d', struct.pack('<II', 0, raw & ~3))[0]
            cells[row, col] = value / 100 if raw & 1 else value
        elif code in (0x6, 0x204, 0x205, 0xBD):
            raise ValueError(f'Unsupported value record {code:#x}; extend importer')
    return cells


def recover(path: Path) -> list[dict]:
    cells = read_cells(path)
    headers = [str(cells.get((0, c), '')) for c in range(8)]
    assert headers[:4] == ['Primary Key', 'Menu Item Name', 'Ethnicity', 'Short Description'], headers
    rows = []
    for r in range(1, max(k[0] for k in cells) + 1):
        row = {headers[c]: cells.get((r, c), '') for c in range(8)}
        if str(row['Menu Item Name']).strip():
            row['_sheet_row'] = r + 1
            rows.append(row)
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('xls', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    rows = recover(args.xls)
    args.output.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
    print(f'Recovered {len(rows)} rows')
    print(collections.Counter(str(r['Ethnicity']).strip() for r in rows))
