#!/usr/bin/env python
import os, sys, base64

FILENAME='.env'

def lower(s): return s.lower()
def _bool(s):
    return {'t':'true',
            'y':'true',
            'n':'false',
            'f': 'false'}.get(s.lower(), s.lower())

VARS = (('HOST', 'Hostname', lower),
        ('PRODUCTION', 'Is this production (t/f)', _bool),
        ('IMAGE_TAG', 'staging/prod', lower),
        ('SITE_SCHEME', 'http/https', lower),
        ('SHORT_CODE', 'shortecode for site, one word', lower)
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

vars = dict((var,_filter(raw_input(prompt + "? ").strip())) for var, prompt, _filter in VARS)

for pw in ('DB_ENV_POSTGRES_PASS',
           'DB_ENV_DATASTORE_PASS',
           'DB_ENV_DATASTORE_RO_PASS',
           'ADMIN_PASSWORD',
           'POSTGRES_PASSWORD',
           'DB_ENV_SUPERSET_PASS',
           'SUPERSET_SECRET',
           'SUPERSET_SECRET_KEY'):
    vars[pw] = random_pw()

with open (FILENAME, 'wa') as f:
    for item in sorted(vars.items()):
        f.write("%s=%s\n" % item)

print ("\n\nAdmin Password: %s\n" % vars['ADMIN_PASSWORD'])

sys.exit(0)
