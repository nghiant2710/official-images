#!/bin/bash

usage() {
	cat <<EOUSAGE
This script processes the specified Docker images using the corresponding
repository manifest files.

push options:
  -p			Don't build, only push image(s) to registry

version options:
  -n			Don't create datestamped image(s)
EOUSAGE
}

# If the build fails, set 1 as exit code and store failed image.
is_success() {
	if [ $1 -ne 0 ]; then
		exitCode=1
		if [ -z "$TAGS" ]; then
			failedList+=($LIBRARY)
		else
			failedList+=($LIBRARY:$2)
		fi
	fi
}

exitCode=0
failedList=()
pushOnly=
aliases=
args=

# Args handling
while getopts ":pna"  opt; do
	case $opt in
		p)
			pushOnly=1
			;;
		n)
			args+=' --no-datestamp'
			;;
		a)
			shift
			aliases=$1 && shift
			;;
		\?)
			{
				echo "Invalid option: -$OPTARG"
				usage
			}>&2
			exit 1
      		;;
	esac
done

# parse aliases
if [ ! -z "$aliases" ]; then
	for alias in $aliases; do
		args+=" --alias=$alias"
	done
fi

# Jenkins build steps
cd bashbrew/
if [ -z "$TAGS" ]; then
	if [ -z "$pushOnly" ]; then
		# Build and push all images
		./bashbrew.sh build $LIBRARY --library=../library --namespaces=resin $args
		is_success $?
	else
		# Push all images
		./bashbrew.sh push $LIBRARY --library=../library --namespaces=resin $args
		is_success $?
	fi
else
	for tag in $TAGS; do
		if [ -z "$pushOnly" ]; then
			# Build specified images only
			./bashbrew.sh build $LIBRARY:$tag --library=../library --namespaces=resin $args
			is_success $? $tag
		else
			# Push specified images
			./bashbrew.sh push $LIBRARY:$tag --library=../library --namespaces=resin $args
			is_success $? $tag
		fi
	done
fi

if [ -f image-list ]; then
	images=$(cat image-list | grep -vE '^#|^\s*$')
	for image in "${images[@]}"; do
		docker rmi -f "$image"
	done
	rm -f image-list
fi

# Delete all stopped containers
docker ps -q -f status=exited | xargs --no-run-if-empty docker rm -f
# Delete all unused images
docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi -f	
