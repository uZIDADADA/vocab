#!/usr/bin/env python3
"""Build a compact, reproducible ECDICT subset without runtime dependencies.

Download ecdict.csv from the pinned upstream commit, then run:
  python3 tool/build_bilingual_dictionary.py /path/to/ecdict.csv
The upstream definitions are retained verbatim (literal \\n becomes a newline).
Only the search index is normalized; it must not be displayed as a definition.
"""

import argparse
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import sqlite3
import tempfile

COMMIT = "bc015ed2e24a7abef49fc6dbbb7fe32c1dadaf8b"
SOURCE_URL = f"https://raw.githubusercontent.com/skywind3000/ECDICT/{COMMIT}/ecdict.csv"
SOURCE_SHA256 = "1a6947e04785db63613a92e14903cdae7954f7e84860b10e68e5c7cbb3f9c3cf"
ASSET_NAME = "ecdict-core-v1.sqlite.gz"
ENGLISH = re.compile(r"[A-Za-z][A-Za-z '\-]*")
HAN = re.compile(r"[\u3400-\u9fff]+")


def build(source: Path, output: Path):
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA256:
        raise ValueError(f"Source checksum mismatch; use {SOURCE_URL}")
    entries = {}
    forms = set()
    for row in csv.DictReader(io.StringIO(data.decode("utf-8-sig"))):
        term = row["word"].strip().lower()
        translation = row["translation"].replace(r"\n", "\n").strip()
        ranks = [int(row[k]) for k in ("bnc", "frq") if row[k].isdigit() and int(row[k]) > 0]
        rank = min(ranks, default=1000000)
        core = rank <= 20000 or row["tag"] or row["oxford"] == "1" or int(row["collins"] or 0) > 0
        if not core or not ENGLISH.fullmatch(term) or not HAN.search(translation):
            continue
        # Case variants share one lookup key; prefer the better-ranked entry.
        if term not in entries or rank < entries[term][1]:
            entries[term] = (translation, rank)
        for exchange in row["exchange"].split("/"):
            kind, _, form = exchange.partition(":")
            form = form.strip().lower()
            if kind in {"p", "d", "i", "3", "r", "t", "s"} and ENGLISH.fullmatch(form) and form != term:
                forms.add((form, term))

    with tempfile.TemporaryDirectory(prefix="vocab-ecdict-build-") as directory:
        db_path = Path(directory) / "dictionary.sqlite"
        db = sqlite3.connect(db_path)
        db.executescript("""
            PRAGMA page_size = 4096;
            CREATE TABLE entry (
                id INTEGER PRIMARY KEY, term TEXT NOT NULL UNIQUE,
                translation TEXT NOT NULL, rank INTEGER NOT NULL
            );
            CREATE TABLE chinese_term (
                text TEXT NOT NULL, term_id INTEGER NOT NULL REFERENCES entry(id),
                PRIMARY KEY(text, term_id)
            ) WITHOUT ROWID;
            CREATE TABLE form (
                text TEXT NOT NULL, term_id INTEGER NOT NULL REFERENCES entry(id),
                PRIMARY KEY(text, term_id)
            ) WITHOUT ROWID;
        """)
        ids = {term: i for i, term in enumerate(sorted(entries), 1)}
        db.executemany("INSERT INTO entry VALUES (?, ?, ?, ?)", [(ids[term], term, *entries[term]) for term in sorted(entries)])
        chinese_terms = set()
        for term, (translation, _) in entries.items():
            # Exclude source/domain labels, e.g. [医], from reverse search.
            searchable = re.sub(r"\[[^\]]*\]", "", translation)
            for phrase in HAN.findall(searchable):
                chinese_terms.add((phrase, ids[term]))
        db.executemany("INSERT INTO chinese_term VALUES (?, ?)", sorted(chinese_terms))
        db.executemany("INSERT INTO form VALUES (?, ?)", sorted((form, ids[term]) for form, term in forms))
        db.commit()
        assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
        assert not db.execute("PRAGMA foreign_key_check").fetchall()
        db.execute("VACUUM")
        db.close()
        uncompressed = db_path.read_bytes()
    compressed = gzip.compress(uncompressed, compresslevel=9, mtime=0)
    if len(compressed) > 3 * 1024 * 1024:
        raise ValueError(f"Bilingual dictionary exceeds the 3 MiB asset budget: {len(compressed)} bytes")
    output.mkdir(parents=True, exist_ok=True)
    (output / ASSET_NAME).write_bytes(compressed)
    manifest = dict(
        source_url=SOURCE_URL, source_sha256=SOURCE_SHA256, source_commit=COMMIT,
        selection="BNC or FRQ rank <= 20000, or upstream exam/oxford/collins tag; English headword and Han definition required",
        normalization="Lowercase lookup keys; retain upstream Chinese definitions; convert literal newline escapes; index Han runs excluding bracketed domain labels",
        entries=len(entries), chinese_index_rows=len(chinese_terms), forms=len(forms),
        compressed_bytes=len(compressed), uncompressed_bytes=len(uncompressed),
        asset_sha256=hashlib.sha256(compressed).hexdigest(),
    )
    (output / "ecdict-core-v1.manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "assets/dictionary")
    args = parser.parse_args()
    build(args.source, args.output)
