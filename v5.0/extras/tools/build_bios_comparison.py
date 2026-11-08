"""Build a DOS 6 BIOS comparison from source in a disposable stage."""
from pathlib import Path
from target_files import read_target
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--candidate',action='store_true')
parser.add_argument('--oembase',action='store_true')
parser.add_argument('--singleconfig',action='store_true')
parser.add_argument('--local-source',action='store_true')
parser.add_argument('--report')
args = parser.parse_args()
if args.report and Path(args.report).name != args.report: parser.error('--report must be a filename')
if args.local_source and not (args.candidate and args.singleconfig):
    parser.error('--local-source requires --candidate --singleconfig')
dos6 = Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))
nt = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
tool16 = Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'))
runner = root/'extras/build/isolated-tool-runner.exe'
dosbox = Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe'))
sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
stage = Path(tempfile.mkdtemp(prefix='bios-comparison-',dir=root/'extras/build'))
if args.local_source:
    shutil.copytree(root/'bios/inc',stage/'inc')
    (stage/'src').mkdir()
else:
    shutil.copytree(dos6/'inc',stage/'inc')
    shutil.copytree(dos6/'bios',stage/'src')
if args.candidate:
    for name in ('msbio1.asm','mschar.asm','msdisk.asm','msdioctl.asm','msint13.asm',
                 'msbio2.asm','msinit.asm','sysinit1.asm','sysconf.asm',
                 'sysinit2.asm','sysimes.asm','power.asm','ptime.asm','msend.asm'):
        shutil.copyfile(root/'bios'/name,stage/'src'/name)
    if not args.local_source:
        shutil.copyfile(root/'extras/research/bios/syspre.asm',stage/'src/syspre.asm')
    if args.singleconfig:
        for path in (root/'bios/inc').iterdir():
            if path.is_file():
                shutil.copyfile(path,stage/'inc'/path.name)
        for name in ('apmequ.inc','biosseg.inc','biostruc.inc','config.inc','devmark.inc',
                     'msdskpr.inc','msequ.inc','msgroup.inc','power.inc'):
            shutil.copyfile(root/'bios'/name,stage/'src'/name)
if args.singleconfig:
    configured = ['sysinit1.asm','sysinit2.asm','sysconf.asm']
    if not args.local_source:
        configured.append('sysimes.asm')
    elif b'MULTI_CONFIG' in (stage/'src/sysimes.asm').read_bytes().upper():
        raise ValueError('local NTIO SYSIMES unexpectedly references MULTI_CONFIG')
    for name in configured:
        path=stage/'src'/name
        data=path.read_bytes()
        before=b'MULTI_CONFIG equ 1'
        if args.candidate and name != 'sysimes.asm':
            assert before not in data, name
        else:
            assert data.count(before)==1,name
            path.write_bytes(data.replace(before,b';'+before))
if args.local_source:
    for name in (root/'extras/tools/bios_shared_includes.txt').read_text(encoding='ascii').splitlines():
        if not name or Path(name).name != name:
            raise ValueError('invalid shared BIOS include name')
        shutil.copyfile(root/'inc'/name, stage/'inc'/name)
shutil.copyfile(root/'inc/versiona.inc',stage/'inc/versiona.inc')
if args.candidate and args.singleconfig:
    shutil.copyfile(root/'bios/copyrigh.inc',stage/'inc/copyrigh.inc')
assets = {'masm.exe':tool16/'masm.exe','nosrvbld.exe':tool16/'nosrvbld.exe',
          'buildidx.exe':tool16/'buildidx.exe','link.exe':dos6/'c6ers/tools6/bin/link.exe',
          'reloc.exe':dos6/'c6ers/tools6/bin/reloc.exe',
          'usa-ms.msg':root/'messages/usa-ms-dos.msg' if args.local_source else nt/'messages/usa-ms.msg',
          'usa-ibm.msg':root/'messages/usa-ibm.msg' if args.local_source else nt/'messages/usa-ibm.msg',
          'msbio.skl':root/'bios/msbio.skl' if args.local_source else dos6/'bios/msbio.skl',
          'msbio.lnk':root/'bios/msbio.lnk' if args.local_source else dos6/'bios/msbio.lnk'}
