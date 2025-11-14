#!/usr/bin/env python3
import sys, json, os

def load_ndjson(path):
    out=[]
    with open(path,'r') as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try:
                out.append(json.loads(line))
            except Exception:
                pass
    return out

def main():
    if len(sys.argv)<2:
        print("usage: check-invariants.py <RUN_DIR>", file=sys.stderr)
        sys.exit(2)
    run_dir=sys.argv[1]
    events_path=os.path.join(run_dir,'events.ndjson')
    ump_path=os.path.join(run_dir,'ump.ndjson')
    if not os.path.exists(events_path):
        print(json.dumps({"ok": False, "error": "missing events.ndjson"}))
        sys.exit(1)
    ev=load_ndjson(events_path)
    # Invariants: timestamps monotonic non-decreasing; note on/off pairs per pitch
    ok=True
    issues=[]
    # monotonic ts
    last=-1e9
    for i,e in enumerate(ev):
        ts=e.get('ts')
        if ts is None or ts < last:
            ok=False; issues.append({"type":"non_monotonic_ts","index":i,"ts":ts,"prev":last})
            break
        last=ts
    # on/off balance
    bal={}
    for e in ev:
        t=e.get('type'); p=e.get('pitch')
        if t=='note.on': bal[p]=bal.get(p,0)+1
        elif t=='note.off': bal[p]=bal.get(p,0)-1
    unbalanced={k:v for k,v in bal.items() if v!=0}
    if unbalanced:
        ok=False; issues.append({"type":"unbalanced_notes","detail":unbalanced})
    # report
    out={"ok": ok, "issues": issues}
    if os.path.exists(ump_path):
        out["ump_lines"]=sum(1 for _ in open(ump_path,'r'))
    print(json.dumps(out))
    sys.exit(0 if ok else 1)

if __name__=='__main__':
    main()

