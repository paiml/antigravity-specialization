Write scripts/deploy.sh VERSION. It copies a fixed list of files (not tests, not node_modules, not data) to releases/VERSION on the host, points a `current`
link at it, restarts the app and probes /healthz. Run commands locally when DEPLOY_HOST=local and over ssh otherwise. The token must never appear on a command line:
write it to a file with mode 600 and have the start script read it. Record the previous release so it can be rolled back. Do not run it against any real host.