for n,p in assets.items(): shutil.copyfile(p,stage/n)
inputs = {str(p.relative_to(stage)):sha(p) for d in ('inc','src')
          for p in sorted((stage/d).rglob('*')) if p.is_file()}
inputs.update({n:sha(p) for n,p in assets.items()})
def phase(name,commands):
    bat='@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    bat+='echo PASS > '+name+'.ok\r\ngoto done\r\n:fail\r\necho FAIL > '+name+'.ok\r\n:done\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(bat.encode('ascii'))
    conf=stage/(name+'.conf')
    conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n',encoding='ascii')
    cmd=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
    r=subprocess.run([str(runner),str(dosbox),str(stage),cmd],capture_output=True,timeout=75)
    (stage/(name+'-host.log')).write_bytes(r.stdout+r.stderr)
    marker=stage/(name+'.ok')
    if r.returncode or not marker.exists() or marker.read_text().strip()!='PASS':
        raise RuntimeError(f'{name} failed; inspect {stage}')

ibm = (stage/'usa-ibm.msg').read_bytes()
boot = re.search(rb'(?im)^BOOT\s+[^\r\n]*\r?\n0001[^\r\n]*\r?\n[^\r\n]*\r?\n',ibm)
assert boot
with (stage/'usa-ms.msg').open('ab') as message:
    message.write(b'\r\n'+boot.group())
phase('messages',['buildidx usa-ms.msg > idx.log','nosrvbld msbio.skl usa-ms.msg > msg.log'])
if args.candidate and args.singleconfig:
    # NOSRVBLD has generated class 3 from the reconstructed DOS 5 skeleton.
    if not (stage/'msbio.cl3').is_file():
        raise ValueError('NOSRVBLD did not generate class 3 messages')
else:
    # The DOS 6 comparison needs the defaults absent from OpenNT messages.
    skeleton = (stage/'msbio.skl').read_bytes()
    class3 = skeleton.split(b':class 3',1)[1].split(b':class 4',1)[0]
    defaults = re.findall(rb'(?im)^:def\s+\d+\s+([^\r\n]+)',class3)
    assert len(defaults) >= 25
    (stage/'msbio.cl3').write_bytes(b'\r\n'.join(defaults)+b'\r\n')
names=re.findall(r'[A-Za-z_][A-Za-z_0-9]*',(stage/'msbio.lnk').read_text().split(',')[0])
expected_units = 14 if args.local_source else 15
assert len(names)==expected_units and len(set(names))==expected_units
units=[]
for name in names:
    shutil.copyfile(stage/'src'/f'{name}.asm',stage/f'{name}.asm')
    cmd=[str(stage/'masm.exe'),'-Mx','-t','-W1',*(['-DOEMBASE'] if args.oembase else []),'-I.','-Iinc','-Isrc',f'{name}.asm,{name}.obj,{name}.lst;']
    r=subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30)
    (stage/f'{name}.log').write_bytes(r.stdout+r.stderr)
    units.append({'name':name,'exit':r.returncode,'object_sha256':sha(stage/f'{name}.obj') if (stage/f'{name}.obj').exists() else None})
    if r.returncode: raise RuntimeError(f'{name} assembly failed; inspect {stage}/{name}.log')
phase('linkbio',['link /MAP @msbio.lnk > link.log','reloc msbio.exe msbio.bin 70 > reloc.log'])
target=read_target('IO.SYS')
assert hashlib.sha256(target).hexdigest()=='dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
actual=(stage/'msbio.bin').read_bytes(); reference=target[0x5a6:]
diffs=[i for i,(a,b) in enumerate(zip(actual,reference)) if a!=b]
intervals=[]
for label,start,end in [('bios_prefix',0,0x6e0),('device_headers',0x23,0x100),
                        ('device_entries',0x6f5,0x762),('interrupt_handlers',0x762,0x8f9)]:
    mismatches=[i for i in range(start,end) if actual[i]!=reference[i]]
    intervals.append({'name':label,'start':start,'end':end,'differences':mismatches,
                      'equal':not mismatches})
