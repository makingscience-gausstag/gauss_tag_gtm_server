#!/bin/bash

sed -Ei "s/(const VERSION = ')[0-9.a-z-]+'/\1$(git describe --tags --always --long)\'/g" template.tpl