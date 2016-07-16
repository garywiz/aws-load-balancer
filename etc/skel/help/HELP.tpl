Help for Image: %(PARENT_IMAGE) Version %(IMAGE_VERSION) 
     Chaperone: %(`chaperone --version | awk '/This is/{print $5}'`)
         Linux: %(`( cat /etc/system-release 2>/dev/null || cat /etc/issue ) | head -1 | sed -e 's/Welcome to //' -e 's/ \\.*$//'`)

This docker image provides a fully-configurable NGINX Load Balancer.  The load balancer
will configure itself automatcially given a DNS record containing A-records for
the backend servers.  This is specified by the (required) LB_DETECT_HOSTNAME environment
variable.  All other environment variables are optional.

You can find out more about configuration and how to use this image at:

    https://github.com/garywiz/aws-load-balancer

You can extract ready-made startup scripts for this image by running
the following command:

  $ docker run -i --rm %(PARENT_IMAGE) --task get-launcher | sh
