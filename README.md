Challenge link: https://roadmap.sh/projects/nodejs-service-deployment

# Challenge goals

The goal of this project is to practice setting up a CI/CD pipeline for a Node.js service using GitHub Actions.

# Prerequisites

Before deploying the website, ensure you have the following:

1. [HCP Terraform account](https://app.terraform.io/) - create an organization (e.g., "roadmap-sh") and generate an [API token](https://app.terraform.io/app/settings/tokens)
2. [Digital Ocean API token](https://cloud.digitalocean.com/account/api/tokens) required for managing cloud resources on DigitalOcean
3. SSH key pair - used by ansible and you to connect to the server
4. GitHub repo configured with secrets and variables, these can be set up quickly using the [`gh` cli tool](https://cli.github.com/)

   ```sh
   gh variable set DO_KEY_NAME -b <digitalocean keyname> # https://cloud.digitalocean.com/account/security

   gh secret set DIGITALOCEAN_API_TOKEN -b <digital ocean api token>
   gh secret set SSH_PRIV_KEY -b "$(cat <private key file path>)"
   gh secret set HCP_TERRAFORM_TOKEN -b <hcp terraform token>
   ```

# Running the pipelines

There are two pipelines set up. Both are activated manually, one is used to deploy the project the other one are used to clean up resources.

# Ansible role to deploy the app

First we use a **set_fact** module to extract repository name from the repository url, this could change for other users that fork this repo

```yaml
- name: Extract repository name from URL
  ansible.builtin.set_fact:
    repository_name: "{{ repository_url.split('/')[-1].split('.')[0] }}"
```

We need to get the files to the machine, we use ansible git module (git must be installed on the remote machine, we took care of that in the base role)

```yaml
- name: Fetch app files # noqa: latest
  ansible.builtin.git:
    repo: "{{ repository_url }}"
    dest: "{{ ansible_facts.user_dir }}/{{ repository_name }}"
```

We use shell module to run commands to install dependencies and build the app, we need to chdir to the nodejs app directory

```yaml
- name: Install npm depdendencies and build app
  ansible.builtin.shell: |
    npm install
    npm run build
  args:
    executable: /bin/bash
    chdir: "{{ ansible_facts.user_dir }}/{{ repository_name }}/hello-world-app"
  changed_when: true
```

Finally we create systemd service and run the server, the service will take care of maitaining the server running

>Service file template:
>```ini
>[Unit]
>Description=NodeJS Hello World service
>After=network.target
>
>[Service]
>User=root
>Group=root
>WorkingDirectory={{ working_directory }}
>ExecStart=bash -c "npm start"
>Restart=always
>RestartSec=3
>
>[Install]
>WantedBy=multi-user.target
>```

```yaml
- name: Create service unit
  ansible.builtin.template:
    src: templates/nodejs-server-service.j2
    dest: /etc/systemd/system/nodejs-server.service
    owner: root
    group: root
    mode: "0644"
  vars:
    working_directory: "{{ ansible_facts.user_dir }}/{{ repository_name }}/hello-world-app"

- name: Reload daemon and start the new service
  ansible.builtin.systemd:
    name: nodejs-server.service
    state: started
    enabled: true
    daemon_reload: true
```
