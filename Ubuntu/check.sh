#!/bin/bash
(ip -4 addr show | grep "inet" | awk '{print $2}' | grep -v "127.0.0.1")
