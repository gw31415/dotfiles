function docker_lima
	# To use Docker with lima you need to set up a docker template:
	# $ limactl start --name=docker template://docker
	limactl start docker

	# In Docker, you need to set up a connection to lima:
	# $ docker context create lima-docker --docker "host=unix:///Users/ama/.lima/docker/sock/docker.sock"
	docker context use lima-docker
end
