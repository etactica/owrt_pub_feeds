#!/usr/bin/env python3
"""
A simple https server, used for unit testing some lua https client code.

Pre-requisites: make a cert! (this makes a combined file)
openssl req -new -x509 -keyout server.pem -out server.pem -days 365 -nodes
"""
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
import io
import logging
import ssl


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
	def do_GET(self):
		self.send_response(200)
		self.end_headers()
		self.wfile.write(b'Hello, world!')

	def do_POST(self):
		rc = 200
		bits = self.path.split("/")
		if len(bits) == 3 and bits[1] == "makeerror":
			rc = int(bits[2])

		content_length = int(self.headers['Content-Length'])
		body = self.rfile.read(content_length)
		self.send_response(rc)
		self.end_headers()
		response = io.BytesIO()
		response.write(b'This is POST request. ')
		response.write(b'Received: ')
		response.write(body)
		self.wfile.write(response.getvalue())

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-p", "--port", help="Port to listen to", default=8912, type=int)
parser.add_argument("-k", "--combined_key", help="Path to a pem encoded cert+key file", default="server.pem")
opts = parser.parse_args()

httpd = HTTPServer(('localhost', opts.port), SimpleHTTPRequestHandler)

httpd.socket = ssl.wrap_socket (httpd.socket, certfile=opts.combined_key, server_side=True)

httpd.serve_forever()