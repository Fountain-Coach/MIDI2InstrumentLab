SHELL := /bin/bash

.PHONY: build run-service run-demo lint-openapi seed-facts verify-facts host clean-artifacts check-invariants demo-check

build:
	swift build -c debug --product lab-service --product lab-runner

run-service: build
	LAB_PORT?=8088; \
	./.build/debug/lab-service

run-demo: build
	RUN_DIR=Artifacts/demo-`date +%Y%m%d-%H%M%S`; \
	mkdir -p $${RUN_DIR}; \
	./.build/debug/lab-runner --session-file sessions/example.avwsession.json --out $${RUN_DIR}; \
	echo "Artifacts → $${RUN_DIR}"; ls -l $${RUN_DIR}

lint-openapi:
	npx --yes @redocly/cli@latest lint openapi/v1/lab.yml

seed-facts:
	@echo "Seeding Facts via Tools Factory (ensure it is running)…";
	@[ -n "$$TOOLS_FACTORY_URL" ] || TOOLS_FACTORY_URL=http://127.0.0.1:8011; \
	python3 - <<'PY'
import json,sys,subprocess,os
url=os.environ.get('TOOLS_FACTORY_URL','http://127.0.0.1:8011')+'/agent-facts/from-openapi'
spec=open('openapi/v1/lab.yml','r').read()
doc={"agentId":"fountain.coach/agent/midi2-instrument-lab/service","seed":True,"openapi":spec}
subprocess.run(['curl','-s','-X','POST',url,'-H','Content-Type: application/json','-d',json.dumps(doc)],check=False)
PY

verify-facts:
	@echo "Verifying Facts from Tools Factory (seed=false)…";
	@[ -n "$$TOOLS_FACTORY_URL" ] || TOOLS_FACTORY_URL=http://127.0.0.1:8011; \
	python3 - <<'PY'
import json,sys,subprocess,os
url=os.environ.get('TOOLS_FACTORY_URL','http://127.0.0.1:8011')+'/agent-facts/from-openapi'
spec=open('openapi/v1/lab.yml','r').read()
doc={"agentId":"fountain.coach/agent/midi2-instrument-lab/service","seed":False,"openapi":spec}
p=subprocess.run(['curl','-s','-X','POST',url,'-H','Content-Type: application/json','-d',json.dumps(doc)],check=True,stdout=subprocess.PIPE)
facts=json.loads(p.stdout)
props=[]
for fb in facts.get('functionBlocks',[]):
  for pr in fb.get('properties',[]):
    props.append(pr.get('id'))
need={'health','runs.start','runs.get','artifacts.list','artifacts.get','introspect.au'}
missing=[x for x in need if x not in set(props)]
ok = not missing
print(json.dumps({"ok": ok, "missing": missing}))
sys.exit(0 if ok else 1)
PY

host:
	@echo "Start the Host in FountainKit separately (example):";
	@echo "  HOST_AGENTS=fountain.coach/agent/midi2-instrument-lab/service swift run --package-path Packages/FountainApps midi-instrument-host"

clean-artifacts:
	rm -rf Artifacts/* Data/*

check-invariants:
	@if [ -z "$$RUN_DIR" ]; then echo "usage: make check-invariants RUN_DIR=Artifacts/run-..." >&2; exit 2; fi; \
	python3 scripts/check-invariants.py "$$RUN_DIR"

demo-check: run-demo
	@last=$$(ls -dt Artifacts/demo-* | head -1); echo "Checking $$last"; \
	python3 scripts/check-invariants.py "$$last"
