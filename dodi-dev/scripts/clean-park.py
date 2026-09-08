#!/usr/bin/env python3
"""Durable clean parking. No commits, process termination, or context resets."""
from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


class ParkError(Exception):
    pass


def require(ok, message):
    if not ok:
        raise ParkError(message)


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def state_home():
    path = Path(os.environ.get('DODI_CLEAN_PARK_HOME', str(Path.home() / '.dodi/clean-park')))
    require(path.is_absolute(), 'DODI_CLEAN_PARK_HOME must be absolute')
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    require(not path.is_symlink() and path.stat().st_uid == os.getuid(), 'state directory must belong to this user')
    require(path.stat().st_mode & 0o077 == 0, 'state directory must have mode 0700')
    return path.resolve()


def atomic(path, value):
    fd, name = tempfile.mkstemp(prefix='.park-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(value, out, indent=2)
            out.write('\n')
            out.flush()
            os.fsync(out.fileno())
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(name):
            os.unlink(name)


@contextlib.contextmanager
def locked(path, blocking=True):
    with open(str(path) + '.lock', 'a') as lock:
        os.chmod(lock.name, 0o600)
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
        except BlockingIOError:
            raise ParkError('another clean-park operation is running')
        yield


def field(body, name):
    matches = re.findall(r'^- ' + re.escape(name) + r': `([^`\n]+)`$', body, re.M)
    require(len(matches) == 1, 'claim must contain exactly one ' + name)
    return matches[0]


def replace_field(body, name, value):
    field(body, name)
    return re.sub(r'^- ' + re.escape(name) + r': `[^`\n]+`$', lambda _: f'- {name}: `{value}`', body, flags=re.M)


def alive(pid):
    try:
        os.kill(pid, 0)  # Probe only: never send a termination signal.
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def command(argv, cwd=None):
    result = subprocess.run(argv, cwd=cwd, text=True, capture_output=True)
    require(result.returncode == 0, f'{argv[0]} failed ({result.returncode}): {result.stderr.strip()[:800]}')
    return result.stdout.strip()


def validate_request(raw):
    require(isinstance(raw, dict), 'request must be a JSON object')
    r = dict(raw)
    required = ('session_id', 'worktree', 'branch', 'remote', 'manifest', 'ticket_id', 'ticket_claim_id', 'seam', 'brief')
    allowed = set(required) | {'native_session_id', 'mode', 'driver', 'source_branch'}
    require(not set(r) - allowed, 'unknown request fields: ' + ', '.join(sorted(set(r) - allowed)))
    for key in required:
        require(isinstance(r.get(key), str) and r[key].strip(), f'{key} must be a nonempty string')
    r.setdefault('mode', 'manual')
    require(r['mode'] in ('manual', 'driver'), 'mode must be manual or driver; Florist is not supported')
    for key in ('session_id', 'native_session_id', 'ticket_id', 'ticket_claim_id', 'seam'):
        if key in r:
            require(isinstance(r[key], str) and r[key] and not any(c in r[key] for c in '\n\r`'), key + ' must be a single line without backticks')
    r.setdefault('native_session_id', os.environ.get('CLAUDE_CODE_SESSION_ID', ''))
    for key in ('worktree', 'manifest'):
        require(Path(r[key]).is_absolute(), key + ' must be absolute')
        r[key] = str(Path(r[key]).resolve())
    require(Path(r['worktree']).is_dir(), 'worktree does not exist')
    require(not r['remote'].startswith('-'), 'invalid remote')
    command(['git', 'check-ref-format', 'refs/heads/' + r['branch']])
    r.setdefault('source_branch', r['branch'])
    require(isinstance(r['source_branch'], str) and r['source_branch'], 'source_branch must be a nonempty string')
    command(['git', 'check-ref-format', 'refs/heads/' + r['source_branch']])
    driver = r.get('driver')
    require((r['mode'] == 'driver') == isinstance(driver, dict), 'driver mode requires a driver object; manual mode forbids it')
    if driver:
        require(set(driver) == {'epic_id', 'claim_id', 'refresher_pid', 'exit_state'}, 'driver requires epic_id, claim_id, refresher_pid, exit_state')
        for key in ('epic_id', 'claim_id'):
            require(isinstance(driver[key], str) and driver[key].strip(), 'driver ' + key + ' is required')
        require(type(driver['refresher_pid']) is int and driver['refresher_pid'] > 1, 'refresher_pid must be an integer greater than 1')
        require(driver['exit_state'] in ('parked', 'refresh-park', 'bloat-handoff'), 'invalid driver exit_state')
    return r


def check_workers(r):
    path = Path(r['manifest'])
    require(path.is_file(), 'dispatch manifest is missing (provide an empty file when no workers were dispatched)')
    active = set()
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        item = json.loads(line)
        require(isinstance(item, dict), 'invalid manifest record')
        worker = item.get('worker_id') or item.get('worker')
        require(worker, 'manifest record has no worker id')
        if 'reaped' not in item:
            require(item.get('session_id') == r['session_id'], 'manifest dispatch belongs to a different session')
            require(worker not in active, 'duplicate live worker in manifest')
            active.add(worker)
        else:
            require(item.get('session_id', r['session_id']) == r['session_id'], 'manifest reap belongs to a different session')
            require(item.get('reaped') is True and worker in active, 'invalid or out-of-order reap record')
            active.remove(worker)
    require(not active, 'unreaped workers: ' + ', '.join(sorted(active)))


class Park:
    def __init__(self, path, record):
        self.path, self.record, self.r = path, record, record['request']

    def save(self):
        self.record['updated_at'] = stamp()
        atomic(self.path, self.record)

    def gql(self, query, variables):
        env = dict(os.environ)
        if env.get('LINEAR_DODI_API_KEY'):
            env['LINEAR_API_KEY'] = env['LINEAR_DODI_API_KEY']
        result = subprocess.run(['bash', str(Path(__file__).with_name('linear-api.sh')), query, json.dumps(variables)], env=env, text=True, capture_output=True)
        require(result.returncode == 0, f'Linear request failed (exit {result.returncode}); check API transport and credentials')
        response = json.loads(result.stdout)
        require(not response.get('errors') and isinstance(response.get('data'), dict), 'Linear returned GraphQL errors or missing data')
        return response['data']

    def comments(self, issue_id):
        nodes, cursor, seen, canonical = [], None, set(), None
        while True:
            data = self.gql('query($id: String!, $after: String) { issue(id: $id) { id identifier comments(first: 100, after: $after) { nodes { id body createdAt } pageInfo { hasNextPage endCursor } } } }', {'id': issue_id, 'after': cursor})
            issue = data.get('issue')
            require(isinstance(issue, dict) and issue.get('id'), 'Linear issue not found: ' + issue_id)
            require(issue_id in (issue['id'], issue.get('identifier')), 'Linear returned a different issue')
            require(canonical in (None, issue['id']), 'issue identity changed during pagination')
            canonical = issue['id']
            comments = issue['comments']
            nodes.extend(comments['nodes'])
            page = comments['pageInfo']
            if not page['hasNextPage']:
                return canonical, nodes
            cursor = page['endCursor']
            require(cursor and cursor not in seen, 'invalid comment pagination')
            seen.add(cursor)

    def claim(self, driver=False):
        r = self.r
        issue, cid, species = (r['driver']['epic_id'], r['driver']['claim_id'], '# Driver Claim') if driver else (r['ticket_id'], r['ticket_claim_id'], '# Ticket Claim')
        uuid, nodes = self.comments(issue)
        matches = [n for n in nodes if n['id'] == cid]
        require(len(matches) == 1, 'exact owned claim not found: ' + cid)
        claim = matches[0]
        require(claim['body'].splitlines()[0:1] == [species], 'wrong claim species: ' + cid)
        require(field(claim['body'], 'Session run id') == r['session_id'], 'claim belongs to a different session: ' + cid)
        return claim, nodes

    def driver_fence(self, quiescent=False):
        if self.r['mode'] != 'driver':
            return
        claim, nodes = self.claim(True)
        require(field(claim['body'], 'Exit state') == 'open', 'driver claim is no longer open')
        now = dt.datetime.now(dt.timezone.utc)
        # All candidates use this acquisition's declared staleness threshold,
        # as driver-claim.sh verify does; a competitor cannot shorten its own
        # window and disappear from this fence's selection.
        window = field(claim['body'], 'Lease window')
        require(re.fullmatch(r'[1-9][0-9]*m', window), 'invalid driver lease window')
        fresh = []
        for item in nodes:
            if item['body'].splitlines()[0:1] != ['# Driver Claim']:
                continue
            if field(item['body'], 'Exit state') != 'open':
                continue
            refreshed = dt.datetime.fromisoformat(field(item['body'], 'Refreshed at').replace('Z', '+00:00'))
            require(refreshed.tzinfo is not None, 'driver timestamp needs a timezone')
            if (now - refreshed).total_seconds() < int(window[:-1]) * 60:
                fresh.append(item)
        require(any(n['id'] == claim['id'] for n in fresh), 'driver claim is stale')
        require(min(fresh, key=lambda n: (n['createdAt'], n['id']))['id'] == claim['id'], 'driver lost oldest-fresh ownership')
        require(alive(self.r['driver']['refresher_pid']) != quiescent, 'refresher must be stopped and quiescent' if quiescent else 'refresher is not running')
        return claim

    def ticket_state(self):
        claim, nodes = self.claim()
        state = field(claim['body'], 'Exit state')
        marker = self.marker()
        closed_by_us = state == 'RESUMABLE' and marker in claim['body']
        require(state == '<open>' or closed_by_us, 'ticket claim was closed by another operation')
        if not closed_by_us:
            claimed_at = dt.datetime.fromisoformat(claim['createdAt'].replace('Z', '+00:00'))
            require(claimed_at.tzinfo is not None, 'ticket timestamp needs a timezone')
            for item in nodes:
                if item['body'].splitlines()[0:1] != ['# Ticket Claim'] or item['id'] == claim['id']:
                    continue
                created_at = dt.datetime.fromisoformat(item['createdAt'].replace('Z', '+00:00'))
                require(created_at.tzinfo is not None, 'ticket timestamp needs a timezone')
                if created_at < claimed_at:
                    continue  # Older legacy history need not carry modern fields.
                if field(item['body'], 'Session run id') == self.r['session_id']:
                    continue
                # A later owner supersedes this acquisition even after it exits.
                # Older stale acquisitions are ordinary history, not a veto.
                require(created_at < claimed_at, 'ticket ownership is superseded or ambiguous: ' + item['id'])
        return claim, closed_by_us

    def marker(self):
        return '<!-- dodi-clean-park:' + self.record['park_id'] + ' -->'

    def git(self, *args):
        return command(['git', '-C', self.r['worktree'], *args])

    def checkout(self):
        require(self.git('rev-parse', '--show-toplevel') == self.r['worktree'], 'declared path is not the worktree root')
        require(self.git('symbolic-ref', '--quiet', '--short', 'HEAD') == self.r['source_branch'], 'checked-out branch differs from declared source branch')
        require(not self.git('status', '--porcelain', '--untracked-files=all'), 'worktree is dirty; commit intended artifacts first')
        sha = self.git('rev-parse', 'HEAD')
        require(not self.record.get('sha') or self.record['sha'] == sha, 'HEAD changed after anchor was locked; refusing to move the old anchor')
        return sha

    def remote_sha(self):
        rows = self.git('ls-remote', '--refs', self.record['push_url'], 'refs/heads/' + self.r['branch']).splitlines()
        require(len(rows) <= 1, 'ambiguous remote branch')
        return rows[0].split()[0] if rows else None

    def prepare_anchor(self):
        sha = self.checkout()
        check_workers(self.r)
        self.driver_fence()
        self.ticket_state()
        urls = self.git('remote', 'get-url', '--push', '--all', self.r['remote']).splitlines()
        require(len(urls) == 1 and urls[0] and not urls[0].startswith('-'), 'remote must have one explicit push URL')
        if self.record.get('sha'):
            require(self.record['push_url'] == urls[0], 'remote push URL changed after anchor was locked')
        else:
            self.record.update(sha=sha, push_url=urls[0])
            self.record['brief_body'] = '\n'.join(['# Continuation Brief', '', self.marker(), f'- Session run id: `{self.r["session_id"]}`', f'- Resume commit: `{sha}`', f'- Branch: `{self.r["branch"]}`', f'- Last completed seam: `{self.r["seam"]}`', '', self.r['brief']])
            self.save()

    def before_mutation(self):
        self.checkout()
        check_workers(self.r)
        claim = self.ticket_state()
        require(not claim[1], 'ticket claim is already released; retry read-only completion')
        self.driver_fence()
        return claim

    def post_brief(self, issue_id):
        uuid, nodes = self.comments(issue_id)
        matching = [n for n in nodes if self.marker() in n['body'] and n['body'].startswith('# Continuation Brief\n')]
        require(len(matching) <= 1, 'duplicate continuation briefs need reconciliation')
        if matching:
            require(matching[0]['body'] == self.record['brief_body'], 'continuation brief differs from locked anchor')
            return matching[0]['id']
        self.before_mutation()
        data = self.gql('mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }', {'input': {'issueId': uuid, 'body': self.record['brief_body']}})
        mutation = data.get('commentCreate', {})
        require(mutation.get('success') is True and mutation.get('comment', {}).get('id'), 'Linear did not confirm continuation brief creation')
        cid = mutation['comment']['id']
        _, current = self.comments(issue_id)
        require(any(n['id'] == cid and n['body'] == self.record['brief_body'] for n in current), 'continuation brief readback failed')
        return cid

    def update_claim(self, cid, body):
        data = self.gql('mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }', {'id': cid, 'input': {'body': body}})
        require(data.get('commentUpdate', {}).get('success') is True, 'Linear did not confirm claim update')

    def run(self):
        if self.record['status'] == 'completed':
            return self.verify_completed()
        require(self.record['status'] != 'interrupted', 'interrupted park requires recovery; it cannot report successful cleanup')
        if self.record['phase'] == 'awaiting-refresher-stop':
            self.verify_anchor_and_briefs()
            require(self.ticket_state()[1], 'ticket release no longer holds')
            return
        if self.ticket_state()[1]:
            # A lost release response may leave only the local receipt unfinished.
            # Never recover it by pushing or writing through a released claim.
            self.verify_anchor_and_briefs()
            self.complete_preparation()
            return
        self.prepare_anchor()
        if self.remote_sha() != self.record['sha']:
            self.before_mutation()
            self.git('push', '--', self.record['push_url'], self.record['sha'] + ':refs/heads/' + self.r['branch'])
        require(self.remote_sha() == self.record['sha'], 'remote SHA does not match the locked anchor')
        self.record['phase'] = 'pushed'
        self.save()
        targets = [self.r['ticket_id']]
        if self.r['mode'] == 'driver':
            targets.append(self.r['driver']['epic_id'])
        for target in dict.fromkeys(targets):
            self.record['brief_ids'][target] = self.post_brief(target)
            self.save()
        claim, closed = self.ticket_state()
        if not closed:
            claim, closed = self.before_mutation()
            require(not closed, 'ticket state changed during release; retry readback')
            body = replace_field(claim['body'], 'Exit state', 'RESUMABLE')
            body = replace_field(body, 'Exited at', stamp())
            body = replace_field(body, 'Evidence', 'resume commit ' + self.record['sha'] + '; continuation brief ' + self.record['brief_ids'][self.r['ticket_id']])
            body += '\n\n' + self.marker() + '\nResume commit: `' + self.record['sha'] + '`'
            self.update_claim(claim['id'], body)
        require(self.ticket_state()[1], 'ticket release readback failed')
        self.complete_preparation()

    def complete_preparation(self):
        self.record['ticket_released'] = True
        if self.r['mode'] == 'driver':
            self.record.update(phase='awaiting-refresher-stop', status='pending', error=None)
        else:
            self.verify_completed()
            self.record.update(phase='done', status='completed', error=None)
        self.save()

    def finish(self, confirmed):
        if self.record['status'] == 'completed':
            return self.verify_completed()
        require(self.record['status'] != 'interrupted', 'interrupted park cannot be finished')
        require(self.r['mode'] == 'driver' and self.record['phase'] == 'awaiting-refresher-stop', 'finish requires awaiting-refresher-stop')
        require(confirmed, '--refresher-stopped confirms the process AND every in-flight refresh request are quiescent')
        require(not alive(self.r['driver']['refresher_pid']), 'refresher process is still running')
        check_workers(self.r)
        self.checkout()
        self.verify_anchor_and_briefs()
        require(self.ticket_state()[1], 'ticket claim is not released')
        claim, _ = self.claim(True)
        expected = self.r['driver']['exit_state']
        if field(claim['body'], 'Exit state') == expected and self.marker() in claim['body']:
            pass  # Recovery after successful mutation but lost response/receipt.
        else:
            claim = self.driver_fence(quiescent=True)
            require(field(claim['body'], 'Exit state') == 'open', 'driver changed before release')
            body = replace_field(claim['body'], 'Exit state', expected)
            body = replace_field(body, 'Released at', stamp()) + '\n\n' + self.marker()
            self.update_claim(claim['id'], body)
        claim, _ = self.claim(True)
        require(field(claim['body'], 'Exit state') == expected and self.marker() in claim['body'], 'driver release readback failed')
        self.verify_completed()
        self.record.update(status='completed', phase='done', error=None, refresher_quiescent=True)
        self.save()

    def verify_anchor_and_briefs(self):
        require(self.record.get('sha') and self.remote_sha() == self.record['sha'], 'remote no longer matches the saved anchor')
        targets = [self.r['ticket_id']] + ([self.r['driver']['epic_id']] if self.r['mode'] == 'driver' else [])
        for target in dict.fromkeys(targets):
            _, nodes = self.comments(target)
            require(any(n['id'] == self.record['brief_ids'].get(target) and n['body'] == self.record['brief_body'] for n in nodes), 'saved continuation brief is missing or changed')

    def verify_completed(self):
        self.verify_anchor_and_briefs()
        require(self.ticket_state()[1], 'completed ticket release no longer holds')
        if self.r['mode'] == 'driver':
            claim, _ = self.claim(True)
            require(field(claim['body'], 'Exit state') == self.r['driver']['exit_state'] and self.marker() in claim['body'], 'completed driver release no longer holds')

    def interrupt(self, reason, workers_stopped, refresher_stopped):
        require(self.record['status'] != 'completed', 'completed parks cannot be interrupted')
        require(reason.strip() and workers_stopped, 'interrupt requires a reason and --workers-stopped confirmation')
        check_workers(self.r)
        if self.r['mode'] == 'driver':
            require(refresher_stopped and not alive(self.r['driver']['refresher_pid']), 'interrupt requires a stopped refresher and confirmation all refresh requests are quiescent')
        self.record.update(status='interrupted', interrupted_reason=reason, cleanup_complete=False, workers_stopped=True)
        if self.r['mode'] == 'driver':
            self.record['refresher_quiescent'] = True
        self.save()


def begin(request_path):
    require(not os.environ.get('FLORIST_UNIT'), 'Florist workers must use their kernel-owned exit contract')
    r = validate_request(json.loads(Path(request_path).read_text()))
    home = state_home()
    path = home / ('park-' + digest(r['session_id']) + '.json')
    marker = home / ('native-' + digest(r['native_session_id']) + '.json') if r['native_session_id'] else None
    with locked(home / 'index'), locked(path, blocking=False):
        if path.exists():
            record = json.loads(path.read_text())
            require(record['request'] == r, 'session already has a different immutable park request')
        else:
            record = {'version': 1, 'owner_uid': os.getuid(), 'park_id': digest(r['session_id']), 'request': r, 'status': 'pending', 'phase': 'armed', 'brief_ids': {}, 'created_at': stamp(), 'error': None}
        if marker and marker.exists():
            prior = json.loads(marker.read_text())
            if prior['record'] != str(path):
                previous = json.loads(Path(prior['record']).read_text())
                require(previous['status'] in ('completed', 'interrupted'), 'native session already has a pending park')
        atomic(path, record)
        if marker:
            atomic(marker, {'native_session_id': r['native_session_id'], 'record': str(path)})
    return path, record


def load_record(path):
    home = state_home()
    path = Path(path)
    require(path.is_absolute() and path.parent == home and not path.is_symlink(), 'record must be an absolute owner-local park path')
    record = json.loads(path.read_text())
    require(record.get('owner_uid') == os.getuid(), 'park record belongs to another user')
    require(path.name == 'park-' + digest(record['request']['session_id']) + '.json', 'record does not match workflow session')
    return path, record


def hook_stop(payload):
    event = json.loads(payload)
    native = event.get('session_id') or os.environ.get('CLAUDE_CODE_SESSION_ID')
    if not native:
        return
    marker = state_home() / ('native-' + digest(native) + '.json')
    if not marker.exists():
        return
    try:
        index = json.loads(marker.read_text())
        require(index['native_session_id'] == native, 'native marker identity mismatch')
        path, record = load_record(index['record'])
        require(record['request']['native_session_id'] == native, 'park native identity mismatch')
        if record['status'] in ('completed', 'interrupted'):
            return
        reason = f'Clean park is incomplete ({record["phase"]}). Continue clean-park.sh with record {path}; complete cleanup or explicitly interrupt after settling workers/refresher. Last error: {record.get("error") or "none"}.'
    except (OSError, ValueError, KeyError, ParkError) as exc:
        reason = 'Armed clean-park evidence is unreadable; cleanup remains incomplete: ' + str(exc)
    if event.get('stop_hook_active') is True:
        reason += ' Repeated normal Stop remains blocked. Finish cleanup or explicitly interrupt after workers and refresher are quiescent; do not retry Stop without settling the park.'
    print(json.dumps({'decision': 'block', 'reason': reason}))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest='command', required=True)
    subs.add_parser('begin').add_argument('request')
    for name in ('run', 'finish', 'status', 'interrupt'):
        sub = subs.add_parser(name)
        sub.add_argument('record')
        if name in ('finish', 'interrupt'):
            sub.add_argument('--refresher-stopped', action='store_true')
        if name == 'interrupt':
            sub.add_argument('--reason', required=True)
            sub.add_argument('--workers-stopped', action='store_true')
    subs.add_parser('hook-stop').add_argument('payload')
    args = parser.parse_args(argv)
    park = None
    try:
        if args.command == 'hook-stop':
            hook_stop(args.payload)
            return 0
        require(not os.environ.get('FLORIST_UNIT'), 'Florist workers must use their kernel-owned exit contract')
        if args.command == 'begin':
            path, record = begin(args.request)
        else:
            path, record = load_record(args.record)
            with locked(path, blocking=False):
                path, record = load_record(args.record)
                park = Park(path, record)
                try:
                    if args.command == 'run':
                        park.run()
                    elif args.command == 'finish':
                        park.finish(args.refresher_stopped)
                    elif args.command == 'interrupt':
                        park.interrupt(args.reason, args.workers_stopped, args.refresher_stopped)
                except (ParkError, OSError, ValueError, KeyError, TypeError, AttributeError, IndexError) as exc:
                    if args.command != 'status' and record['status'] != 'completed':
                        record.update(error=str(exc), status='incomplete' if record['status'] != 'interrupted' else 'interrupted')
                        park.save()
                    raise
        print(json.dumps({'record': str(path), **record}))
        return 0
    except (ParkError, OSError, ValueError, KeyError, TypeError, AttributeError, IndexError) as exc:
        print(json.dumps({'status': 'incomplete', 'error': str(exc)}))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
