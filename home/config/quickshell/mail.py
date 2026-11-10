"""Mail from Thunderbird's local IMAP cache, as JSON (used by the quickshell menu).

  quickshell-mail                       recent inbox mail (headers only)
  quickshell-mail --body ACCOUNT MSGID  one message: headers, plain-text body, attachment names
  quickshell-mail --sync                run Thunderbird headless until the inboxes stop changing
  --profile DIR                         use this profile instead of the default (build-time check)

Only the tail of each inbox file is read (new mail is appended). Bodies are returned as plain text,
HTML converted, so the menu never loads anything (tracking pixels, remote images) from a mail.
"""
import configparser
import email
import email.policy
import html
import json
import os
import re
import signal
import subprocess
import sys
import time
from email.utils import parsedate_to_datetime
from html.parser import HTMLParser

TAIL = 8 * 1024 * 1024
PER_ACCOUNT = 40


def profile_dir():
    for base in (os.path.expanduser("~/.config/thunderbird"), os.path.expanduser("~/.thunderbird")):
        ini = os.path.join(base, "profiles.ini")
        if not os.path.exists(ini):
            continue
        cp = configparser.ConfigParser()
        cp.read(ini)
        for s in cp.sections():  # the profile this Thunderbird install uses
            if s.startswith("Install") and cp[s].get("Default"):
                return os.path.join(base, cp[s]["Default"])
        profiles = [cp[s] for s in cp.sections() if s.startswith("Profile")]
        p = next((p for p in profiles if p.get("Default") == "1"), profiles[0] if profiles else None)
        if p:
            return os.path.join(base, p["Path"]) if p.get("IsRelative", "1") == "1" else p["Path"]
    return None


def imap_accounts(profile):
    prefs = open(os.path.join(profile, "prefs.js"), encoding="utf-8", errors="replace").read()
    servers = {}
    for server, key, value in re.findall(r'user_pref\("mail\.server\.(server\d+)\.([\w-]+)", "([^"]*)"\);', prefs):
        servers.setdefault(server, {})[key] = value
    for s in servers.values():
        folder = s.get("directory-rel", "").replace("[ProfD]", "")
        if s.get("type") == "imap" and folder:
            yield s.get("name") or s.get("hostname", "?"), os.path.join(profile, folder)


def find_inbox(folder):
    names = os.listdir(folder) if os.path.isdir(folder) else []
    return next((os.path.join(folder, f) for f in names if f.lower() == "inbox"), None)


def tail_messages(inbox):
    """Raw messages from the end of an mbox file, newest last (the mbox "From " line removed)."""
    size = os.path.getsize(inbox)
    with open(inbox, "rb") as f:
        f.seek(max(0, size - TAIL))
        data = f.read()
    parts = re.split(rb"\r?\n(?=From )", data)
    if size > TAIL:
        parts = parts[1:]  # the first piece starts mid-message
    return [p.split(b"\n", 1)[-1] if p.startswith(b"From ") else p for p in parts]


def recent(inbox):
    out, seen = [], set()
    for raw in reversed(tail_messages(inbox)):
        head = re.split(rb"\r?\n\r?\n", raw, maxsplit=1)[0]
        msg = email.message_from_bytes(head, policy=email.policy.default)
        try:
            status = int(msg.get("X-Mozilla-Status", "0") or "0", 16)
        except ValueError:
            status = 0
        mid = str(msg.get("Message-ID", "")).strip().strip("<>")
        if status & 0x0008 or (mid and mid in seen):  # deleted (kept until Thunderbird compacts) / duplicate copy
            continue
        seen.add(mid)
        try:
            sender = msg["From"].addresses[0]
            sender = sender.display_name or sender.addr_spec
        except Exception:
            sender = str(msg.get("From", ""))
        try:
            date = parsedate_to_datetime(str(msg["Date"])).timestamp()
        except Exception:
            date = 0
        out.append({"from": sender, "subject": str(msg.get("Subject", "")) or "(no subject)",
                    "date": date, "unread": not status & 0x0001, "id": mid})
        if len(out) >= PER_ACCOUNT:
            break
    return out


