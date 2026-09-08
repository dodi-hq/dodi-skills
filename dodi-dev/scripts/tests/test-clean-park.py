#!/usr/bin/env python3
"""Offline clean-park contract tests: real Git, fake Linear at the curl boundary."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('clean_park', SCRIPTS / 'clean-park.py')
PARK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PARK)
FAKE_CURL = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
p = Path(os.environ['PARK_TEST_DB'])
db = json.loads(p.read_text())
payload = json.loads(sys.argv[sys.argv.index('--data') + 1])
q, v = payload['query'], payload['variables']
operation = 'create' if 'commentCreate(' in q else 'update' if 'commentUpdate(' in q else 'read'
db['calls'].append({'operation': operation, 'variables': v})
def save(): p.write_text(json.dumps(db))
if db.pop('transport_fail', False):
    save(); sys.exit(22)
if db.pop('graphql_fail', False):
    save(); print(json.dumps({'errors':[{'message':'fixture failure'}]})); sys.exit(0)
if operation == 'read':
    issue = db['issues'].get(v['id'])
    if not issue:
        issue = next((i for i in db['issues'].values() if i['id'] == v['id']), None)
    if issue:
        rows = issue['comments']
        start = int(v.get('after') or 0)
        size = db.get('page_size', 100)
        part = rows[start:start+size]
        data = {'issue': {'id': issue['id'], 'identifier': issue['identifier'], 'comments': {'nodes': part, 'pageInfo': {'hasNextPage': start + size < len(rows), 'endCursor': str(start + size)}}}}
    else: data = {'issue': None}
else:
    if db.get('fail_operation') == operation:
        db.pop('fail_operation'); save()
        print(json.dumps({'data': {'commentCreate' if operation == 'create' else 'commentUpdate': {'success':False}}})); sys.exit(0)
    db['mutations'].append({'operation':operation, 'variables':v})
    if operation == 'create':
        issue = next(i for i in db['issues'].values() if i['id'] == v['input']['issueId'])
        c = {'id':'brief-' + str(len(db['mutations'])), 'body': v['input']['body'], 'createdAt':'2026-01-01T00:00:00Z'}
        issue['comments'].append(c)
        data = {'commentCreate': {'success': True, 'comment':{'id':c['id']}}}
    else:
        c = next(c for i in db['issues'].values() for c in i['comments'] if c['id'] == v['id'])
        c['body'] = v['input']['body']
        data = {'commentUpdate': {'success':True}}
    if db.get('lose_reply_operation') == operation:
        db.pop('lose_reply_operation'); save(); sys.exit(22)
save()
print(json.dumps({'data':data}))
'''


def ticket_body(session='workflow', state='<open>'):
    return f'# Ticket Claim\n\n- Session run id: `{session}`\n- Exit state: `{state}`\n- Evidence: `<pending>`\n- Exited at: `<pending>`'


def driver_body(session='workflow', state='open', age=0):
    refreshed = PARK.dt.datetime.now(PARK.dt.timezone.utc) - PARK.dt.timedelta(minutes=age)
    return f'# Driver Claim\n\n- Session run id: `{session}`\n- Refreshed at: `{refreshed.isoformat()}`\n- Lease window: `45m`\n- Exit state: `{state}`\n- Released at: `<pending>`'


class CleanParkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clean-park-test-')
        self.root = Path(self.temp.name)
        self.work = self.root / 'work'
        self.remote = self.root / 'remote.git'
        self.home = self.root / 'state'
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        curl = self.bin / 'curl'
        curl.write_text(FAKE_CURL)
        curl.chmod(0o755)
        self.env = dict(os.environ, DODI_CLEAN_PARK_HOME=str(self.home), PARK_TEST_DB=str(self.root / 'db.json'), PATH=str(self.bin) + os.pathsep + os.environ['PATH'], LINEAR_API_KEY='fixture-only')
        self.env.pop('FLORIST_UNIT', None)
        self.env.pop('CLAUDE_CODE_SESSION_ID', None)
        self.git('init', '--bare', str(self.remote), cwd=self.root)
        self.git('init', str(self.work), cwd=self.root)
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.git('checkout', '-b', 'codex/park-fixture')
        (self.work / 'artifact.txt').write_text('saved work\n')
        self.git('add', 'artifact.txt')
        self.git('commit', '-m', 'fixture')
        self.git('remote', 'add', 'origin', str(self.remote))
        self.manifest = self.root / 'manifest.jsonl'
        self.manifest.write_text('')
        self.request = {'session_id':'workflow', 'native_session_id':'native-other', 'worktree':str(self.work), 'branch':'codex/park-fixture', 'remote':'origin', 'manifest':str(self.manifest), 'ticket_id':'DOD-1', 'ticket_claim_id':'ticket-claim', 'seam':'verify-to-pr', 'brief':'Next: open PR. Reason: verification complete. Concerns: none. Interrupted work: none. Review executor and ledger: recorded.'}
        self.db = {'issues': {'DOD-1': {'id':'issue-1','identifier':'DOD-1','comments':[{'id':'ticket-claim','body':ticket_body(),'createdAt':'2026-01-01T00:00:00Z'}]}, 'DOD-EPIC': {'id':'issue-epic','identifier':'DOD-EPIC','comments':[{'id':'driver-claim','body':driver_body(),'createdAt':'2026-01-01T00:00:00Z'}]}}, 'calls':[], 'mutations':[]}
        self.save_db()
        self.refresher = None

    def tearDown(self):
        if self.refresher is not None:
            self.stop_refresher()
        self.temp.cleanup()

    def git(self, *args, cwd=None):
        p = subprocess.run(['git', *args], cwd=cwd or self.work, text=True, capture_output=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        return p.stdout.strip()

    def save_db(self):
        (self.root / 'db.json').write_text(json.dumps(self.db))

    def read_db(self):
        self.db = json.loads((self.root / 'db.json').read_text())
        return self.db

    def invoke(self, *args, ok=True, cwd=None, env=None):
        p = subprocess.run([str(SCRIPTS / 'clean-park.sh'), *map(str,args)], cwd=cwd or self.root, env=env or self.env, text=True, capture_output=True)
        self.assertEqual(p.returncode, 0 if ok else 2, p.stdout + p.stderr)
        return json.loads(p.stdout)

    def arm(self):
        path = self.root / 'request.json'
        path.write_text(json.dumps(self.request))
        self.record = self.invoke('begin', path)['record']
        return self.record

    def driver(self):
        self.refresher = subprocess.Popen([sys.executable, '-c', 'import sys; sys.stdin.read()'], stdin=subprocess.PIPE)
        self.request.update(mode='driver', driver={'epic_id':'DOD-EPIC','claim_id':'driver-claim','refresher_pid':self.refresher.pid,'exit_state':'refresh-park'})

    def stop_refresher(self):
        self.refresher.stdin.close()
        self.assertEqual(self.refresher.wait(timeout=5), 0)
        self.refresher = None

    def claim_text(self, cid):
        db = self.read_db()
        return next(c['body'] for i in db['issues'].values() for c in i['comments'] if c['id'] == cid)

    def hook(self, native='native-other', active=False):
        p = subprocess.run([str(SCRIPTS/'hook-clean-park.sh')], input=json.dumps({'session_id':native,'stop_hook_active':active}), cwd='/', env=self.env, text=True, capture_output=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        return p

    def test_manual_and_completed_recheck_do_not_mutate(self):
        self.arm()
        done = self.invoke('run', self.record)
        self.assertEqual(done['status'], 'completed')
        self.assertEqual(done['sha'], self.git('rev-parse','HEAD'))
        self.assertIn('`RESUMABLE`', self.claim_text('ticket-claim'))
        count = len(self.read_db()['mutations'])
        self.invoke('run', self.record)
        self.assertEqual(len(self.read_db()['mutations']), count)
        self.assertEqual(self.hook().stdout, '')
        self.assertEqual(self.hook(active=True).stdout, '')

    def test_begin_before_final_commit_and_mature_epic_branch(self):
        self.git('checkout','-b','codex/epic')
        self.request['branch'] = 'codex/epic'
        (self.work/'artifact.txt').write_text('intended unfinished work')
        self.arm()
        self.assertNotIn('sha', self.invoke('status',self.record))
        self.invoke('run',self.record,ok=False)
        self.git('add','artifact.txt'); self.git('commit','-m','finish intended artifacts')
        self.assertEqual(self.invoke('run',self.record)['status'],'completed')

    def test_dirty_worktree_blocks_push(self):
        self.arm(); (self.work/'untracked').write_text('dirty')
        result = self.invoke('run',self.record,ok=False)
        self.assertIn('dirty',result['error'])
        self.assertFalse(self.read_db()['mutations'])
        self.assertEqual(self.git('ls-remote',str(self.remote)), '')

    def test_wrong_branch_and_relative_worktree_rejected(self):
        self.request['worktree']='.'
        path=self.root/'request.json'; path.write_text(json.dumps(self.request))
        self.invoke('begin',path,ok=False)
        self.request['worktree']=str(self.work)
        self.request['branch']='codex/wrong'; self.arm()
        self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])

    def test_unreaped_and_foreign_manifest_records(self):
        self.arm()
        for row in ({'worker_id':'w','session_id':'workflow'}, {'worker_id':'w','session_id':'foreign'}):
            self.manifest.write_text(json.dumps(row)+'\n')
            self.invoke('run',self.record,ok=False)
        self.manifest.write_text(json.dumps({'worker':'w','session_id':'workflow'})+'\n'+json.dumps({'worker':'w','reaped':True})+'\n')
        self.assertEqual(self.invoke('run',self.record)['status'],'completed')

    def test_exact_foreign_or_closed_claim_is_never_released(self):
        self.arm()
        self.db['issues']['DOD-1']['comments'][0]['body']=ticket_body('foreign')
        self.save_db(); self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])
        self.db['issues']['DOD-1']['comments'][0]['body']=ticket_body(state='completed')
        self.save_db(); self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])

    def test_newer_equal_or_closed_successor_blocks_all_writes(self):
        self.arm()
        for created, state in [('2026-02-01T00:00:00Z','<open>'), ('2026-01-01T00:00:00Z','<open>'), ('2026-01-01T01:00:00+01:00','<open>'), ('2026-02-01T00:00:00Z','completed')]:
            with self.subTest(created=created, state=state):
                self.db['issues']['DOD-1']['comments'][1:] = [{'id':'successor-claim','body':ticket_body('successor',state),'createdAt':created}]
                self.save_db()
                failure=self.invoke('run',self.record,ok=False)
                self.assertIn('superseded or ambiguous: successor-claim',failure['error'])
                self.assertEqual(self.git('ls-remote',str(self.remote)), '')
                self.assertFalse(self.read_db()['mutations'])
                self.assertEqual(self.claim_text('ticket-claim'),ticket_body())
                self.assertEqual(self.claim_text('successor-claim'),ticket_body('successor',state))

    def test_older_ticket_claims_allow_exact_current_claim_release(self):
        self.db['issues']['DOD-1']['comments'].extend([
            {'id':'stale-claim','body':ticket_body('stale'),'createdAt':'2025-01-01T00:00:00Z'},
            {'id':'historical-claim','body':ticket_body('historical','completed'),'createdAt':'2025-02-01T00:00:00Z'},
        ])
        self.save_db(); self.arm()
        self.assertEqual(self.invoke('run',self.record)['status'],'completed')
        self.assertEqual(self.claim_text('stale-claim'),ticket_body('stale'))
        self.assertEqual(self.claim_text('historical-claim'),ticket_body('historical','completed'))
        updates=[m['variables']['id'] for m in self.read_db()['mutations'] if m['operation']=='update']
        self.assertEqual(updates,['ticket-claim'])

    def assert_ticket_takeover_at(self, boundary, driver=False):
        if driver:
            self.driver()
        self.arm()
        with patch.dict(os.environ,self.env,clear=True):
            path,record=PARK.load_record(self.record)
            park=PARK.Park(path,record)
            actual=park.before_mutation
            attempts=[]
            snapshot={}
            with patch.object(park,'git',wraps=park.git) as git:
                def lose_before_boundary():
                    attempts.append(1)
                    if len(attempts)==boundary:
                        self.read_db()['issues']['DOD-1']['comments'].append({'id':'successor-claim','body':ticket_body('successor'),'createdAt':'2026-02-01T00:00:00Z'})
                        self.save_db()
                        snapshot['mutations']=list(self.db['mutations'])
                        snapshot['pushes']=sum(c.args[0]=='push' for c in git.call_args_list)
                    return actual()
                with patch.object(park,'before_mutation',side_effect=lose_before_boundary):
                    with self.assertRaisesRegex(PARK.ParkError,'superseded or ambiguous'):
                        park.run()
                self.assertEqual(sum(c.args[0]=='push' for c in git.call_args_list),snapshot['pushes'])
        self.assertEqual(self.read_db()['mutations'],snapshot['mutations'])
        self.assertEqual(self.claim_text('ticket-claim'),ticket_body())
        self.assertEqual(self.claim_text('successor-claim'),ticket_body('successor'))

    def test_ticket_takeover_before_push(self):
        self.assert_ticket_takeover_at(1)
        self.assertEqual(self.git('ls-remote',str(self.remote)), '')

    def test_ticket_takeover_before_brief(self):
        self.assert_ticket_takeover_at(2)

    def test_ticket_takeover_before_release(self):
        self.assert_ticket_takeover_at(3)

    def test_driver_ticket_takeover_before_epic_brief(self):
        self.assert_ticket_takeover_at(3,driver=True)

    def test_driver_ticket_takeover_before_release(self):
        self.assert_ticket_takeover_at(4,driver=True)

    def test_transport_graphql_and_mutation_failure_retry(self):
        self.arm()
        for key, value in [('transport_fail',True),('graphql_fail',True),('fail_operation','create'),('fail_operation','update')]:
            self.read_db()[key]=value; self.save_db()
            self.invoke('run',self.record,ok=False)
            self.assertEqual(self.invoke('status',self.record)['status'],'incomplete')
        self.assertEqual(self.invoke('run',self.record)['status'],'completed')
        briefs=[c for c in self.read_db()['issues']['DOD-1']['comments'] if c['body'].startswith('# Continuation Brief')]
        self.assertEqual(len(briefs),1)

    def test_lost_creation_response_reuses_exact_brief(self):
        self.db['lose_reply_operation']='create'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        self.invoke('run',self.record)
        self.assertEqual(sum(m['operation']=='create' for m in self.read_db()['mutations']),1)

    def test_lost_ticket_release_response_reuses_exact_release(self):
        self.db['lose_reply_operation']='update'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        self.read_db()['issues']['DOD-1']['comments'].append({'id':'successor-claim','body':ticket_body('successor'),'createdAt':'2026-02-01T00:00:00Z'})
        self.save_db(); mutations=list(self.db['mutations'])
        self.invoke('run',self.record)
        self.invoke('run',self.record)
        self.assertEqual(self.read_db()['mutations'],mutations)
        self.assertEqual(sum(m['operation']=='update' for m in self.read_db()['mutations']),1)
        self.assertEqual(self.claim_text('successor-claim'),ticket_body('successor'))

    def test_released_ticket_retry_never_repushes_missing_anchor(self):
        self.db['lose_reply_operation']='update'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        mutations=list(self.read_db()['mutations'])
        self.git('--git-dir='+str(self.remote),'update-ref','-d','refs/heads/codex/park-fixture')
        failure=self.invoke('run',self.record,ok=False)
        self.assertIn('remote no longer matches',failure['error'])
        self.assertEqual(self.git('ls-remote',str(self.remote)), '')
        self.assertEqual(self.read_db()['mutations'],mutations)

    def test_released_ticket_retry_never_recreates_missing_brief(self):
        self.db['lose_reply_operation']='update'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        self.read_db()
        self.db['issues']['DOD-1']['comments'][:]=[c for c in self.db['issues']['DOD-1']['comments'] if c['id']=='ticket-claim']
        self.save_db(); mutations=list(self.db['mutations'])
        failure=self.invoke('run',self.record,ok=False)
        self.assertIn('saved continuation brief is missing',failure['error'])
        self.assertEqual(self.read_db()['mutations'],mutations)

    def test_anchor_never_moves_on_retry(self):
        self.db['fail_operation']='create'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        saved=self.invoke('status',self.record)['sha']
        (self.work/'artifact.txt').write_text('newer unrelated work')
        self.git('add','artifact.txt'); self.git('commit','-m','newer')
        failure=self.invoke('run',self.record,ok=False)
        self.assertIn('HEAD changed',failure['error'])
        self.assertEqual(self.invoke('status',self.record)['sha'],saved)

    def test_remote_push_url_is_locked_and_non_fast_forward_refused(self):
        self.db['fail_operation']='create'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        other=self.root/'other.git'; self.git('init','--bare',str(other),cwd=self.root)
        self.git('remote','set-url','origin',str(other))
        self.invoke('run',self.record,ok=False)
        self.assertEqual(self.git('ls-remote',str(other)), '')

    def test_driver_two_stage_shutdown_and_completed_receipt(self):
        self.driver(); self.arm()
        waiting=self.invoke('run',self.record)
        self.assertEqual(waiting['phase'],'awaiting-refresher-stop')
        self.assertIn('`open`',self.claim_text('driver-claim'))
        count=len(self.read_db()['mutations'])
        self.invoke('run',self.record)
        self.invoke('finish',self.record,ok=False)
        self.invoke('finish',self.record,'--refresher-stopped',ok=False)
        self.assertEqual(len(self.read_db()['mutations']),count)
        self.stop_refresher()
        self.assertEqual(self.invoke('finish',self.record,'--refresher-stopped')['status'],'completed')
        self.assertIn('`refresh-park`',self.claim_text('driver-claim'))
        count=len(self.read_db()['mutations']); self.invoke('finish',self.record)
        self.assertEqual(len(self.read_db()['mutations']),count)

    def test_lost_ticket_release_retry_allows_driver_finish_after_ticket_successor(self):
        self.driver()
        self.db['lose_reply_operation']='update'; self.save_db(); self.arm()
        self.invoke('run',self.record,ok=False)
        self.read_db()['issues']['DOD-1']['comments'].append({'id':'successor-claim','body':ticket_body('successor'),'createdAt':'2026-02-01T00:00:00Z'})
        self.save_db(); mutations=list(self.db['mutations'])
        self.assertEqual(self.invoke('run',self.record)['phase'],'awaiting-refresher-stop')
        self.assertEqual(self.read_db()['mutations'],mutations)
        self.stop_refresher()
        self.assertEqual(self.invoke('finish',self.record,'--refresher-stopped')['status'],'completed')
        added=self.read_db()['mutations'][len(mutations):]
        self.assertEqual([(m['operation'],m['variables']['id']) for m in added],[('update','driver-claim')])
        self.assertEqual(self.claim_text('successor-claim'),ticket_body('successor'))

    def test_delayed_refresh_must_settle_before_release(self):
        self.driver(); self.arm(); self.invoke('run',self.record)
        self.invoke('finish',self.record,'--refresher-stopped',ok=False)
        # The refresh still owns its process/request. Its delayed write lands
        # while the claim is open, then caller joins it before finish.
        self.read_db()['issues']['DOD-EPIC']['comments'][0]['body']=driver_body()
        self.save_db(); self.stop_refresher()
        self.invoke('finish',self.record,'--refresher-stopped')
        self.assertIn('`refresh-park`',self.claim_text('driver-claim'))

    def test_driver_fence_stale_foreign_and_oldest_fresh(self):
        self.driver(); self.arm()
        original=self.db['issues']['DOD-EPIC']['comments'][0]
        for body in [driver_body(age=46),driver_body('foreign'),driver_body(state='parked')]:
            original['body']=body; self.save_db(); self.invoke('run',self.record,ok=False)
            self.assertFalse(self.read_db()['mutations'])
            original=self.db['issues']['DOD-EPIC']['comments'][0]
        original['body']=driver_body()
        self.db['issues']['DOD-EPIC']['comments'].append({'id':'older','body':driver_body('older'),'createdAt':'2025-01-01T00:00:00Z'})
        self.save_db(); self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])

    def test_fence_keeps_future_and_short_window_competitors_visible(self):
        self.driver(); self.arm()
        competitor={'id':'older','body':driver_body('older',age=-5),'createdAt':'2025-01-01T00:00:00Z'}
        self.db['issues']['DOD-EPIC']['comments'].append(competitor)
        self.save_db(); self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])
        self.db['issues']['DOD-EPIC']['comments'][-1]['body']=driver_body('older',age=2).replace('`45m`','`1m`')
        self.save_db(); self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])

    def test_driver_fence_checked_at_each_preparation_mutation(self):
        self.driver(); self.arm()
        with patch.dict(os.environ,self.env,clear=True):
            path,record=PARK.load_record(self.record)
            park=PARK.Park(path,record)
            calls=[]
            actual=park.driver_fence
            def fence(*args,**kwargs):
                calls.append('fence'); return actual(*args,**kwargs)
            def update(cid,body):
                self.assertEqual(calls[-1],'fence'); calls.append('update')
                return PARK.Park.update_claim(park,cid,body)
            with patch.object(park,'driver_fence',side_effect=fence), patch.object(park,'update_claim',side_effect=update):
                park.run()
            self.assertEqual(calls.count('fence'),5)  # initial + push + 2 briefs + release

    def assert_fence_loss_at(self, boundary):
        self.driver(); self.arm()
        with patch.dict(os.environ,self.env,clear=True):
            path,record=PARK.load_record(self.record)
            park=PARK.Park(path,record)
            actual=park.before_mutation
            attempts=[]
            def lose_before_boundary():
                attempts.append(1)
                if len(attempts)==boundary:
                    self.read_db()['issues']['DOD-EPIC']['comments'][0]['body']=driver_body(state='taken-over')
                    self.save_db()
                return actual()
            with patch.object(park,'before_mutation',side_effect=lose_before_boundary):
                with self.assertRaisesRegex(PARK.ParkError,'no longer open'):
                    park.run()
        self.assertEqual(len(self.read_db()['mutations']),max(0,boundary-2))
        self.assertIn('`<open>`',self.claim_text('ticket-claim'))

    def test_lost_fence_before_push(self):
        self.assert_fence_loss_at(1)
        self.assertEqual(self.git('ls-remote',str(self.remote)), '')

    def test_lost_fence_before_ticket_brief(self):
        self.assert_fence_loss_at(2)

    def test_lost_fence_before_epic_brief(self):
        self.assert_fence_loss_at(3)

    def test_lost_fence_before_ticket_release(self):
        self.assert_fence_loss_at(4)

    def test_failed_push_and_non_fast_forward_never_release(self):
        self.arm()
        hook=self.remote/'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n'); hook.chmod(0o755)
        self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])
        hook.unlink()
        self.git('push','origin','HEAD:refs/heads/codex/park-fixture')
        writer=self.root/'writer'
        self.git('clone','--branch','codex/park-fixture',str(self.remote),str(writer),cwd=self.root)
        self.git('config','user.name','Fixture',cwd=writer)
        self.git('config','user.email','fixture@example.invalid',cwd=writer)
        (writer/'artifact.txt').write_text('remote successor')
        self.git('add','artifact.txt',cwd=writer); self.git('commit','-m','successor',cwd=writer)
        self.git('push','origin','HEAD:refs/heads/codex/park-fixture',cwd=writer)
        successor=self.git('rev-parse','HEAD',cwd=writer)
        self.invoke('run',self.record,ok=False)
        self.assertIn(successor,self.git('ls-remote',str(self.remote)))
        self.assertFalse(self.read_db()['mutations'])

    def test_dead_refresher_blocks_preparation(self):
        self.driver(); self.arm(); self.stop_refresher()
        self.invoke('run',self.record,ok=False)
        self.assertFalse(self.read_db()['mutations'])
        self.assertEqual(self.git('ls-remote',str(self.remote)), '')

    def test_corrupt_armed_evidence_blocks_repeatedly_without_erasing_it(self):
        self.arm()
        Path(self.record).write_text('broken JSON')
        self.assertEqual(json.loads(self.hook().stdout)['decision'],'block')
        repeated=json.loads(self.hook(active=True).stdout)
        self.assertEqual(repeated['decision'],'block')
        self.assertIn('incomplete',repeated['reason'])
        self.assertEqual(Path(self.record).read_text(),'broken JSON')

    def test_finish_lost_fence_never_releases_successor(self):
        self.driver(); self.arm(); self.invoke('run',self.record); self.stop_refresher()
        self.read_db()['issues']['DOD-EPIC']['comments'][0]['body']=driver_body(state='taken-over')
        self.db['issues']['DOD-EPIC']['comments'].append({'id':'successor-driver','body':driver_body('next'),'createdAt':'2026-01-02T00:00:00Z'})
        self.save_db(); count=len(self.db['mutations'])
        self.invoke('finish',self.record,'--refresher-stopped',ok=False)
        self.assertEqual(len(self.read_db()['mutations']),count)
        self.assertIn('`open`',self.claim_text('successor-driver'))

    def test_lost_driver_release_response_is_read_back_without_releasing_twice(self):
        self.driver(); self.arm(); self.invoke('run',self.record); self.stop_refresher()
        self.read_db()['lose_reply_operation']='update'; self.save_db()
        self.invoke('finish',self.record,'--refresher-stopped',ok=False)
        count=len(self.read_db()['mutations'])
        self.invoke('finish',self.record,'--refresher-stopped')
        self.assertEqual(len(self.read_db()['mutations']),count)

    def test_interrupt_releases_nothing_and_preserves_failure(self):
        self.arm(); (self.work/'dirty').write_text('dirty'); self.invoke('run',self.record,ok=False)
        result=self.invoke('interrupt',self.record,'--reason','cannot finish','--workers-stopped')
        self.assertEqual(result['status'],'interrupted'); self.assertIn('dirty',result['error'])
        self.assertFalse(result['cleanup_complete']); self.assertFalse(self.read_db()['mutations'])
        self.assertEqual(self.hook().stdout,'')
        self.assertEqual(self.hook(active=True).stdout,'')
        self.invoke('run',self.record,ok=False)

    def test_interrupt_requires_workers_and_refresher_quiescence(self):
        self.driver(); self.arm()
        self.invoke('interrupt',self.record,'--reason','blocked',ok=False)
        self.invoke('interrupt',self.record,'--reason','blocked','--workers-stopped','--refresher-stopped',ok=False)
        self.stop_refresher()
        self.invoke('interrupt',self.record,'--reason','blocked','--workers-stopped',ok=False)
        self.invoke('interrupt',self.record,'--reason','blocked','--workers-stopped','--refresher-stopped')
        self.assertFalse(self.read_db()['mutations'])

    def test_hook_unarmed_pending_retry_native_id_and_changed_cwd(self):
        self.assertEqual(self.hook().stdout,'')
        self.arm()
        self.assertEqual(self.hook('workflow').stdout,'')
        self.assertEqual(json.loads(self.hook().stdout)['decision'],'block')
        repeat=json.loads(self.hook(active=True).stdout)
        self.assertEqual(repeat['decision'],'block')
        self.assertIn('explicitly interrupt',repeat['reason'])
        self.assertIn('do not retry Stop',repeat['reason'])
        self.assertEqual(self.invoke('status',self.record)['status'],'pending')

    def test_repeated_stop_with_live_worker_and_refresher_requires_explicit_interrupt(self):
        self.driver(); self.arm()
        self.manifest.write_text(json.dumps({'worker_id':'w','session_id':'workflow'})+'\n')
        for active in (False,True,True):
            self.assertEqual(json.loads(self.hook(active=active).stdout)['decision'],'block')
        self.invoke('interrupt',self.record,'--reason','cannot finish','--workers-stopped','--refresher-stopped',ok=False)
        self.assertEqual(json.loads(self.hook(active=True).stdout)['decision'],'block')
        with self.manifest.open('a') as manifest:
            manifest.write(json.dumps({'worker_id':'w','reaped':True})+'\n')
        self.invoke('interrupt',self.record,'--reason','cannot finish','--workers-stopped','--refresher-stopped',ok=False)
        self.assertEqual(json.loads(self.hook(active=True).stdout)['decision'],'block')
        self.stop_refresher()
        self.assertEqual(json.loads(self.hook(active=True).stdout)['decision'],'block')
        result=self.invoke('interrupt',self.record,'--reason','cannot finish','--workers-stopped','--refresher-stopped')
        self.assertEqual(result['status'],'interrupted')
        self.assertFalse(result['cleanup_complete'])
        self.assertEqual(self.hook(active=True).stdout,'')
        self.assertFalse(self.read_db()['mutations'])

    def test_native_environment_id_is_supported_and_pending_cannot_be_replaced(self):
        self.request.pop('native_session_id'); self.env['CLAUDE_CODE_SESSION_ID']='native-env'
        self.arm(); self.assertEqual(json.loads(self.hook('native-env').stdout)['decision'],'block')
        self.request['session_id']='another-workflow'
        path=self.root/'request.json'; path.write_text(json.dumps(self.request))
        self.invoke('begin',path,ok=False)

    def test_paginated_claim_and_brief_lookup(self):
        self.db['page_size']=1
        self.db['issues']['DOD-1']['comments'].insert(0,{'id':'other','body':'Some old comment','createdAt':'2025-01-01T00:00:00Z'})
        self.save_db(); self.arm(); self.invoke('run',self.record)

    def test_mature_source_branch_pushes_to_epic_checked_out_elsewhere(self):
        epic_worktree = self.work
        original_sha = self.git('rev-parse', 'HEAD')
        self.git('branch', '-m', 'codex/epic')
        self.git('push', 'origin', 'HEAD:refs/heads/codex/epic')
        mature_worktree = self.root / 'mature-worktree'
        self.git('worktree', 'add', '-b', 'codex/mature-DOD-1', str(mature_worktree), 'HEAD')
        self.work = mature_worktree
        (self.work / 'spec.md').write_text('durable mature artifact\n')
        self.git('add', 'spec.md')
        self.git('commit', '-m', 'mature artifact')
        self.request.update(worktree=str(self.work), source_branch='codex/mature-DOD-1', branch='codex/epic', seam='spec-reviewing')
        self.arm()
        result = self.invoke('run', self.record)
        self.assertEqual(result['status'], 'completed')
        self.assertEqual(self.git('rev-parse', 'HEAD', cwd=epic_worktree), original_sha)
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/codex/epic').split()[0], result['sha'])
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/codex/mature-DOD-1'), '')

    def test_wrong_source_branch_blocks_before_mutation(self):
        self.request['source_branch'] = 'codex/different-source'
        self.arm()
        self.invoke('run', self.record, ok=False)
        self.assertFalse(self.read_db()['mutations'])
        self.assertEqual(self.git('ls-remote', 'origin'), '')

    def test_older_legacy_claim_without_session_does_not_block_parking(self):
        self.db['issues']['DOD-1']['comments'].append({'id':'legacy', 'body':'# Ticket Claim\n\n- Exit state: `completed`', 'createdAt':'2025-01-01T00:00:00Z'})
        self.save_db()
        self.arm()
        self.assertEqual(self.invoke('run', self.record)['status'], 'completed')

    def test_newer_legacy_claim_without_session_blocks_before_mutation(self):
        self.db['issues']['DOD-1']['comments'].append({'id':'legacy', 'body':'# Ticket Claim\n\n- Exit state: `completed`', 'createdAt':'2026-02-01T00:00:00Z'})
        self.save_db()
        self.arm()
        self.invoke('run', self.record, ok=False)
        self.assertFalse(self.read_db()['mutations'])
        self.assertEqual(self.git('ls-remote', 'origin'), '')

    def test_florist_is_refused(self):
        self.arm()
        env=dict(self.env,FLORIST_UNIT='unit')
        self.invoke('run',self.record,ok=False,env=env)
        self.assertFalse(self.read_db()['mutations'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
