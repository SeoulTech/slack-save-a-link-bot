Slack bot to save links
-----------------------

Saves messages from Slack using Outgoing WebHooks integration.

Each dir in this repository is meant to be a an implementation of the same program, using different technologis.
See README's in each dir for details on build\deployment process.


## Sepc
Slack bot accepts requests to save links through very basic REST API using JSON. 

The API has two end-points:
 - */api/v1/links*
   - GET /api/v1/links returns the list of all links
   - POST /api/v1/links will save trimmed content of "text"-"trigger_word" fields from the payload
 - */api/v1/dump*
   - and request here gets dumped to server logs with all payloads, fields, etc.

All API responces should be a well-formatted JSON object with at least one field "text", wich will be represented to user by Slack.

Simple authorization on-write is done by checking the "token" field in request payload, wich should match the one from Slack OutgoingWebhooks integrations page

**TODO:**
  - [x] add common spec
  - [ ] add acceptance test infrastructure AKA #1
  - [ ] automate spec verification (write the tests that can be re-used!)
  - [x] add Haskell impl
  - [ ] add shared client-side app
  - [ ] add python impl
  - [ ] add C++ impl
  - [ ] add stress/performance test to compare impls
