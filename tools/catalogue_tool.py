"""Validate catalogue data or package Lua source; never execute a submitted script."""
import argparse
import hashlib
import json
import re
import stat
import sys
import zipfile
from pathlib import Path
from urllib.parse import quote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {".lua", ".json", ".md", ".txt"}
PERMISSIONS = {"ui", "notifications", "storage", "session"}
ID = re.compile(r"[a-z][a-z0-9.-]{2,47}\Z", re.ASCII)


def fail(message):
    raise ValueError(message)


def pairs(items):
    result = {}
    for key, value in items:
        if key in result:
            fail(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path, limit=262144):
    if path.is_symlink() or path.stat().st_size > limit:
        fail(f"Linked or oversized JSON file: {path}")
    raw = path.read_bytes()
    if len(raw) > limit:
        fail(f"Oversized JSON file: {path}")
    return json.loads(raw.decode("utf-8-sig"), object_pairs_hook=pairs,
                      parse_constant=lambda value: fail(f"Invalid number: {value}"))


def text(row, key, maximum, default=None, required=False):
    value = row.get(key, default)
    if not isinstance(value, str) or len(value) > maximum:
        fail(f"Invalid {key}; expected text up to {maximum} characters")
    if any(ord(c) < 32 or 127 <= ord(c) <= 159 or c == "\u202e" for c in value):
        fail(f"Control characters are not allowed in {key}")
    if required and not value.strip():
        fail(f"{key} is required")
    return value


def is_reparse(path):
    info = path.lstat()
    return path.is_symlink() or bool(getattr(info, "st_file_attributes", 0) & 0x400)


def source_files(folder):
    folder = folder.absolute()
    for parent in (folder, *folder.parents):
        if is_reparse(parent):
            fail("Linked script folders are not allowed")
    result, pending, entries = [], [folder], 0
    while pending:
        directory = pending.pop()
        for path in sorted(directory.iterdir()):
            entries += 1
            if entries > 40 or is_reparse(path):
                fail("Script has too many entries or contains a link")
            if path.is_dir():
                pending.append(path)
            elif path.is_file():
                if path.suffix.lower() not in ALLOWED:
                    fail(f"Only Lua source, JSON and documentation are allowed: {path.name}")
                for part in path.relative_to(folder).parts:
                    if (part.endswith((".", " ")) or
                            any(c in part for c in ':*?"<>|\\') or
                            any(ord(c) < 32 for c in part) or
                            re.fullmatch(r"(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?", part, re.I)):
                        fail(f"Unsafe package filename: {part}")
                result.append(path)
    if sum(p.stat().st_size for p in result) > 1048576:
        fail("Expanded script exceeds 1 MB")
    if sum(p.name == "script.json" for p in result) != 1:
        fail("Exactly one script.json is required")
    return result


def validate_script(folder):
    files = source_files(folder)
    manifest = read_json(folder / "script.json", 16384)
    if not isinstance(manifest, dict):
        fail("script.json must be an object")
    script_id = text(manifest, "id", 48, required=True)
    if not ID.fullmatch(script_id):
        fail("Invalid script ID")
    for key in ("name", "author"):
        text(manifest, key, 80, required=True)
    if manifest.get("api") not in ("1.0", "1.1") or manifest.get("game") not in ("Any", "Aniimo", "Loftia"):
        fail("Unsupported API or game")
    permissions = manifest.get("permissions")
    if (not isinstance(permissions, list) or len(permissions) > 4 or
            any(not isinstance(p, str) or p not in PERMISSIONS for p in permissions) or
            len(set(permissions)) != len(permissions)):
        fail("Explicit, unique supported permissions are required")
    for key, maximum, default in (("description", 500, ""), ("category", 40, "Utilities"), ("version", 40, "1.0")):
        text(manifest, key, maximum, default)
    source = (folder / "main.lua").read_bytes()
    if len(source) > 65536 or source.startswith(b"\x1b") or b"\0" in source:
        fail("main.lua must be UTF-8 source, at most 64 KB; bytecode is not allowed")
    source.decode("utf-8-sig")
    locales = folder / "Locales"
    if locales.is_dir():
        paths = list(locales.glob("*.json"))
        if len(paths) > 32:
            fail("Too many script locale files")
        for path in paths:
            rows = read_json(path, 32768)
            if not isinstance(rows, dict) or any(not isinstance(k, str) or len(k) > 240 or not isinstance(v, str) or len(v) > 240 for k, v in rows.items()):
                fail("Invalid script translation map")
    return manifest, files


