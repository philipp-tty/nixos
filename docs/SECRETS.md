# Secrets in a public repo

This repo is public. Do not commit plaintext secrets.

For email accounts, prefer GNOME Online Accounts or Thunderbird so credentials live in the GNOME keyring instead of your Nix config.

If you need secrets in Nix (e.g. for CLI mail tools), use sops-nix.

## sops-nix quick setup

1. Create an age key for your user:

```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

2. Add a `.sops.yaml` (replace the key):

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml
    age: ["AGE_PUBLIC_KEY_HERE"]
```

3. Create your encrypted secrets file:

```sh
mkdir -p secrets
sops --config .sops.yaml -e secrets/zeus.yaml > secrets/zeus.yaml
```

4. Wire it up in `hosts/zeus/configuration.nix` (example):

```nix
# sops.defaultSopsFile = ./secrets/zeus.yaml;
# sops.age.keyFile = "/var/lib/sops-nix/key.txt";
# sops.secrets."mail/app-password".owner = "philipp";
```

5. Copy the key onto the system and rebuild:

```sh
sudo install -D -m 0600 ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo nixos-rebuild switch --flake .#zeus
```

Keep encrypted files in `secrets/` and never commit unencrypted credentials.
