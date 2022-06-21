#!/usr/bin/env python3
import base64

with open('/dev/urandom', 'rb') as f:
    print (base64.urlsafe_b64encode(f.read(12)).decode('utf-8'))
