# This is a template Dockerfile for creating a new image.  
# See the README for a complete description of how you create derivative images.
# NOTE that this image will not auto-build because there is a separate prerequisite
# step needed to create the NGINX binary.  Use 'build.sh' to create new images.

FROM chapdev/chaperone-alpinebase
ADD . /setup/
RUN /setup/build/install.sh
