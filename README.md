AWS Load Balancer Docker Image
==============================

This is a custom load-balancer designed originally for AWS, but can be used in
practically any other context as well.  All AWS-specific features are optional.
Yes, AWS already has Elastic Load Balancers, but this image was created for
situations where a more flexible configuration is needed, such as cases where
you are load balancing between IP addresses running on the same instance (yes,
some people need this).

The version of NGINX included also includes the excellent
[nginx-sticky-module-ng](https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng),
so that the `sticky` directive can be used within `upstream` blocks, similar to
NGINX Plus.

Features of this Load Balancer are:

-   Automatically does an A-Record lookup to determine the IP numbers of
    back-end servers.  This makes it easy to have backends auto-register
    themselves in DNS (such as Route-53) and have the load-balancer reconfigure
    itself automatically.

-   Can use public A-Record hostname, or an optional name-server can be
    specified in case the DNS is hosted privately.  This means you can create
    unregistered domains in Route-53 to hold your Load Balancer definitions.

-   Allows independent specification of SSL for front-end and back-end servers.
    So, you can have NGINX offload the SSL burden so that your backends can
    simply run HTTP.

-   If the front-end is SSL, will automatically publish a redirection for HTTP
    (can be disabled).

-   Uses session affinity (sticky cookies) by default for Load Balancer logic,
    but can be fully customised by editing the default `nginx.conf` template.

-   Lean 68MB Docker image.

-   Includes automatic log rotation for NGINX logs.

-   Can store NGINX and other configuration, as well as logs, in attached
    storage so that the image can be easily upgraded.

Quick Start
-----------

You can get started quickly using the [image hosted on Docker Hub](https://hub.docker.com/r/garywiz/aws-load-balancer/).
For example, to quickly create a running self-contained load-balancer server daemon:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ docker pull garywiz/aws-load-balancer
$ docker run -d -p 80:8080 -e LB_DETECT_HOSTNAME=backends.mydomain.org garywiz/aws-load-balancer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once the load balancer starts, it will configure itself based upon the A-Records
located at `LB_DETECT_HOSTNAME`. and begin serving content immediately.

HTTP is published internally on port 8080.  HTTPS is published internally (when
enabled) on port 8443.

Customizations
--------------

If you want to customize the configuration further, such as adding SSL or other
features, you can use the built-in launcher script. Extract the launcher script
from the image like this:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ docker run -i --rm garywiz/aws-load-balancer --task get-launcher | sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This will create a flexible launcher script that you can customize or use as a
template. You can run it as a daemon:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ ./run-aws-load-balancer.sh -d
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Or, if you want to have local persistent storage:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ mkdir aws-load-balancer-storage
$ ./run-aws-load-balancer.sh -d
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, all persistent data, logs, and configuration will be stored in the
`aws-load-balancer-storage` directory. The container itself is therefore
entirely disposable.

The `run-aws-load-balancer.sh` script is designed to be self-documenting and you
can edit it to change start-up options and storage options. You can get
up-to-date help on the image's features like this:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ docker run -i --rm garywiz/aws-load-balancer --task get-help
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Full Option List
----------------

If you want to invent your own start-up, or are using an orchestration tool,
here is a quick view of all the configuration options piled into one command
along with their defaults:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ docker run -d garywiz/aws-load-balancer \
  -p 443:8443 -p 80:8080 \
  -e LB_DETECT_HOSTNAME=backend-servers.example.org \
  -e LB_DETECT_NAMESERVER=optional-ns.example.org \
  -e SSL_FRONT=false \
  -e SSL_BACK=false \
  -e HTTP_REDIRECT=true
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

-   `LB_DETECT_HOSTNAME`: This is the DNS record which contains one or more
    A-Records which define the backend servers.  *This is required.*

-   `LB_DETECT_NAMESERVER`: An optional name server which (name or IP address)
    which should be used to perform DNS lookups.  If not specified, then a
    standard public lookup will be done.

-   `SSL_FRONT`:  If set to "true", then the load balancer will serve HTTPS on
    internal port 8443.  Otherwise, internal port 8080 will serve HTTP traffic.
    **Important:** This setting will have no effect unless you provide your SSL
    certificate and keys as specified below under "SSL Configuration".

-   `SSL_BACK`: If set to "true", then backends will use the HTTPS protocol
    instead of HTTP.  Defaults to "false".

-   `HTTP_REDIRECT`: This setting is only recognized if `SSL_FRONT` is "true"
    and a valid SSL certificate is provided.  In this case, it will cause an
    HTTP to HTTPS redirect to be served on internal port 8080.  This setting
    defaults to "true".

AWS User Data Feature
---------------------

If you use the built-in launcher (as described above under "Customizations"),
the launcher will automatically read any AWS user data provided to the instance
as a list of newline-separated environment variables.  Thus, you can start an
AWS instance with user-data such as:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SSL_FRONT: true
LB_DETECT_HOSTNAME=custom-servers.example.org
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The launcher will also work in non-AWS environments without change.

Configuring Attached Storage
----------------------------

When configuring attached storage, there are two considerations:

1.  Attached storage must be mounted at `/apps/var` inside the container,
    whether using the Docker `-v` switch, or `--volumes-from`.

2.  You will need to tell the container to match the user credentials using the
    `--create-user` switch ([documented here on the Chaperone
    site](http://garywiz.github.io/chaperone/ref/command-line.html#option-create-user)).

Both are pretty easy. For example, assume you are going to store persistent data
on your local drive in `/persist/aws-lb`. Providing the directory exists, you
can just do this:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ docker run -d -v /persist/aws-lb:/apps/var garywiz/aws-load-balancer \
     --create-user anyuser:/apps/var
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the container starts, it will assure that all internal services run as a
new user called `anyuser` whose UID/GID credentials match the credentials your
host box has assigned to `/persist/aws-lb`.

That's it!

When you run the container, you'll see that all the load balancer persistent
data files have been properly created in `/persist/aws-lb`.

SSL Configuration
-----------------

In order to use SSL, you will need to run the load balancer image using attached
storage.   This also allows you to make many other customizations, such as
changing the NGINX start-up template.

This is easy if you're using the provided launcher, as described above. The
first thing to do is run the container once just to initialize the persistent
storage directory:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ mkdir aws-load-balancer-storage
$ ./run-aws-load-balancer.sh -d
Using attached storage at .../aws-load-balancer-storage
00e9615bc51d63f9a150186482b3258d1c24b4f21ca0c781ae6e1717d9c97abc
$
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now that your container is running, you should see the following in
`aws-load-balancer-storage`:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ cd aws-load-balancer-storage
$ ls
log nginx.conf nginx.conf.tp nginx_ssl nginx_temp run server.cache
$
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Certificates should be stored in the `nginx_ssl` directory:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ cd nginx_ssl
$ ls
README.txt
$
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Initially, the directory will not contain any SSL keys, but will contain a
README telling you what to do.

The rest is quite simple:

-   Store your server certificate in the file `nginx_ssl/server.crt`

-   Store your server key (it must not have a password) in the file
    `nginx_ssl/server.key`

-   Now, modify `run-aws-load-balancer.sh` to enable SSL and specify any other
    start-up parameters.

Once you've done this, it's probably a good idea to stop (and even delete) your
container, as all persistent data is now stored in `aws-load-balancer-storage`.