def valid_download(value):
    try:
        url = urlsplit(value)
        return (url.scheme == "https" and url.hostname == "github.com" and
                url.port in (None, 443) and not url.username and not url.password and
                not url.query and not url.fragment and
                bool(re.fullmatch(r"/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/releases/download/[^/]+/[^/]+\.zip", url.path, re.I)))
    except (TypeError, ValueError):
        return False


def validate_catalogue(path):
    data = read_json(path)
    if not isinstance(data, dict) or type(data.get("schema")) is not int or data["schema"] != 1:
        fail("Unsupported catalogue schema")
    scripts = data.get("scripts")
    if not isinstance(scripts, list) or len(scripts) > 200:
        fail("Catalogue must contain at most 200 scripts")
    seen = set()
    for row in scripts:
        if not isinstance(row, dict):
            fail("Each catalogue entry must be an object")
        script_id = text(row, "id", 48, required=True)
        if not ID.fullmatch(script_id) or script_id in seen:
            fail("Invalid or duplicate script ID")
        seen.add(script_id)
        for key in ("name", "author"):
            text(row, key, 80, required=True)
        if row.get("game") not in ("Any", "Aniimo", "Loftia"):
            fail("Invalid catalogue game")
        for key, maximum, default in (("description", 500, ""), ("category", 40, "Utilities"), ("version", 40, "")):
            text(row, key, maximum, default)
        if not re.fullmatch(r"[a-fA-F0-9]{64}", row.get("sha256", "")) or not valid_download(row.get("download")):
            fail("A GitHub release ZIP URL and exact SHA-256 are required")
    return data


def validate(root):
    catalogue = validate_catalogue(root / "catalogue.json")
    examples = root / "examples"
    total = 0
    if examples.is_dir():
        for folder in sorted(examples.iterdir()):
            if folder.is_dir():
                validate_script(folder)
                total += 1
    return len(catalogue["scripts"]), total


def package(folder, repository, tag, output):
    folder = folder.absolute()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        fail("Use owner/repository")
    if not tag or len(tag) > 100 or "/" in tag or any(ord(c) < 32 for c in tag):
        fail("Use a simple release tag without slashes")
    manifest, files = validate_script(folder)
    output = output.absolute()
    if output == folder.absolute() or folder.absolute() in output.parents:
        fail("The output folder must be outside the script source")
    output.mkdir(parents=True, exist_ok=True)
    archive = output / (manifest["id"] + ".zip")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zip_file:
        for file in files:
            info = zipfile.ZipInfo(file.relative_to(folder).as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            zip_file.writestr(info, file.read_bytes())
    if archive.stat().st_size > 1048576:
        fail("Compressed ZIP exceeds 1 MB")
    entry = {key: manifest[key] for key in ("id", "name", "author", "game")}
    entry.update(description=manifest.get("description", ""), category=manifest.get("category", "Utilities"),
                 version=manifest.get("version", "1.0"),
                 download=f"https://github.com/{repository}/releases/download/{quote(tag, safe='')}/{quote(archive.name, safe='')}",
                 sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
    catalogue = {"schema": 1, "scripts": [entry]}
    preview = output / "catalogue-entry.json"
    preview.write_text(json.dumps(catalogue, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    validate_catalogue(preview)
    return archive, preview


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("validate")
    check.add_argument("--root", type=Path, default=ROOT)
    build = commands.add_parser("package")
    build.add_argument("--script", type=Path, required=True)
    build.add_argument("--repo", required=True)
    build.add_argument("--tag", required=True)
    build.add_argument("--output", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    try:
        if args.command == "validate":
            scripts, examples = validate(args.root)
            print(f"Valid: {scripts} catalogue entries, {examples} source examples. No Lua was executed.")
        else:
            archive, preview = package(args.script, args.repo, args.tag, args.output)
            print(f"ZIP: {archive}\nCatalogue entry: {preview}\nUpload the release ZIP BEFORE adding its entry to the live catalogue.")
    except (ValueError, OSError, UnicodeError, json.JSONDecodeError) as error:
        parser.exit(1, f"Validation failed: {error}\n")


if __name__ == "__main__":
    main()
