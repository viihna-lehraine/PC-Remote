#!/bin/bash

systemctl --user daemon-reload
systemctl --user restart pc-remote.service
