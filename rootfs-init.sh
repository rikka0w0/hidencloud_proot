#!/bin/sh
apt update -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false
apt install -y ca-certificates
apt update
apt install -y curl wget nano iproute2