assert all(x['equal'] for x in intervals)
if args.candidate:
    for label,start,end in [('candidate_prefix',0,0x8f9),('candidate_init_prefix',0x900,0x19c0),
                            ('physical_bios_code',0x2570,0x3fd0),
                            ('sysinit_stack_prefix',0x3fd0,0x4238),
                            ('sysinit_command_data',0x423b,0x43d0)]:
        mismatches=[i for i in range(start,end) if actual[i]!=reference[i]]
        intervals.append({'name':label,'start':start,'end':end,'differences':mismatches,
                          'equal':not mismatches})
    assert all(x['equal'] for x in intervals)
if args.candidate and args.oembase:
    start,end=0x423b,0x44e1
    mismatches=[i for i in range(start,end) if actual[i]!=reference[i]]
    intervals.append({'name':'oembase_sysinit_data','start':start,'end':end,
                      'differences':mismatches,'equal':not mismatches})
    assert not mismatches
    if not args.singleconfig:
        rows=re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+tempcds\s*$',
                        (stage/'msbio.map').read_text(errors='replace'))
        addresses={int(seg,16)*16+int(off,16) for seg,off in rows}
        assert len(addresses)==1,addresses
        start=addresses.pop()+0x17
        end,target_start=start+34,0x4c1c
        mismatches=[i for i in range(end-start) if actual[start+i]!=reference[target_start+i]]
        intervals.append({'name':'tempcds_allocation','start':start,'end':end,
                          'target_start':target_start,'differences':mismatches,
                          'equal':not mismatches})
        assert not mismatches
if args.candidate and args.oembase and args.singleconfig:
    for label,start,end in [('singleconfig_bios_prefix',0,0x19db),
                            ('command_line_prepare',0x47d9,0x47f2),
                            ('command_exec_setup',0x4849,0x4864),
                            ('command_error_halt',0x4869,0x489b)]:
        mismatches=[i for i in range(start,end) if actual[i]!=reference[i]]
        intervals.append({'name':label,'start':start,'end':end,
                          'differences':mismatches,'equal':not mismatches})
        assert not mismatches
    start,end,target_start=0x4b6e,0x4b98,0x4b6e
    mismatches=[i for i in range(end-start) if actual[start+i]!=reference[target_start+i]]
    intervals.append({'name':'clr_vdisk_displaced','start':start,'end':end,
                      'target_start':target_start,'differences':mismatches,
                      'equal':not mismatches,
                      'scope':'Displaced comparison; differences need relocation analysis.'})
    assert not mismatches
    for label,target_start,length in [('install_exit_code',0x5110,11),
                                      ('install_return_pararound',0x511f,13)]:
        start=target_start; end=start+length
        mismatches=[i for i in range(length) if actual[start+i]!=reference[target_start+i]]
        intervals.append({'name':label,'start':start,'end':end,'target_start':target_start,
                          'differences':mismatches,'equal':not mismatches})
        assert not mismatches
report={'stage':str(stage),'inputs':inputs,'units':units,'messages':{p.name:sha(p) for p in stage.glob('msbio.cl*')},
        'candidate':args.candidate,
        'oembase':args.oembase,
        'singleconfig':args.singleconfig,
        'local_source':args.local_source,
        'combined_message_sha256':sha(stage/'usa-ms.msg'),
        'bios_map_sha256':sha(stage/'msbio.map'),
        'msbio1_matches_candidate_source':sha(stage/'src/msbio1.asm')==sha(root/'bios/msbio1.asm'),
        'target_intervals':intervals,
        'output':{'length':len(actual),'sha256':sha(stage/'msbio.bin'),
                  'target_remaining_length':len(reference),'common_prefix_differences':len(diffs),
                  'first_difference':diffs[0] if diffs else None,'equal':actual==reference},
        'scope':('Single-config candidate using DOS 5 class 3 source; direct comparison against pinned BIOS extract, no runtime claim.' if args.candidate and args.singleconfig else 'DOS 6 comparison using combined reference messages and DOS 6 class 3 defaults; no runtime claim.')}
report_name=args.report or ('m5-bios-singleconfig-probe.json' if args.singleconfig else
             'm5-bios-oembase-probe.json' if args.oembase else
             'm5-bios-physical-candidate-build.json' if args.candidate else 'm5-bios-comparison-build.json')
(root/'extras/docs/etc/evidence'/report_name).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='inputs'},indent=2))
