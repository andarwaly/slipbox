#!/usr/bin/env bash
# Exercise the installed layout from an unrelated working directory.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$HERE/../../skills/setup-slipbox/scripts/slipbox" <<'PY'
import hashlib, json, pathlib, shutil, subprocess, sys, tempfile

def fp(path):
    return 'sha256:' + hashlib.sha256(path.read_bytes()).hexdigest()

with tempfile.TemporaryDirectory() as tmp:
    vault = pathlib.Path(tmp) / 'Test Vault'
    internal = vault / '.slipbox'
    (internal / 'bin').mkdir(parents=True)
    cli = internal / 'bin/slipbox'
    shutil.copy2(sys.argv[1], cli)
    def run(*args, ok=True):
        p = subprocess.run([str(cli), *args], cwd=tmp, text=True, capture_output=True)
        assert (p.returncode == 0) == ok, p.stderr
        return json.loads(p.stdout if ok else p.stderr)
    def git(*args):
        return subprocess.check_output(['git', '-C', str(vault), *args], text=True).strip()
    def stage(work, path, text):
        wd = internal / 'work' / work['work_id']
        (wd / 'draft.md').write_text(text)
        (wd / 'mutations.json').write_text(json.dumps([{'kind':'artifact', 'path':path,
            'expected_fingerprint':work['target_starting_fingerprint'], 'replacement_path':'draft.md'}]))
        run('work', 'update', work['work_id'], '--status', 'ready-to-finalize')
    (internal / 'config.json').write_text(json.dumps({'git':{'mode':'auto'}}))
    (vault / '.gitignore').write_text('.slipbox/work/\n')
    (vault / 'Resources').mkdir()
    source = vault / 'Resources/source.md'
    source.write_text('original source\n')
    git('init', '-q'); git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.com')
    git('add', '.'); git('commit', '-qm', 'baseline')

    work = run('work', 'create', '--kind', 'resource', '--activity', 'clip', '--target', 'Resources/Developing Taste.md')
    stage(work, 'Resources/Developing Taste.md', '# Developing Taste\n')
    run('work', 'finalize', work['work_id'])
    assert (vault / 'Resources/Developing Taste.md').is_file(), 'Resource was not published in vault/Resources'
    assert not (internal / 'Resources').exists(), 'Resource incorrectly published inside .slipbox'
    committed = run('work', 'commit', work['work_id'])
    assert committed['git_commit_status'] == 'committed', committed
    assert git('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD') == 'Resources/Developing Taste.md'
    print('PASS: clipping publication and automatic Git commit use vault paths')

    work = run('work', 'create', '--kind', 'literature', '--activity', 'create', '--source', 'Resources/source.md', '--target', 'Literature/note.md')
    assert work['source_starting_fingerprint'] == fp(source)
    assert work['git_baselines']['Resources/source.md']['blob'] == git('rev-parse', 'HEAD:Resources/source.md')
    assert run('work', 'resume', work['work_id'])['resumable']
    other = vault / 'Resources/other.md'; other.write_text('other\n')
    updated = run('work', 'update', work['work_id'], '--source', 'Resources/other.md', '--target', 'Resources/source.md', '--affected-path', 'Resources/other.md')
    assert updated['source_starting_fingerprint'] == fp(other)
    assert updated['target_starting_fingerprint'] == fp(source)
    assert updated['affected_starting_fingerprints']['Resources/other.md'] == fp(other)
    other.write_text('changed\n')
    assert not run('work', 'resume', work['work_id'])['resumable']
    print('PASS: create, update, Git baselines and resume fingerprint vault files')

    collision = run('work', 'create', '--kind', 'resource', '--activity', 'clip', '--target', 'Resources/source.md')
    stage(collision, 'Resources/source.md', 'must not replace\n')
    assert 'collision' in run('work', 'finalize', collision['work_id'], ok=False)['error']
    assert source.read_text() == 'original source\n'
    print('PASS: existing vault Resource remains frozen')

    cache_path = '.slipbox/cache/source-maps/local.json'
    work = run('work', 'create', '--kind', 'reference', '--activity', 'create', '--target', 'References/test.md', '--affected-path', cache_path)
    stage(work, 'References/test.md', '# Test\n')
    wd = internal / 'work' / work['work_id']
    (wd / 'cache.json').write_text('{}\n')
    mutations = json.loads((wd / 'mutations.json').read_text())
    mutations.append({'kind':'artifact', 'path':cache_path, 'expected_fingerprint':None, 'replacement_path':'cache.json'})
    (wd / 'mutations.json').write_text(json.dumps(mutations))
    run('work', 'finalize', work['work_id'])
    assert run('work', 'commit', work['work_id'])['git_commit_status'] == 'committed'
    assert git('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD') == 'References/test.md'
    assert (vault / cache_path).is_file()
    print('PASS: local source-map cache is published internally but excluded from Git')

    (internal / 'config.json').write_text(json.dumps({'git':{'mode':'off'}}))
    work = run('work', 'create', '--kind', 'resource', '--activity', 'clip', '--target', 'Resources/off.md')
    stage(work, 'Resources/off.md', '# No commit\n')
    run('work', 'finalize', work['work_id'])
    head = git('rev-parse', 'HEAD')
    assert run('work', 'commit', work['work_id'], '--yes')['git_commit_status'] == 'off'
    assert git('rev-parse', 'HEAD') == head
    print('PASS: Git-off configuration is still read from .slipbox/config.json')
PY
