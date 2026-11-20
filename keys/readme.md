please provide your keys in the following structure

all VMs reuses bastion host ssh keys but tls keys needs to be provided

```
keys
├── bastion
│   └── ssh
│       ├── id_ed25519
│       └── id_ed25519.pub
├── gitlab
│   ├── ssh
│   └── tls
│       ├── gitlab.ntnxlab.local.crt
│       └── gitlab.ntnxlab.local.key
└── registry
    ├── ssh
    └── tls
        ├── registry-private.key
        └── registry-server.crt
```        