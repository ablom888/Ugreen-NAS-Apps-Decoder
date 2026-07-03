#!/bin/bash

# 执行修改所有容器关闭重启策略
docker update --restart no $(docker ps -aq)