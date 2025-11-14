SHELL := /bin/bash

.PHONY: build run-service run-demo lint-openapi seed-facts host clean-artifacts

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

host:
	@echo "Start the Host in FountainKit separately (example):";
	@echo "  HOST_AGENTS=fountain.coach/agent/midi2-instrument-lab/service swift run --package-path Packages/FountainApps midi-instrument-host"

clean-artifacts:
	rm -rf Artifacts/* Data/*

