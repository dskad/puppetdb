#!/bin/bash
docker run -it \
        --hostname puppetdb.example.com \
        --name puppetdb \
        --tmpfs /run:rw,noexec,nosuid,size=65536k \
        --net puppet_puppetnet \
        --net-alias puppetdb.example.com \
        -e PUPPETSERVER=puppet \
        -e PUPETENV=production \
        -e WAITFORCERT=15s \
        -p 8080:8080 \
        -p 8081:8081 \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        puppetagent
