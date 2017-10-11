#!/usr/bin/env python
""" server component to read traefik hosts
and present them as links """

import sys
import consul
import requests
from flask import Flask
from flask import render_template

app = Flask(__name__)  # pylint: disable=invalid-name

client = consul.Consul()
services = dict()

@app.route('/')
def index():
    """ index page function """
    foo, items = client.catalog.services()
    for service, tags in items.iteritems():
        proto = None
        if 'http' in tags:
            proto = 'http'
        if 'https' in tags:
            proto = 'https'
        if proto:
            services.update({ service: proto })
    return render_template('index.html', services=services)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(5000))
