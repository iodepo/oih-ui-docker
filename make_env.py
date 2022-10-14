#!/usr/bin/env python3
import os, sys, base64

FILENAME='.env'

def noop(s): return s
def lower(s): return s.lower()
def _bool(s):
    return {'t':'true',
            'y':'true',
            'n':'false',
            'f': 'false'}.get(s.lower(), s.lower())

VARS = (('HOST', 'Hostname', lower),
        )

def random_pw():
    with open('/dev/urandom', 'rb') as f:
        return base64.urlsafe_b64encode(f.read(12))

print ("""
Making the ENV file...
""")

if os.path.exists(FILENAME):
    print (".env file exists, either remove or edit directly")
    sys.exit(0)

vars = dict((var,_filter(input(prompt + "? ").strip())) for var, prompt, _filter in VARS)

# for pw in ('DB_PASS',
#            'POSTGRES_PASSWORD',
#            'ADMIN_PASS'):
#     vars[pw] = random_pw()

with open (FILENAME, 'w') as f:
    for k,v in sorted(vars.items()):
        strVal = v
        if isinstance(v, bytes):
            strVal=v.decode('ascii')
        f.write("%s=%s\n" % (k,strVal))


sys.exit(0)
