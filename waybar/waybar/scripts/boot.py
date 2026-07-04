#!/usr/bin/env python3
from datetime import datetime

import psutil


def get_boot_and_uptime():
    boot_timestamp = psutil.boot_time()
    current_timestamp = datetime.now().timestamp()

    boot_time = datetime.fromtimestamp(boot_timestamp)
    now = datetime.now()

    uptime_duration = now - boot_time

    total_seconds = int(uptime_duration.total_seconds())

    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60

    formatted_boot = boot_time.strftime("%Y-%m-%d %H:%M:%S")
    formatted_uptime = f"{hours}h {minutes}m"

    return formatted_boot, formatted_uptime


boot_date, uptime = get_boot_and_uptime()

print(uptime)
