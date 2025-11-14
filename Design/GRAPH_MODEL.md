# Graph Model — Formal Shapes and Examples (v0)

This document specifies the in‑memory model for nodes, ports, edges, and graphs used by MIDI2InstrumentLab. It complements the Session schema and informs the headless runner and UI.

Principles
- Typed ports; only compatible kinds connect (Event↔Event, Audio↔Audio).
- Explicit, stable identifiers for nodes and ports; edges reference ids.
- Simple, extensible shapes (additionalProperties: true encouraged) with schema versioning (`graph.schema`).

## Types (pseudo‑schema)

NodeType:
- instrument | effect | controller | master

PortKind:
- event.in | event.out | audio.in | audio.out | property.in | property.out

Node (object):
- id: string
- type: NodeType
- label?: string
- params?: object (node‑specific parameters)
- ports: Port[]

Port (object):
- id: string (unique within the node)
- kind: PortKind
- channels?: integer (audio)*
- group?: integer (MIDI2 group)*
- channel?: integer (MIDI2 channel)*

Edge (object):
- id: string
- from: { node: string, port: string }
- to:   { node: string, port: string }

Graph (object):
- schema: string (e.g., "avw.graph.v0")
- nodes: Node[]
- edges: Edge[]
- meta?: object

Constraints
- PortKind compatibility enforced at connect time.
- No cycles in audio domain; event domain may allow feedback under guarded conditions (future).

## Example — Minimal Graph (JSON)

```json
{
  "schema": "avw.graph.v0",
  "nodes": [
    {
      "id": "ctl1",
      "type": "controller",
      "label": "LFO-1",
      "ports": [ { "id": "event.out", "kind": "event.out" } ]
    },
    {
      "id": "inst1",
      "type": "instrument",
      "label": "MPE-Synth",
      "ports": [
        { "id": "event.in", "kind": "event.in", "group": 0 },
        { "id": "audio.out", "kind": "audio.out", "channels": 2 },
        { "id": "property.in", "kind": "property.in" }
      ]
    },
    {
      "id": "fx1",
      "type": "effect",
      "label": "Hall-Reverb",
      "ports": [
        { "id": "audio.in",  "kind": "audio.in",  "channels": 2 },
        { "id": "audio.out", "kind": "audio.out", "channels": 2 }
      ]
    },
    {
      "id": "master",
      "type": "master",
      "label": "Master",
      "ports": [ { "id": "audio.in", "kind": "audio.in", "channels": 2 } ]
    }
  ],
  "edges": [
    { "id": "e1", "from": { "node": "ctl1",  "port": "event.out" }, "to": { "node": "inst1", "port": "event.in" } },
    { "id": "e2", "from": { "node": "inst1", "port": "audio.out" }, "to": { "node": "fx1",   "port": "audio.in" } },
    { "id": "e3", "from": { "node": "fx1",   "port": "audio.out" }, "to": { "node": "master", "port": "audio.in" } }
  ]
}
```

## Port Naming Conventions
- event.in / event.out
- audio.in / audio.out (append ".N" if addressing specific channel buses later)
- property.in / property.out (PE flows; rarely connected directly; host mediates PE)

## Integration With Session
- The Session (`avw.session.v0`) may embed or reference a Graph in the future (`graph` or `graphRef`). For v0, the routing is implicit: single instrument → effects → master. This document prepares a stable shape for v1.

