#!/bin/sh
# pi-box entrypoint.
#
# Normal mode: the host config is mounted read-only at $PI_BOX_CONFIG_SRC and
# /root/.pi/agent is an in-memory (tmpfs) dir. We copy the source in so pi can
# lock/write settings.json — required to load installed packages/skills — while
# the agent's writes stay ephemeral and never reach the host.
#
# Edit mode: /root/.pi/agent is bind-mounted read-write directly and no source
# dir is mounted, so we skip the copy and changes persist to the host.
if [ -n "$PI_BOX_CONFIG_SRC" ] && [ -d "$PI_BOX_CONFIG_SRC" ]; then
	# The sessions subdir is a separate read-write mount; copying the (empty)
	# source sessions dir over it is harmless. Errors touching the mount are
	# ignored.
	cp -a "$PI_BOX_CONFIG_SRC/." /root/.pi/agent/ 2>/dev/null || true
fi

exec pi "$@"
