<?php
// Current RAM usage and containers sorted by memory, as plain text for RamGuard.page
header('Content-Type: text/plain; charset=utf-8');
passthru('/usr/local/emhttp/plugins/ram.guard/scripts/ramguard status 2>&1');
