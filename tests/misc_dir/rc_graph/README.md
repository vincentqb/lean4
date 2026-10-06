# Reference-counting regression

Run `tests/with_stage1_test_env.sh tests/misc_dir/rc_graph/run_test.sh` from the
repository root.

The native graph tests check the existing runtime against a counted-edge oracle.
`concurrent.c` checks retained payloads and exactly-once finalization with eight workers.
`Graph.lean` proves serial ownership safety and completeness.

Scratch files stay under this test's `_tmp/`.
`Concurrent.lean` proves the shared-counter ownership invariant across guard/update histories.
