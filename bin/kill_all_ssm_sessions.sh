#!/bin/bash
for each in `aws ssm describe-sessions --state Active | jq -r '.Sessions[]  | .SessionId'`;do aws ssm terminate-session --session-id ${each};done
