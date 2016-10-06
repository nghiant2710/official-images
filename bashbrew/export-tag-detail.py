#!/usr/bin/env python

import sys
import os.path as Path

from docker import Client

def main():
	if len(sys.argv) < 3:
		print("Missing arguments")
		sys.exit(1)

	image_name, tag = sys.argv[1].split(':')
	path = sys.argv[2]

	cli = Client(base_url='unix://var/run/docker.sock', version='auto')
	image = cli.images("resin/" + sys.argv[1])
	f = open(Path.join(path, image_name + "-temp"), 'a')
	f.write("Tag: {tag}, Id: {id}, Size: {size} MB.\n".format(
		tag=tag,
		id=image[0]['Id'],
		size="{0:.2f}".format(float(image[0]['VirtualSize'])/(1024*1024))
	))
	f.close()

if __name__ == '__main__':
	main()