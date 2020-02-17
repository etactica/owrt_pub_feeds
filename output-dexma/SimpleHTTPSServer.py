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

import time


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
	def do_GET(self):
		self.send_response(200)
		self.end_headers()
		self.wfile.write(b'Hello, world!')

	def do_OPTIONS(self):
		print("Attempting to handle CORS") # but failing, because the browser won't recognize our cert anyway
		self.send_response(200)
		self.send_header("Access-Control-Allow-Origin", "*")
		self.send_header("Access-Control-Allow-Headers", "x-dexcell-source-token")
		self.send_header("Access-Control-Allow-Headers", "Content-Type")
		self.end_headers()

	def do_POST(self):
		rc = 200
		time.sleep(0.7)
		bits = self.path.split("/")
		if len(bits) == 3 and bits[1] == "makeerror":
			rc = int(bits[2])

		content_length = int(self.headers['Content-Length'])
		token = self.headers["x-dexcell-source-token"]
		if token not in ["mysecret", "token-list"]:
			self.send_response(401, "hoho mofo, go away!")
			self.send_header("Access-Control-Allow-Origin", "*")
			self.end_headers()
			self.wfile.write(b"token not recognised")
			return
		body = self.rfile.read(content_length)
		self.send_response(rc)
		self.send_header("Access-Control-Allow-Origin", "*")
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

saddr = ('0.0.0.0', opts.port)
httpd = HTTPServer(saddr, SimpleHTTPRequestHandler)
print("Listening on ", saddr)

httpd.socket = ssl.wrap_socket (httpd.socket, certfile=opts.combined_key, server_side=True)

httpd.serve_forever()
