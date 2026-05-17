# Usage
`git clone` or upload this repo to your HidenCloud ARM64 instance. For "Server Type", choose "[SOFTWARE] Node.js".

Under "CONFIGURATION->Startup", set "Git Repo Address" to the URL of this repo (starts with "https://", set "Install Branch" to "main", and enable "Auto Update".

Set "Main file" to index.js and leave everything else on this page untouched (use defaults).

Go to "GENERAL->Console", click on "Start".

After the server state moves to Online, the console will be a bash shell.

# SSH
You can access the server instance via ssh.

The ssh server address and port the same as the server ingress.

The username should always be `container`.

Login with password is not supported, the setup only accepts key-based login.

To add pubkeys, see "Additional Arguments" under "CONFIGURATION->Startup". 

Pass your pubkey string using `-k` argument in "Additional Arguments", or specify an URL to the key file via `-u`.

# SSLH
SSLH demultiplexies the server TCP ingress. It listens on ${SERVER_PORT} and forwards SSH connections to the SSHD listening on port 22.

In addition, it forwards HTTP and HTTPS requests to 80 and 443, respectively. Other traffic is forwarded to port 8000.

# Utilities
1. `source prepare-env.sh` in the shell gives you access to some useful scripts and tools in the `tools` folder, like `nss-run` and `screen`.
2. `nss-run` runs a given command with UID and GID corrected.  
   For some reason, the default `/etc/passwd` and `/etc/group` contain wrong UID and GID for the current user "container". Several tools wont work without `nss-run`.
3. `screen` allows you to keep something running even after you quit the SSH session.  
   Start a new screen session with `screen`, and detach with `Ctrl+A, D`.
4. `apt-nonroot-install` let you install some APT packages without root.  
   __It does not automatically install required dependencies.__  
   To find out what dependencies a package needs , use `apt-check-deps.sh`.
