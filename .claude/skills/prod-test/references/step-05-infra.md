# Step 5: Set Up Test Infrastructure

Create the test target that the deliverable will run against.

## When This Step Applies

Only if step 1 identified infrastructure needs. Skip if the deliverable runs locally (CLI tool, library).

## Infrastructure Patterns

### Docker + SSH (network tools)
```
_test/docker/Dockerfile        → target OS + service
_test/docker/docker-compose.yml → port mapping
_test/docker/test_key           → SSH key pair
```

1. Write Dockerfile (target OS + required services + key auth)
2. Generate SSH key pair (`ssh-keygen -t ed25519`)
3. Write docker-compose.yml (port mapping, container name)
4. Build and start: `docker-compose -f [test_path]/_test/docker/docker-compose.yml up -d --build`
5. Verify target reachable (SSH, HTTP, or ping depending on service)

### Docker + Browser (web UI tools)
```
_test/docker/docker-compose.yml → app + browser service
```

1. Write docker-compose with app service + Playwright/Selenium
2. Build and start
3. Verify app reachable via HTTP

### Mock Server (API clients)
```
_test/mock/server.py → mock API responses
_test/fixtures/responses.json → canned response data
```

1. Write mock server script
2. Start in background
3. Verify responding on expected port

### No Infra (CLI tools, libraries)
Skip this step entirely. Tests will import/invoke the deliverable directly.

## Verification

- [ ] Test target is reachable (connectivity verified)
- [ ] Required services are running
- [ ] Authentication works (if applicable)

## Cleanup Note

Whatever is set up here must be torn down in step 8. Track what was created so cleanup knows what to remove.
