# Vault & Consul Enterprise Setup
=================================

## Architecture
![High level arch](architecture.png)

## Pre-req

- The project will be created under a Folder
- You will need a service account that can create projects and enable APIs. Here's the list of perms that I had on the folder
    ```
    Project Billing Manager
    Compute Admin
    Compute Network Admin
    Create Service Accounts
    Owner
    Storage Admin
    Viewer
    Project Creator
    ```
- You will need to put the credentials file of another service account that can create service accounts in `vault-config` dir.
- You will need to have HashiCorp binaries or rpm file, and change the variable `rpm_file` to the path of this file.
- Replace the ssh public key with your key in variable `ssh_key`.
- If you have auto-create-network flag off in your org, set `auto_create_network` variable to `true`. Seems like Tf [tries to delete](https://www.terraform.io/docs/providers/google/r/google_project.html#auto_create_network) a network that does not exist and errors out.

## Gotchas
- compute API takes time to get enabled, so TF might error out in the middle. Just do another apply ;)

## Steps

- deploy with tf
- [sshuttle](https://github.com/sshuttle) to your jump box to avoid using LB.
- Unseal your primary and secondary separately

    ```
    vault operator init -recovery-shares=1 -recovery-threshold=1
    vault status
    ```

- Login to consul primary and secondary servers and check health status

    ```
    http://consul-ip:8500
    ```

- Enable replication on primary

    ```
    vault login root-token
    vault write -f sys/replication/performance/primary/enable
    vault write sys/replication/performance/primary/secondary-token id=<id>
    ```

- On the secondary login and enable secondary replication, regenerate root token

    ```
    vault login root-token
    vault write sys/replication/performance/secondary/enable token=<token>
    vault operator generate-root -generate-otp
    vault operator generate-root -init -otp="xxxxxx"
    #Use unseal key from primary to generate root
    vault operator generate-root -otp="xxxxxx"
    vault operator generate-root -otp="xxxxxx" -decode=yyyyy
    ```

- Save root token from above ^
- ===== For some reason other two vault servers seal after this step, so restart vault. =====
- Export primary address and token

    ```
    export VAULT_ADDR=http://ip:8200
    export VAULT_TOKEN=xxxxx
    ```

- cd `vault-config`
- again tf apply to configre your Vault with GCP secret engine.
- try to read gcp service account keys

    ```
    vault read gcp/key/storage_admin
    ```

- Generate another root token. This should be fixed to a non-root token with the right policies.

    ```
    vault token create
    ```

- SSH to one of the vault servers to use consul-template. Generate config file for consul template.

    ```
    echo 'kill_signal = "SIGINT"
    log_level = "warn"

    vault {
      address = "http://10.11.0.51:8200"
      token = "generated-token"
      renew_token = false

    }' > config.hcl
    ```

- Generate your template file

    ```
    echo '{{ with secret "gcp/key/storage_admin" }}
    {{.Data.private_key_data}}
    {{ end }}' > in.tpl
    ```

- Run consul-template and watch new service account keys being created every 2 seconds

    ```
    while true; do consul-template -template "in.tpl:out.txt"  -config=./config.hcl -once > log 2>&1 ; sleep 2; done &
    watch cat out.txt
    ```