class TextOnly(HTMLParser):
    """HTML mail -> readable text; nothing is fetched, script/style dropped."""
    BLOCK = {"p", "div", "br", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6", "table", "blockquote", "hr"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out, self.skip = [], 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "head"):
            self.skip += 1
        elif tag in self.BLOCK:
            self.out.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style", "head"):
            self.skip = max(0, self.skip - 1)
        elif tag in self.BLOCK:
            self.out.append("\n")

    def handle_data(self, data):
        if not self.skip:
            self.out.append(data)


def html_to_text(markup):
    parser = TextOnly()
    parser.feed(markup)
    text = html.unescape("".join(parser.out)).replace("\xa0", " ")
    text = re.sub(r"[ \t]+\n", "\n", re.sub(r"[ \t]{2,}", " ", text))
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def body(profile, account, mid):
    for name, folder in imap_accounts(profile):
        inbox = find_inbox(folder)
        if name != account or not inbox:
            continue
        for raw in reversed(tail_messages(inbox)):
            msg = email.message_from_bytes(raw, policy=email.policy.default)
            if str(msg.get("Message-ID", "")).strip().strip("<>") != mid:
                continue
            part = msg.get_body(preferencelist=("plain", "html"))
            text = ""
            if part is not None:
                try:
                    text = part.get_content()
                except Exception:
                    text = part.get_payload(decode=True).decode("utf-8", "replace")
                if part.get_content_type() == "text/html":
                    text = html_to_text(text)
            text = re.sub(r"(?m)^>From ", "From ", text)  # mbox escaping
            return {"from": str(msg.get("From", "")), "to": str(msg.get("To", "")), "cc": str(msg.get("Cc", "")),
                    "date": str(msg.get("Date", "")), "subject": str(msg.get("Subject", "")),
                    "body": text[:200000], "attachments": [a.get_filename() for a in msg.iter_attachments() if a.get_filename()]}
    return {"error": "This mail is no longer in Thunderbird's recent cache."}


def thunderbird_running():
    return subprocess.run(["pgrep", "-x", r"thunderbird|\.thunderbird-wr.*"], stdout=subprocess.DEVNULL).returncode == 0


def sync(profile):
    """Headless Thunderbird checks every account at startup. Stop once the inboxes (mail file or its .msf
    summary) changed and then stayed still for a few seconds; 25 s with no change at all, 60 s at most."""
    if thunderbird_running():
        return  # an open Thunderbird syncs by itself
    files = []
    for _, folder in imap_accounts(profile):
        inbox = find_inbox(folder)
        if inbox:
            files += [inbox, inbox + ".msf"]

    def stamp():
        return [os.path.getmtime(f) if os.path.exists(f) else 0 for f in files]

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # stopped early by the menu: still close Thunderbird
    start, last, changed = time.time(), stamp(), None
    tb = subprocess.Popen(["thunderbird", "--headless"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        while tb.poll() is None and time.time() - start < 60:
            time.sleep(1)
            now, current = time.time(), stamp()
            if current != last:
                last, changed = current, now
            if (changed and now - changed > 4) or (not changed and now - start > 25):
                break
    finally:
        tb.terminate()
        try:
            tb.wait(15)
        except subprocess.TimeoutExpired:
            tb.kill()


def main():
    args = sys.argv[1:]
    profile = None
    if "--profile" in args:
        i = args.index("--profile")
        profile = args[i + 1]
        del args[i:i + 2]
    profile = profile or profile_dir()
    if not profile or not os.path.isdir(profile):
        print(json.dumps({"accounts": [], "messages": []}))
        return
    if args[:1] == ["--sync"]:
        sync(profile)
        return
    if args[:1] == ["--body"] and len(args) == 3:
        print(json.dumps(body(profile, args[1], args[2])))
        return
    print(json.dumps(cached_list(profile)))


def cached_list(profile):
    """The inbox list, reused while no inbox changed (size and modified time). The cache lives in
    $XDG_RUNTIME_DIR: in memory, readable only by you, gone at logout."""
    inboxes = [(name, find_inbox(folder)) for name, folder in imap_accounts(profile)]
    inboxes = [(name, inbox) for name, inbox in inboxes if inbox]
    stamp = [[name, inbox, os.path.getsize(inbox), os.path.getmtime(inbox)] for name, inbox in inboxes]
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    cache = os.path.join(runtime, "quickshell-mail.json") if runtime else None
    if cache:
        try:
            with open(cache) as f:
                saved = json.load(f)
            if saved["stamp"] == stamp:
                return saved["result"]
        except (OSError, ValueError, KeyError):
            pass
    result = list_mail(inboxes)
    if cache:
        with os.fdopen(os.open(cache, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
            json.dump({"stamp": stamp, "result": result}, f)
    return result


def list_mail(inboxes):
    result = {"accounts": [], "messages": []}
    for name, inbox in inboxes:
        mails = recent(inbox)
        result["accounts"].append({"name": name, "synced": os.path.getmtime(inbox),
                                   "unread": sum(m["unread"] for m in mails)})
        result["messages"] += [dict(m, account=name) for m in mails]
    result["messages"].sort(key=lambda m: m["date"], reverse=True)
    result["messages"] = result["messages"][:100]
    return result


main()
