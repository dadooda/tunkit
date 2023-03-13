
# The SSH tunnel kit


* [Overview](#overview)
* [Created using Procdown](#created-using-procdown)
* [Quick start](#quick-start)
  * [Set up SOCKS proxy to bypass sites blocking](#set-up-socks-proxy-to-bypass-sites-blocking)
  * [Set up direct SSH access to a Linux server running on a virtual machine or in the cloud](#set-up-direct-ssh-access-to-a-linux-server-running-on-a-virtual-machine-or-in-the-cloud)
  * [Set up Remote Desktop (RDP) or VNC access to my Windows machine](#set-up-remote-desktop-rdp-or-vnc-access-to-my-windows-machine)
  * [Set up the home server or NAS to build multiple tunnels to other machines on my local network](#set-up-the-home-server-or-nas-to-build-multiple-tunnels-to-other-machines-on-my-local-network)
* [Step-by-step setup](#step-by-step-setup)
  * [Server setup: SSH](#server-setup-ssh)
  * [Server setup: User and key](#server-setup-user-and-key)
  * [Server setup: Nginx-based semaphore website](#server-setup-nginx-based-semaphore-website)
  * [Client setup (Linux or WSL)](#client-setup-linux-or-wsl)
  * [Client setup (Cygwin)](#client-setup-cygwin)
  * [Tunnel setup: SOCKS (Linux, WSL or Cygwin)](#tunnel-setup-socks-linux-wsl-or-cygwin)
  * [Tunnel setup: Remote access (Linux)](#tunnel-setup-remote-access-linux)
  * [Tunnel setup: Remote access (WSL)](#tunnel-setup-remote-access-wsl)
  * [Tunnel setup: Having a working remote access tunnel, make its clone (Linux or WSL)](#tunnel-setup-having-a-working-remote-access-tunnel-make-its-clone-linux-or-wsl)
  * [Tunnel setup: On-demand remote access (Linux or WSL)](#tunnel-setup-on-demand-remote-access-linux-or-wsl)
  * [Tunnel setup: Multi-channel on-demand remote access (Linux or WSL)](#tunnel-setup-multi-channel-on-demand-remote-access-linux-or-wsl)
  * [System setup: Tunnel autostart upon boot (Linux)](#system-setup-tunnel-autostart-upon-boot-linux)
    * [For the remote access script (`ra`)](#for-the-remote-access-script-ra)
    * [For the on-demand monitor script (`ra-mon`)](#for-the-on-demand-monitor-script-ra-mon)
    * [For the multi-channel on-demand monitor script (`raduo-mon`)](#for-the-multi-channel-on-demand-monitor-script-raduo-mon)
    * [Disabling the autostart](#disabling-the-autostart)
  * [System setup: Tunnel autostart upon boot (WSL)](#system-setup-tunnel-autostart-upon-boot-wsl)
    * [For the remote access script (`ra`)](#for-the-remote-access-script-ra-1)
    * [For the on-demand monitor script (`ra-mon`)](#for-the-on-demand-monitor-script-ra-mon-1)
    * [For the multi-channel on-demand monitor script (`raduo-mon`)](#for-the-multi-channel-on-demand-monitor-script-raduo-mon-1)
    * [If `boot.command` already exists in `/etc/wsl.conf`](#if-bootcommand-already-exists-in-etcwslconf)
    * [Disabling the autostart](#disabling-the-autostart-1)
  * [System setup: Tunnel autostart upon boot (Cygwin)](#system-setup-tunnel-autostart-upon-boot-cygwin)
* [Miscellaneous](#miscellaneous)
  * [Compatibility notes (WSL)](#compatibility-notes-wsl)
  * [Compatibility notes (Cygwin)](#compatibility-notes-cygwin)
* [Copyright](#copyright)

## Overview

SSH tunneling (port forwarding) is a method of transporting arbitrary data over an encrypted SSH connection.
SSH tunnel reroutes your traffic through a remote server, like VPS or a dedicated server.
All your traffic, “proxied” through the tunnel, appears to be coming from the remote server instead of your local machine.
These feature of the SSH tunnels is used to encrypt legacy applications' traffic, implement VPNs (virtual private networks), access local (intranet) services through firewalls etc.

Most of the well-known SSH implementations for various platforms do a great job of creating one-off tunnels. The Internet is literally jammed with recipes like “create an SSH-based SOCKS proxy in 5 minutes to bypass firewall restrictions” or “create an SSH tunnel for Remote Desktop”. However, none of such “user-friendly” articles explain how to control and manage such tunnels, make them reliable and secure.

Tunkit originated as a set of scripts around <a href="https://linux.die.net/man/1/autossh" target="_blank">autossh</a> to help start and stop a few simple tunnels when booting the machine. Scenarios were gradually added, and with them, opportunities. By setting up various tunnels again and again in different environments, I kept making the solution more flexible, but at the same time simpler and more reliable.

As a result, you get what you see — an “assebly kit” to create a production-grade tunnel setup for almost any task in just minutes, guided by precise step-by-step instructions from this README.

[:top:](#the-ssh-tunnel-kit)

## Created using Procdown

This README file was composed using <a href="https://github.com/dadooda/procdown" target="_blank">Procdown</a>, the tool to write and maintain multi-page Markdown documents with a structure and a lot of internal links.

[:top:](#the-ssh-tunnel-kit)

## Quick start

These **<a name="basic-steps">basic steps</a>** must be completed for any of the scenarios listed below:

1. Complete the steps of [“Server setup: SSH”](#server-setup-ssh).
2. Complete the steps of [“Server setup: User and key”](#server-setup-user-and-key).
3. Complete the steps of “Client setup”: :game_die:[Linux or WSL](#client-setup-linux-or-wsl), :game_die:[Cygwin](#client-setup-cygwin).

A few typical scenarios follow.

### Set up SOCKS proxy to bypass sites blocking

1. Complete the [basic steps](#basic-steps).
2. Set up the [SOCKS tunnel](#tunnel-setup-socks-linux-wsl-or-cygwin).
3. Set up service autostart: :game_die:[Linux](#system-setup-tunnel-autostart-upon-boot-linux), :game_die:[WSL](#system-setup-tunnel-autostart-upon-boot-wsl), :game_die:[Cygwin](#system-setup-tunnel-autostart-upon-boot-cygwin).

[:top:](#the-ssh-tunnel-kit)

### Set up direct SSH access to a Linux server running on a virtual machine or in the cloud

1. Complete the [basic steps](#basic-steps).
2. Set up the [remote access tunnel](#tunnel-setup-remote-access-linux).
3. Optionally, set up the [service autostart](#for-the-remote-access-script-ra).
4. Optionally, set up the [on-demand monitor](#tunnel-setup-on-demand-remote-access-linux-or-wsl).

[:top:](#the-ssh-tunnel-kit)

### Set up Remote Desktop (RDP) or VNC access to my Windows machine

1. Complete the [basic steps](#basic-steps).
2. Set up the [remote access tunnel](#tunnel-setup-remote-access-wsl).
3. Optionally, set up the [service autostart](#for-the-remote-access-script-ra-1).
4. Optionally, set up the [on-demand monitor](#tunnel-setup-on-demand-remote-access-linux-or-wsl).

[:top:](#the-ssh-tunnel-kit)

### Set up the home server or NAS to build multiple tunnels to other machines on my local network

1. Complete the [basic steps](#basic-steps).
2. On the server, set up multiple remote access tunnels (:game_die:[Linux](#tunnel-setup-remote-access-linux), :game_die:[WSL](#tunnel-setup-remote-access-wsl)) to other machines/services on the local network.
3. Set up the [multi-channel on-demand monitor](#tunnel-setup-multi-channel-on-demand-remote-access-linux-or-wsl).
4. Optionally, set up the service autostart: :game_die:[Linux](#for-the-multi-channel-on-demand-monitor-script-raduo-mon), :game_die:[WSL](#for-the-multi-channel-on-demand-monitor-script-raduo-mon-1).

[:top:](#the-ssh-tunnel-kit)

## Step-by-step setup

### Server setup: SSH

Pre-requisites:

1. The gateway server, `ec2-13-34-43-202.compute-1.amazonaws.com`, runs a reasonably fresh popular Linux distribution, such as Ubuntu.
2. The SSH server running on `ec2-13-34-43-202.compute-1.amazonaws.com` is set up per up-to-date defaults.
3. User `joe` can `sudo` to change the Linux system settings.

With SSH, log into the gateway server, `ec2-13-34-43-202.compute-1.amazonaws.com`:

```
ssh joe@ec2-13-34-43-202.compute-1.amazonaws.com
```

> :bulb: *As of now, all commands are run on the gateway server, `ec2-13-34-43-202.compute-1.amazonaws.com`.*

Edit the SSH server configuration:

```
sudoedit /etc/ssh/sshd_config
```

Specify the `GatewayPorts` setting:

```
GatewayPorts clientspecified
```

Activate configuration changes:

```
sudo service ssh reload
```

Our SSH server should be good to go now.

[:top:](#the-ssh-tunnel-kit)

### Server setup: User and key

With SSH, log into the gateway server, `ec2-13-34-43-202.compute-1.amazonaws.com`:

```sh
ssh joe@ec2-13-34-43-202.compute-1.amazonaws.com
```

> :bulb: *As of now, all commands are run on the gateway server, `ec2-13-34-43-202.compute-1.amazonaws.com`.*

Add a non-interactive user, `joetun`:

```sh
sudo adduser --disabled-password --shell /usr/sbin/nologin --gecos "Joe's tunnel" joetun
```

<pre>
Adding user `joetun' ...
Adding new group `joetun' (1001) ...
Adding new user `joetun' (1001) with group `joetun' ...
Creating home directory `/home/joetun' ...
Copying files from `/etc/skel' ...
</pre>

Let's see what we've got so far:

```sh
grep joetun /etc/passwd
```

<pre>
joetun:x:1001:1001:Joe's tunnel,,,:/home/joetun:/usr/sbin/nologin
</pre>

Looks good. Now let's proceed with key generation:

```sh
mkdir -p /tmp/joetun-key &&
cd /tmp/joetun-key &&
ssh-keygen -t ed25519 -b 512 -N "" -C "Joe's tunnel" -f joetun.key

```

<pre>
Generating public/private ed25519 key pair.
Your identification has been saved in joetun.key
Your public key has been saved in joetun.key.pub
…
</pre>

> :bulb: *We've chosen `ed25519` as key type. For more information on key type selection,*
> *please consult <a href="https://goteleport.com/blog/comparing-ssh-keys/" target="_blank">Comparing SSH Keys - RSA, DSA, ECDSA, or EdDSA?</a> or similar articles.*

> :warning: *The generated private key, `joetun.key` hasn't got a passphrase.*
> *Make sure you don't use this key for anything but the tunnels.*

Now, **<a name="previously-saved-keys">copy</a> both `joetun.key` and `joetun.key.pub` from the remote server to a safe location.**

* If you're on Linux, use `scp`, e.g.:

    ```sh
    mkdir -p ~/saved-keys &&
    scp joe@ec2-13-34-43-202.compute-1.amazonaws.com:/tmp/joetun-key/joetun.key* ~/saved-keys

    ```

* If you're on Windows and you have <a href="https://www.putty.org" target="_blank">PuTTY</a> installed, use `pscp`, like this:

    ```
    mkdir %USERPROFILE%\saved-keys
    pscp joe@ec2-13-34-43-202.compute-1.amazonaws.com:/tmp/joetun-key/joetun.key* %USERPROFILE%\saved-keys

    ```

* If none of the above works for you, you can always default to saving the actual file contents.
  Since key files are made to be copy-paste friendly, just collect and store the exact `cat` command output.

    ```sh
    cat joetun.key.pub joetun.key
    ```

  <pre>
  ssh-ed25519 AAAAC3Nzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxov2DWA0z Joe's tunnel
  -----BEGIN OPENSSH PRIVATE KEY-----
  b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  DqXqkQQZ9af0ov2DWA0zAAAADEpvZSdzIHR1bm5lbAE=
  -----END OPENSSH PRIVATE KEY-----
  </pre>

Now let's set configure our newly created user, `joetun`, to use the SSH key authorization.
While still in `/tmp/joetun-key`, run the following commands:

```sh
sudo runuser -u joetun bash
cd &&
touch .hushlogin &&
mkdir -pm 700 .ssh &&
touch .ssh/authorized_keys &&
chmod 600 .ssh/authorized_keys &&
cat /tmp/joetun-key/joetun.key.pub >> .ssh/authorized_keys &&
exit

```

> :bulb: *As you might have guessed, in the command sequence above, we became user `joetun` (via `runuser`),*
> *did a couple things on his behalf, and returned to our regular shell after `exit`.*

Now let's test if key authorization works for `joetun`. While still in `/tmp/joetun-key`, do a:

```sh
ssh -i joetun.key joetun@localhost
```

<pre>
The authenticity of host 'localhost (::1)' can't be established.
ECDSA key fingerprint is SHA256:4fyuZVMRxxxxxxxxxxxxxxxxxxxxxxxxxxxAJ6KR3bQ.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
</pre>

Type `yes` and press ENTER. Then you should see:

<pre>
This account is currently not available.
Connection to localhost closed.
</pre>

Hooray. Our tunnel user, `joetun` is good to go and we've got both private and public keys
copied to a safe location.

Let's clean up:

```sh
cd &&
rm -rf /tmp/joetun-key

```

[:top:](#the-ssh-tunnel-kit)

### Server setup: Nginx-based semaphore website

:memo: Pre-requisites:

1. You can create `A` or `CNAME` DNS records in an existing domain. In this example, the domain is `joescompany.com`.
2. You have a server on the Internet, running a modern Linux like Ubuntu, capable of running the web server software.
3. User `joe` can `sudo` to change the Linux system settings on the web server.

Creating the semaphore website is required for the on-demand scenarios such as [“Tunnel setup: On-demand remote access (Linux or WSL)”](#tunnel-setup-on-demand-remote-access-linux-or-wsl) and [“Tunnel setup: Multi-channel on-demand remote access (Linux or WSL)”](#tunnel-setup-multi-channel-on-demand-remote-access-linux-or-wsl).

When setting up the semaphore website, consider the following:

1. The site **must be HTTPS.** Today, many ISPs intercept the HTTP 404 responses and display their ads, force-rewriting the HTTP status to 200.
2. The semaphore URLs should respond with HTTP status 200 if the semaphore is up and 404 if it's down.
3. For reliability reasons, it's desirable to keep the semaphore website separate from any existing sites, on its own domain with its own SSL certificate.

In the DNS control panel of `joescompany.com`, create the record `secret` of type `A` or `CNAME`, pointing to the web server host. For example:

<pre>
secret IN A 45.56.76.21
</pre>

**Wait several minutes for the changes to take effect.** It usually takes 10-15 minutes up to an hour.

Let's check our new DNS record:

```sh
ping secret.joescompany.com
```

<pre>
PING li926-21.members.linode.com (45.56.76.21) 56(84) bytes of data.
64 bytes from li926-21.members.linode.com (45.56.76.21): icmp_seq=1 ttl=42 time=105 ms
64 bytes from li926-21.members.linode.com (45.56.76.21): icmp_seq=2 ttl=42 time=105 ms
…
</pre>

:+1: Great, the DNS name `secret.joescompany.com` responds.

Now let's set up a simple static website on Nginx.

```sh
ssh joe@secret.joescompany.com
```

> :bulb: *As of now, all commands are run on the web server, `secret.joescompany.com`.*

Install the automated SSL certificate generator, <a href="https://certbot.eff.org" target="_blank">Certbot</a>.

> :bulb: *You may use any other SSL provider and software. This example assumes you're using Certbot.*

Install the Nginx web server:

```sh
sudo apt install nginx
```

Create the new Nginx website configuration:

```sh
sudoedit /etc/nginx/sites-available/secret.joescompany.com
```

```
server {
  listen 443 ssl;
  server_name secret.joescompany.com;

  ssl_certificate /etc/letsencrypt/live/secret.joescompany.com/cert.pem;
  ssl_certificate_key /etc/letsencrypt/live/secret.joescompany.com/privkey.pem;

  access_log /var/log/nginx/secret.joescompany.com_access.log;
  error_log /var/log/nginx/secret.joescompany.com_error.log;

  location / {
    root /home/joe/www/secret.joescompany.com/html;
    index index.html;
  }
}
```

Enable our website:

```sh
cd /etc/nginx/sites-enabled &&
sudo ln -s ../sites-available/secret.joescompany.com

```

With Certbot, generate the certificate for `secret.joescompany.com`:

```sh
sudo certbot certonly --nginx
```

> :bulb: *In this short example, we don't cover the details of SSL certificate generation and setup.*
> *Please consult the relevant <a href="https://certbot.eff.org" target="_blank">Certbot pages</a>.*

Restart Nginx:

```sh
sudo service nginx reload
```

Create the dummy `index.html`:

```sh
mkdir -p ~/www/secret.joescompany.com/html &&
cd ~/www/secret.joescompany.com/html &&
echo "Go away" > index.html

```

Test it:

```sh
curl -D - -k https://secret.joescompany.com
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: …
Content-Type: text/html
Content-Length: 17
Last-Modified: …
Connection: keep-alive
ETag: …
Accept-Ranges: bytes

Go away
```

If you see this, then the semaphore website is working correctly.

[:top:](#the-ssh-tunnel-kit)

### Client setup (Linux or WSL)

:memo: Pre-requisites:

1. User `joe` can `sudo` to change the Linux system settings.
2. You've successfully completed the steps of [“Server setup: User and key”](#server-setup-user-and-key).

On your local machine, install the required packages (Ubuntu names):

```sh
sudo apt update &&
sudo apt install autossh curl git openssh-client

```

<a name="get-tunkit">Get Tunkit:</a>

```sh
cd &&
git clone https://github.com/dadooda/tunkit.git &&
cd tunkit

```

<pre>
Cloning into 'tunkit'...
remote: Enumerating objects: 510, done.
remote: Counting objects: 100% (145/145), done.
…
Resolving deltas: 100% (306/306), done.
</pre>

Copy the [previously saved private key](#previously-saved-keys), `joetun.key`, to Tunkit's `keys/`:

```sh
cp -nt keys ~/saved-keys/joetun.key &&
chmod 600 keys/joetun.key
```

[:top:](#the-ssh-tunnel-kit)

### Client setup (Cygwin)

Install the following packages:

1. From the “Devel” category: `git`.
2. From the “Net” category: `autossh`, `curl`, `openssh`.

Follow the steps of “Client setup (Linux or WSL)”, starting from [“get Tunkit”](#get-tunkit).

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: SOCKS (Linux, WSL or Cygwin)

:memo: Pre-requisites:

1. You've successfully completed the steps of “Client setup”: :game_die:[Linux or WSL](#client-setup-linux-or-wsl), :game_die:[Cygwin](#client-setup-cygwin).

Step into Tunkit's directory:

```sh
cd ~/tunkit
```

Create a config for script `socks` and edit it:

```sh
cp -n socks.d/conf.sh.example socks.d/conf.sh &&
${EDITOR} socks.d/conf.sh

```

```
C_HOST="ec2-13-34-43-202.compute-1.amazonaws.com"
C_USER="joetun"
C_KEY="joetun.key"
C_SOCKS_PORT="1080"
```

> :bulb: *Provide **your** gateway hostname in `C_HOST=` instead of `ec2-13-34-43-202.compute-1.amazonaws.com`.*

Discover the IP address of our gateway host, we'll use it a couple steps later:

```sh
ping ec2-13-34-43-202.compute-1.amazonaws.com
```

<pre>
PING ec2-13-34-43-202.compute-1.amazonaws.com (13.34.43.202) 56(84) bytes of data.
64 bytes from ec2-13-34-43-202.compute-1.amazonaws.com (13.34.43.202): icmp_seq=1 ttl=41 time=45.6 ms
…
</pre>

Start the tunnel, yet in debug mode:

```sh
DEBUG=! ./socks
```

<pre>
Running AutoSSH in the foreground
++ autossh -M 0 joetun@ec2-13-34-43-202.compute-1.amazonaws.com -D 0.0.0.0:1080 -i …
…
Authenticated to ec2-13-34-43-202.compute-1.amazonaws.com ([13.34.43.202]:22) using "publickey".
debug1: Local connections to 0.0.0.0:1080 forwarded to remote address socks:0
debug1: Local forwarding listening on 0.0.0.0 port 1080.
…
</pre>

> :warning: *There **should not** be messages like this:*
>
> <pre>
> bind [0.0.0.0]:1080: Address already in use
> channel_setup_fwd_listener_tcpip: cannot listen to port: 1080
> Could not request local forwarding.
> </pre>
>
> *If there are such messages, then port 1080 is being used by another process.*
> *In this case, stop `./socks` by pressing Ctrl+C, and then either find and stop the competing process,*
> *or configure to use a different port, for example, `C_PORT="8010"`.*
> *Then run `./socks` again with the command listed above.*

:+1: If all looks good and there are no explicit error messages, then the tunnel is up.

Keep `./socks` running where it is, **open a new terminal window** and move on.

Request an Internet page to discover our external IP address:

```sh
curl -s https://ipchicken.com | grep "^[0-9]*\..*<br>$"
```

<pre>
172.58.44.119&lt;br&gt;
</pre>

And now the same via the tunnel:

```sh
curl -x socks5://localhost:1080 -s https://ipchicken.com | grep "^[0-9]*\..*<br>$"
```

<pre>
13.34.43.202&lt;br&gt;
</pre>

What do we see? An external resource recognized our traffic originating from 13.34.43.202, which is our gateway host's IP address.
Which, in turn, means that our tunnel is working.

Return to the original `./socks` terminal and **stop the script** by pressing Ctrl+C.

Now, let's start the tunnel in the background:

```sh
./socks-ctl start
```

<pre>
Starting AutoSSH
AutoSSH is running, PID 11046
</pre>

Check it again with the `curl -x socks5://…` command written above.

:+1: Works? It means everything is OK. What we ended up with:

1. Script `socks` is running in the background, started with `./socks-ctl start`.
2. Local SOCKS server is listening on `localhost:1080`.
   Any Internet client (for example, the Web browser) can send its data through the gateway host by connecting to the local SOCKS server.

Next, if you want the tunnel to start automatically on boot, please complete the steps of “System setup: Tunnel autostart upon boot”: :game_die:[Linux](#system-setup-tunnel-autostart-upon-boot-linux), :game_die:[WSL](#system-setup-tunnel-autostart-upon-boot-wsl), :game_die:[Cygwin](#system-setup-tunnel-autostart-upon-boot-cygwin).

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: Remote access (Linux)

> :bulb: *In this example, the Linux server is running on a virtual machine.*
> *If your Linux server is hosted in a cloud, the steps are exactly the same.*

> :bulb: *In this example, we'll build a tunnel to an SSH daemon running inside our Linux machine.*
> *To build a tunnel to another service, use a different local port number instead of 22.*

:memo: Pre-requisites:

1. You've successfully completed the steps of [“Client setup (Linux or WSL)”](#client-setup-linux-or-wsl).

Step into Tunkit's directory:

```sh
cd ~/tunkit
```

Create a config for script `ra` and edit it:

```sh
cp -n ra.d/conf.sh.example ra.d/conf.sh &&
${EDITOR} ra.d/conf.sh

```

<a name="ra-config-linux">The configuration,</a> `ra.d/conf.sh`, looks like this:

```
C_HOST="ec2-13-34-43-202.compute-1.amazonaws.com"
C_USER="joetun"
C_KEY="joetun.key"
C_R_PORT="50022"

C_L_HOST="127.0.0.1"
C_L_PORT="22"
```

> :bulb: *Provide **your** gateway hostname in `C_HOST=` instead of `ec2-13-34-43-202.compute-1.amazonaws.com`.*

> :bulb: *If you build the tunnel to another machine on the local network, provide its local IP address in `C_L_HOST=`.*

Start the tunnel, yet in debug mode:

```sh
DEBUG=! ./ra
```

<pre>
Running AutoSSH in the foreground
++ autossh -M 0 joetun@ec2-13-34-43-202.compute-1.amazonaws.com -R 0.0.0.0:50022:127.0.0.1:22 -i …
…
Authenticated to ec2-13-34-43-202.compute-1.amazonaws.com ([13.34.43.202]:22) using "publickey".
…
debug1: Remote connections from 0.0.0.0:50022 forwarded to local address 127.0.0.1:22
…
debug1: remote forward success for: listen 0.0.0.0:50022, connect 127.0.0.1:22
…
</pre>

:+1: If all looks good and there are no explicit error messages, then the tunnel is up.

Keep `./ra` running, **open a new terminal window** and move on.

With a regular SSH client, connect to the public (listening) end of the tunnel. Once asked to confirm the host key authenticity, enter `yes`:

```sh
ssh joe@ec2-13-34-43-202.compute-1.amazonaws.com -p 50022
```

<pre>
joe@linuxvm:~$
</pre>

If you see this prompt, congratulations — you've just connected to your Linux VM via the tunnel.

Return to the original `./ra` terminal and **stop the script** by pressing Ctrl+C.

Now, let's start the tunnel in the background:

```sh
./ra-ctl start
```

<pre>
Starting AutoSSH
AutoSSH is running, PID 2337
</pre>

Check it again with the `ssh …` command written above.

:+1: Works? It means everything is OK. What we ended up with:

1. Script `ra` is running in the background, started with `./ra-ctl start`.
2. The public (listening) end of the tunnel is deployed at `ec2-13-34-43-202.compute-1.amazonaws.com:50022`.
  Anyone knowing the IP:port pair can connect, as long as the tunnel is up.

Next, if you want the tunnel to start automatically on boot, please complete [these steps](#system-setup-tunnel-autostart-upon-boot-linux).

Or, if you want to boost the tunnel security and set it up to start on demand, please complete [these steps](#tunnel-setup-on-demand-remote-access-linux-or-wsl).

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: Remote access (WSL)

:memo: Pre-requisites:

1. Your version of Windows <a href="https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-supported-config" target="_blank">supports connections to it</a> with Remote Desktop.
2. You have <a href="https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-allow-access" target="_blank">enabled Remote Desktop</a> in your Windows system.
3. You have another machine with a Remote Desktop client from which you can connect over the tunnel to test it.
4. You've successfully completed the steps of [“Client setup (Linux or WSL)”](#client-setup-linux-or-wsl).
5. You have successfully connected to your PC with a Remote Desktop client over the LAN.

> :bulb: *Some Windows versions, such as Home, don't allow incoming Remote Desktop connections.*
> *A firewall or an antivirus may also intervene.*
> *Please don't ignore pre-requisites 3 to 5. If you skip them, you risk wasting your time on unnecessary debugging.*

Open the WSL terminal. Step into Tunkit's directory:

```sh
cd ~/tunkit
```

Create a config for script `ra` and edit it:

```sh
cp -n ra.d/conf.sh.example ra.d/conf.sh &&
${EDITOR} ra.d/conf.sh

```

<a name="ra-config-wsl">The configuration,</a> `ra.d/conf.sh`, looks like this:

```
set -e

C_HOST="ec2-13-34-43-202.compute-1.amazonaws.com"
C_USER="joetun"
C_KEY="joetun.key"
C_R_PORT="50389"

C_L_HOST=`ip route show default | awk '{ print $3 }'`
C_L_PORT="3389"

set +e
```

> :bulb: *Provide **your** gateway hostname in `C_HOST=` instead of `ec2-13-34-43-202.compute-1.amazonaws.com`.*

> :bulb: *If you build the tunnel to another machine on the local network, provide its local IP address in `C_L_HOST=`.*

Start the tunnel, yet in debug mode:

```sh
DEBUG=! ./ra
```

<pre>
Running AutoSSH in the foreground
++ autossh -M 0 joetun@ec2-13-34-43-202.compute-1.amazonaws.com -R 0.0.0.0:50389:172.17.80.1:3389 -i …
…
Authenticated to ec2-13-34-43-202.compute-1.amazonaws.com ([13.34.43.202]:22) using "publickey".
…
debug1: Remote connections from 0.0.0.0:50389 forwarded to local address 172.17.80.1:3389
…
debug1: remote forward success for: listen 0.0.0.0:50389, connect 172.17.80.1:3389
…
</pre>

:+1: If all looks good and there are no explicit error messages, then the tunnel is up.

Keep `./ra` running. **From another machine,** with a Remote Desktop client, connect to the public (listening) end of the tunnel, `ec2-13-34-43-202.compute-1.amazonaws.com:50389`.

If you can see your PC in a Remote Desktop session, congratulations.

Return to the original `./ra` terminal and **stop the script** by pressing Ctrl+C.

Now, let's start the tunnel in the background:

```sh
./ra-ctl start
```

<pre>
Starting AutoSSH
AutoSSH is running, PID 5347
</pre>

Check the connection from another machine again.

:+1: Works? It means everything is OK. What we ended up with:

1. Script `ra` is running in the background, started with `./ra-ctl start`.
2. The public (listening) end of the tunnel is deployed at `ec2-13-34-43-202.compute-1.amazonaws.com:50389`.
  Anyone knowing the IP:port pair can connect, as long as the tunnel is up.

Next, if you want the tunnel to start automatically on boot, please complete [these steps](#system-setup-tunnel-autostart-upon-boot-wsl).

Or, if you want to boost the tunnel security and set it up to start on demand, please complete [these steps](#tunnel-setup-on-demand-remote-access-linux-or-wsl).

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: Having a working remote access tunnel, make its clone (Linux or WSL)

:memo: Pre-requisites:

1. You've successfully completed the steps of “Tunnel setup: Remote access”: :game_die:[Linux](#tunnel-setup-remote-access-linux), :game_die:[WSL](#tunnel-setup-remote-access-wsl).

Let's say we have more than one gateway server on the Internet, and we want to utilize all of the servers to duplicate our remote access tunnels.
The `ra` tunnel is already set up, now we want to build the `xyz` tunnel according to the same model.

Step into Tunkit's directory:

```sh
cd ~/tunkit
```

Create a set of directories and files:

```sh
mkdir xyz.d xyz-mon.d &&
ln -s ra xyz &&
for P in ctl mon mon-ctl; do cp -d ra-${P} xyz-${P}; done

```

Create a config for script `xyz` and edit it:

```sh
cp -nt xyz.d ra.d/conf.sh &&
${EDITOR} xyz.d/conf.sh

```

Provide the necessary settings in `xyz.d/conf.sh` as described in the main chapter “Tunnel setup: Remote access” (:game_die:[Linux](#ra-config-linux), :game_die:[WSL](#ra-config-wsl)). Set up, debug and start the tunnel.

What we ended up with:

1. `xyz` script is ready to use, controlled by `./xyz-ctl` script.
2. To set up the on-demand monitor, follow the steps of [“Tunnel setup: On-demand remote access (Linux or WSL)”](#tunnel-setup-on-demand-remote-access-linux-or-wsl), using `xyz-mon` instead of `ra-mon`.

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: On-demand remote access (Linux or WSL)

:memo: Pre-requisites:

1. You've successfully completed the steps of [“Server setup: Nginx-based semaphore website”](#server-setup-nginx-based-semaphore-website).
2. You've successfully completed the steps of “Tunnel setup: Remote access”: :game_die:[Linux](#tunnel-setup-remote-access-linux), :game_die:[WSL](#tunnel-setup-remote-access-wsl).

Let's say we've built a remote access tunnel (:game_die:[Linux](#tunnel-setup-remote-access-linux), :game_die:[WSL](#tunnel-setup-remote-access-wsl)),
configured its autostart (:game_die:[Linux](#for-the-remote-access-script-ra), :game_die:[WSL](#for-the-remote-access-script-ra-1)) and are ejoying it.
But what about security, especially when it comes to full control of the machine over SSH or RDP?
What if the IP:port combination pointing to our internal, *and therefore obviously less protected* machine, gets somehow known to an attacker?
What if he guesses or otherwise finds out our simple login and password?

Again, the very fact that we at some point decide to provide access to an internal resource through a tunnel *implies a generally lower level of security.*

Most likely, the resource to which we provide access (most often to ourselves) has long been used exclusively on our local network,
and passwords, purely historically, are assigned simple, if assigned at all.

To tackle all this, Tunkit makes it possible to significantly raise the level of security of the remote access tunnels by letting us enable and disable them on demand.

> :warning: *If you're setting up a tunnel for permanent production access to critical infrastructure, such as your main computer at work,*
> *following the steps of this scenario **is highly desirable from a security point of view.***

Well, let's get started.

If you've previously set up tunnel autostart (:game_die:[Linux](#for-the-remote-access-script-ra), :game_die:[WSL](#for-the-remote-access-script-ra-1)), now it's time to reliably disable it: :game_die:[Linux](#disabling-the-autostart), :game_die:[WSL](#disabling-the-autostart-1).

We've already [set up the semaphore website](#server-setup-nginx-based-semaphore-website) `secret.joescompany.com` earlier. Let's create a semaphore on it, and see if it works.

> :warning: ***Don't ignore this step,** no matter how simple it may seem to you. If you are setting up a tunnel for production use,*
> *the semaphore must be bulletproof. Whoever controls the semaphore controls the tunnel.*

Bring the semaphore up by creating an empty website page:

```sh
ssh joe@secret.joescompany.com "cd ~/www/secret.joescompany.com/html && mkdir -p powah && touch powah/uno"
```

Check from the outside:

```sh
curl -fk https://secret.joescompany.com/powah/uno; echo code:$?
```

<pre>
code:0
</pre>

:+1: Great. Now bring the semaphore down:

```sh
ssh joe@secret.joescompany.com "rm ~/www/secret.joescompany.com/html/powah/uno"
```

Check again:

```sh
curl -fk https://secret.joescompany.com/powah/uno; echo code:$?
```

<pre>
curl: (22) The requested URL returned error: 404 Not Found
code:22
</pre>

Now the semaphore is down, just as we wanted it to be.

Now let's get to the tunnel monitor setup.

> :bulb: *The **tunnel monitor** is a script, which watches the semaphore on the Internet, and*
> *starts a pre-configured tunnel once the semaphore is up, or stops the tunnel once the semaphore is down.*

> :bulb: *The relationship between the monitor script and the tunnel script is defined by their filenames.*
> *Thus, `ra-mon` is connected with `ra`. Likewise, `xyz-mon` will be connected with `xyz`, and so forth.*

Step into Tunkit's directory:

```sh
cd ~/tunkit
```

Create a config for script `ra-mon` and edit it:

```sh
cp -n ra-mon.d/conf.sh.example ra-mon.d/conf.sh &&
${EDITOR} ra-mon.d/conf.sh

```

```
# Semaphore. Must be HTTPS.
C_SEMA_URL="https://secret.joescompany.com/powah/uno"
```

Start the monitor script:

```sh
./ra-mon-ctl start
```

<pre>
Monitor is running, PID 3298
</pre>

**In a new terminal window,** watch the live monitor log:

```sh
cd ~/tunkit &&
./ra-mon-ctl log

```

Using a free terminal, bring the semaphore up:

```sh
ssh joe@secret.joescompany.com "cd ~/www/secret.joescompany.com/html && mkdir -p powah && touch powah/uno"
```

The monitor log should grow with messages like these:

<pre>
[2023-01-26 19:01:30] Semaphore is up, triggering START
Starting AutoSSH
AutoSSH is running, PID 32823
</pre>

Additionally, the control script should indicate that the tunnel is running:

```sh
./ra-ctl status
```

<pre>
AutoSSH is running, PID 32823
</pre>

Bring the semaphore down:

```sh
ssh joe@secret.joescompany.com "rm ~/www/secret.joescompany.com/html/powah/uno"
```

The monitor log should grow with messages like these:

<pre>
[2023-01-26 19:07:00] Semaphore is down, triggering STOP
Stopping AutoSSH, PID 32823
AutoSSH is not running
</pre>

:+1: If all is as above, then **the semaphore and the monitor script are working correctly.**

> :bulb: *If for some reason the monitor script behaves inappropriately, you can run it in the foreground in debug mode:*
>
> ```sh
> DEBUG=! ./ra-mon
> ```

What we ended up with:

1. The `ra` tunnel is now controlled by the monitor, which watches the semaphore on the Internet.
2. Manual control via `./ra-ctl start` and `./ra-ctl stop` is now pointless.
   For example, if the semaphore is down and you do a `./ra-ctl start`, the monitor will instantly stop the tunnel.
   The opposite is also true: as long as the semaphore is up, the `ra` tunnel will be started by the monitor, even if you stop it by hand.

Next, if you want the monitor to start automatically on boot, please complete these steps: :game_die:[Linux](#for-the-on-demand-monitor-script-ra-mon), :game_die:[WSL](#for-the-on-demand-monitor-script-ra-mon-1).

[:top:](#the-ssh-tunnel-kit)

### Tunnel setup: Multi-channel on-demand remote access (Linux or WSL)

:memo: Pre-requisites:

1. All pre-requisites of [“Tunnel setup: On-demand remote access (Linux or WSL)”](#tunnel-setup-on-demand-remote-access-linux-or-wsl).
2. You've successfully completed the steps of “Tunnel setup: Remote access” (:game_die:[Linux](#tunnel-setup-remote-access-linux), :game_die:[WSL](#tunnel-setup-remote-access-wsl)) to
  produce two independently working tunnels: `ra1` and `ra2`.

The [main chapter](#tunnel-setup-on-demand-remote-access-linux-or-wsl) explains what's an on-demand monitor, when it's useful, and how to set it up for a single tunnel.
If you have't read it, please do.

Here we describe a scenario where multiple tunnels are governed by a single semaphore.
Of course, we can start multiple monitors (`ra1-mon`, `ra2-mon`, …) that watch the same semaphore,
but that'll be wasteful in terms of manageability, traffic, and the number of running processes.

Therefore, Tunkit includes a `raduo-mon` monitor, which we describe here.
This monitor watches the semaphore and controls multiple tunnels configured in the body of the script.

By default, these are `ra1` and `ra2`, but the set can be extended by a few simple changes in `raduo-mon`:

<pre>
#--------------------------------------- Configuration

ALLSEQ=`seq 1 2`
c1() { ./ra1-ctl "$@" 2>&1 | ppipe "ra1-ctl: "; }
c2() { ./ra2-ctl "$@" 2>&1 | ppipe "ra2-ctl: "; }
# Add `c3()` and edit `ALLSEQ` to control yet another tunnel.
</pre>

Some of my servers control 8-10 tunnels with `raduo-mon`.

The steps to do the setup are the same as in the [main chapter](#tunnel-setup-on-demand-remote-access-linux-or-wsl), except for the following differences:

* The on-demand monitor filename is `raduo-mon`.
* The control script filename is `raduo-mon-ctl`.
* The data directory name is `raduo-mon.d/`.

Next, if you want the monitor to start automatically on boot, please complete these steps: :game_die:[Linux](#for-the-multi-channel-on-demand-monitor-script-raduo-mon), :game_die:[WSL](#for-the-multi-channel-on-demand-monitor-script-raduo-mon-1).

[:top:](#the-ssh-tunnel-kit)

### System setup: Tunnel autostart upon boot (Linux)

> :bulb: *Here we describe a common scenario for configuring a service to start automatically upon boot in a modern Linux system.*
> *We use the [SOCKS tunnel](#tunnel-setup-socks-linux-wsl-or-cygwin) as an example.*

:memo: Pre-requisites:

1. Our Linux system uses `systemd` to manage boot-time services startup.
2. User `joe` has set up the [SOCKS tunnel](#tunnel-setup-socks-linux-wsl-or-cygwin) properly.

In `joe`'s home directory, create a unit file for the new `systemd` service:

```sh
cd &&
mkdir -p .config/systemd/user &&
${EDITOR} .config/systemd/user/tunkit-socks.service

```

```
[Unit]
Description=Tunkit SOCKS

[Service]
Type=forking
Restart=on-failure
PIDFile=%h/tunkit/socks.d/autossh.pid
ExecStart=-%h/tunkit/socks-ctl start
ExecStop=%h/tunkit/socks-ctl stop

[Install]
WantedBy=default.target
```

Enable the service:

```sh
systemctl --user enable tunkit-socks
```

<pre>
Created symlink /home/joe/.config/systemd/user/default.target.wants/tunkit-socks.service → /home/joe/.config/systemd/user/tunkit-socks.service.
</pre>

**Reboot.** After it, check if the service is running:

```sh
systemctl --user status tunkit-socks
```

<pre>
● tunkit-socks.service - Tunkit SOCKS
     Loaded: loaded (/home/joe/.config/systemd/user/tunkit-socks.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2023-01-18 17:11:59 UTC; 7min ago
    Process: 1280 ExecStart=/home/joe/tunkit/socks-ctl start (code=exited, status=0/SUCCESS)
   Main PID: 1337 (autossh)
     CGroup: /user.slice/user-1002.slice/user@1002.service/tunkit-socks.service
             ├─1337 /usr/lib/autossh/autossh -M 0    joetun@ec2-13-34-43-202.compute-1.amazonaws.com -D 0.0.0.0:1080 -i /home/joe/tunkit>
             └─1339 /usr/bin/ssh -D 0.0.0.0:1080 -i /home/joe/tunkit/keys/joetun.key -N -o StrictHostKeyCheck>

Jan 18 17:11:58 joehost systemd[1274]: Starting Tunkit SOCKS...
Jan 18 17:11:59 joehost socks-ctl[1321]: Starting AutoSSH
Jan 18 17:11:59 joehost socks-ctl[1280]: AutoSSH is running, PID 1337
Jan 18 17:11:59 joehost systemd[1274]: Started Tunkit SOCKS.
</pre>

Just in case, check if manual restart works:

```sh
systemctl --user restart tunkit-socks &&
systemctl --user status tunkit-socks
```

If everything looks normal, then the service is working.

> :bulb: *If something doesn't work, try these diagnostic commands:*
> 
> ```sh
> journalctl --user
> ```
> 
> ```sh
> journalctl --user -u tunkit-socks
> ```
> 
> ```sh
> systemctl --user --failed
> ```

In addition to the above, I highly recommend reading this article at DigitalOcean:
<a href="https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files" target="_blank">Understanding Systemd Units and Unit Files</a>
It's a very detailed and thoughtful material explaining how `systemd` units work.

[:top:](#the-ssh-tunnel-kit)

#### For the remote access script (`ra`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-linux), except for the following differences:

* The unit file for `systemd` is called `.config/systemd/user/tunkit-ra.service` and has the following content:

    ```
    [Unit]
    Description=Tunkit RA

    [Service]
    Type=forking
    Restart=on-failure
    PIDFile=%h/tunkit/ra.d/autossh.pid
    ExecStart=-%h/tunkit/ra-ctl start
    ExecStop=%h/tunkit/ra-ctl stop

    [Install]
    WantedBy=default.target
    ```

* The command to enable the service is:

    ```sh
    systemctl --user enable tunkit-ra
    ```

* The command to check the service **after reboot** is:

    ```sh
    systemctl --user status tunkit-ra
    ```

[:top:](#the-ssh-tunnel-kit)

#### For the on-demand monitor script (`ra-mon`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-linux), except for the following differences:

* The unit file for `systemd` is called `.config/systemd/user/tunkit-ra-mon.service` and has the following content:

    ```
    [Unit]
    Description=Tunkit RA monitor

    [Service]
    Type=forking
    Restart=on-failure
    PIDFile=%h/tunkit/ra-mon.d/monitor.pid
    ExecStart=-%h/tunkit/ra-mon-ctl start
    ExecStop=%h/tunkit/ra-mon-ctl stop

    [Install]
    WantedBy=default.target
    ```

* The command to enable the service is:

    ```sh
    systemctl --user enable tunkit-ra-mon
    ```

* The command to check the service **after reboot** is:

    ```sh
    systemctl --user status tunkit-ra-mon
    ```

[:top:](#the-ssh-tunnel-kit)

#### For the multi-channel on-demand monitor script (`raduo-mon`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-linux), except for the following differences:

* The unit file for `systemd` is called `.config/systemd/user/tunkit-raduo-mon.service` and has the following content:

    ```
    [Unit]
    Description=Tunkit RAduo monitor

    [Service]
    Type=forking
    Restart=on-failure
    PIDFile=%h/tunkit/raduo-mon.d/monitor.pid
    ExecStart=-%h/tunkit/raduo-mon-ctl start
    ExecStop=%h/tunkit/raduo-mon-ctl stop

    [Install]
    WantedBy=default.target
    ```

* The command to enable the service is:

    ```sh
    systemctl --user enable tunkit-raduo-mon
    ```

* The command to check the service **after reboot** is:

    ```sh
    systemctl --user status tunkit-raduo-mon
    ```

[:top:](#the-ssh-tunnel-kit)

#### Disabling the autostart

Depending on which `systemd` unit file you've created earlier, run the commands:

* For the `socks` script:

    ```
    systemctl --user stop tunkit-socks &&
    systemctl --user disable tunkit-socks &&
    systemctl --user status tunkit-socks

    ```

* For the `ra` script:

    ```
    systemctl --user stop tunkit-ra &&
    systemctl --user disable tunkit-ra &&
    systemctl --user status tunkit-ra

    ```

* For the `ra-mon` script:

    ```
    systemctl --user stop tunkit-ra-mon &&
    systemctl --user disable tunkit-ra-mon &&
    systemctl --user status tunkit-ra-mon

    ```

* For the `raduo-mon` script:

    ```
    systemctl --user stop tunkit-raduo-mon &&
    systemctl --user disable tunkit-raduo-mon &&
    systemctl --user status tunkit-raduo-mon

    ```

[:top:](#the-ssh-tunnel-kit)

### System setup: Tunnel autostart upon boot (WSL)

> :bulb: *Here we describe a common scenario for configuring a service to start automatically upon boot in a Linux system running under WSL.*
> *We use the [SOCKS tunnel](#tunnel-setup-socks-linux-wsl-or-cygwin) as an example.*

:memo: Pre-requisites:

1. User `joe` has set up the [SOCKS tunnel](#tunnel-setup-socks-linux-wsl-or-cygwin) properly.
2. User `joe` can `sudo` to change the Linux system settings.

Edit or create `/etc/wsl.conf`:

```sh
sudoedit /etc/wsl.conf
```

Find or create the `[boot]` section and add the `command` setting to it. If there are other sections and settings, *leave them as they are.*

```
[boot]
command = "sudo -u joe ~joe/tunkit/socks-ctl start"
```

If `boot.command` already exists, [follow these steps](#if-bootcommand-already-exists-in-etcwslconf) to handle it.

Restart the WSL instance. **In the classic Command Prompt** do a:

```
wsl --shutdown & wsl echo hey
```

> :bulb: *If you're in PowerShell, do a:*
>
> ```
> wsl --shutdown ; wsl echo hey
> ```

The VM running Linux will stop and then start again. After a few seconds (up to 10 seconds on slow machines) you'll see `hey`.

Let's check if our service has started. **Open a WSL terminal** and run:

```
~joe/tunkit/socks-ctl status
```

<pre>
AutoSSH is running, PID 49
</pre>

If everything looks normal, then the service is working.

[:top:](#the-ssh-tunnel-kit)

#### For the remote access script (`ra`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-wsl), except for the following differences:

* The `boot.command` setting in `/etc/wsl.conf` is:

    ```
    command = "sudo -u joe ~joe/tunkit/ra-ctl start"
    ```

  If `boot.command` already exists, [follow these steps](#if-bootcommand-already-exists-in-etcwslconf) to handle it.

* The command to check the service **after WSL restart** is:

    ```
    ~joe/tunkit/ra-ctl status
    ```

[:top:](#the-ssh-tunnel-kit)

#### For the on-demand monitor script (`ra-mon`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-wsl), except for the following differences:

* The `boot.command` setting in `/etc/wsl.conf` is:

    ```
    command = "sudo -u joe ~joe/tunkit/ra-mon-ctl start"
    ```

  If `boot.command` already exists, [follow these steps](#if-bootcommand-already-exists-in-etcwslconf) to handle it.

* The command to check the service **after WSL restart** is:

    ```
    ~joe/tunkit/ra-mon-ctl status
    ```

[:top:](#the-ssh-tunnel-kit)

#### For the multi-channel on-demand monitor script (`raduo-mon`)

The steps to do the setup are the same as in the [main chapter](#system-setup-tunnel-autostart-upon-boot-wsl), except for the following differences:

* The `boot.command` setting in `/etc/wsl.conf` is:

    ```
    command = "sudo -u joe ~joe/tunkit/ra-mon-ctl start"
    ```

  If `boot.command` already exists, [follow these steps](#if-bootcommand-already-exists-in-etcwslconf) to handle it.

* The command to check the service **after WSL restart** is:

    ```
    ~joe/tunkit/ra-mon-ctl status
    ```

[:top:](#the-ssh-tunnel-kit)

#### If `boot.command` already exists in `/etc/wsl.conf`

`/etc/wsl.conf` is a configuration file with a primitive syntax. Each setting can only be present once, and only the last setting has effect.

Our `boot.command` is no exception. What if we need to execute more than one command, and `boot.command` is already there?

For example, we're about to add `ra-ctl start`, but `command` is already set:

<pre>
[boot]
command = "sudo -u joe ~joe/tunkit/socks-ctl start"
</pre>

The answer is simple. We need to *carefully append* (“chain”) the new command to the existing one via `&&` or `;`. For example:

```
[boot]
command = "sudo -u joe ~joe/tunkit/socks-ctl start && sudo -u joe ~joe/tunkit/ra-ctl start"
#command = "sudo -u joe ~joe/tunkit/socks-ctl start"
```

> :warning: *I highly recommend **not overwrite, but comment out** the existing `command =` line so that in case of an error you can quickly restore a working setup.*
> *Remember, you're editing a file with primitive syntax and making a mistake is very easy.*

You can learn more about chaining operators `&&` and `;` in <a href="https://www.geeksforgeeks.org/difference-between-chaining-operators-in-linux/" target="_blank">this article on GeeksforGeeks</a> or another Unix shell manual.

[:top:](#the-ssh-tunnel-kit)

#### Disabling the autostart

Edit `/etc/wsl.conf`:

```sh
sudoedit /etc/wsl.conf
```

Locate the `[boot]` section and comment out the `command =` line:

```
[boot]
#command = "sudo -u joe ~joe/tunkit/socks-ctl start"
```

Next time you boot WSL, the tunnel will not start.

[:top:](#the-ssh-tunnel-kit)

### System setup: Tunnel autostart upon boot (Cygwin)

Activate the “Run” dialog (Win+R). In a dialog that appears, input `shell:startup` and press ENTER.

In the window that appears, create a new shortcut. Input the following item location:

```
c:\cygwin64\bin\bash.exe -l -c "~/tunkit/socks-ctl start"
```

> :bulb: *If you have installed Cygwin to a path different from `c:\cygwin64`, adjust the above value accordingly.*

Input shortcut name, e.g. `Tunkit SOCKS`. Confirm by clicking “OK”.

Next time you log into your machine, the SOCKS tunnel will automatically start in the background.

> :warning: *The steps above assume that the tunnel is started when the user logs on interactively.*
> _**This method will not work** the remote access scenarios. Some aspects of this are partially covered in [“Compatibility notes (Cygwin)”](#compatibility-notes-cygwin)._

[:top:](#the-ssh-tunnel-kit)

## Miscellaneous

### Compatibility notes (WSL)

Throughout the document, the term “WSL” refers to WSL 2. I've never set up Tunkit under WSL 1, although I think it'll work under this version, too.

[:top:](#the-ssh-tunnel-kit)

### Compatibility notes (Cygwin)

I've been successfully using Tunkit under Cygwin, but over time I've come across a number of aspects, mostly negative ones,
which you'll have to consider if you want to set up durable tunnels for production use.

Let's say, if you need to set a “quick and dirty” tunnel for one-time use, Cygwin suits quite well.

But if you want to set up advanced production scenarios like
[“Tunnel setup: Remote access”](#tunnel-setup-remote-access-wsl), [“Tunnel setup: On-demand remote access”](#tunnel-setup-on-demand-remote-access-linux-or-wsl) or [“Tunnel setup: Multi-channel on-demand remote access”](#tunnel-setup-multi-channel-on-demand-remote-access-linux-or-wsl),
I'd advise you **to take a minute and install WSL.**
Especially considering that the most recent WSL editions, especially under Windows 11, <a href="https://learn.microsoft.com/en-us/windows/wsl/install " target="_blank">can be installed in just minutes</a>.
If some time ago Cygwin used to have the advantage of a relatively simpler and faster installation, now this advantage is gone.

I summarize the known Cygwin compatibility aspects in the list below. Items are marked 🍏, 🍊 and 🍎, according to the nature of the aspect:

1. 🍏 Both `autossh` and `ssh` packages are very stable, although they may look slightly outdated by version number. **All works without any issues.**
2. 🍏 Tunnel autostart after interactive logon into the machine [is set up without any problems](#system-setup-tunnel-autostart-upon-boot-cygwin). **For a simple `socks` tunnel it works just fine.**
3. 🍊 **Difficulties were observed** trying to set up tunnel autostart without the interactive logon. I've used the Task Scheduler.
  The processes start, but they can't be controlled from the Cygwin shell, because they belong to another user.
  Also, some very specific non-default settings need to be provided if you want the task to stay alive.
1. 🍎 **Severe problems with the Windows Defender firewall were observed.** In order for the RDP tunnel *to the same machine* work, I had do completely disable the firewall. At the same time, if my machine was building a tunnel to another machine on the local network, everything worked fine.

Since I yet don't have reliable answers to the questions above, I refrain from detailed description of Cygwin setup steps, except for [the most basic SOCKS scenario](#tunnel-setup-socks-linux-wsl-or-cygwin).

[:top:](#the-ssh-tunnel-kit)

## Copyright

The product is free to use by everyone. Feedback of any kind is greatly appreciated.

— © 2021-2023 Alex Fortuna

