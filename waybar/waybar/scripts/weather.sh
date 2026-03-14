#!/bin/bash
curl -s "wttr.in/?format=%c+%t" 2>/dev/null || echo ""
