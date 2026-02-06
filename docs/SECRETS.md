# Secrets (public repo)

This repo is public. Do not commit plaintext secrets (SSH keys, tokens, passwords).

If you just need GUI app credentials (mail, calendars, etc.), prefer GNOME Online Accounts / the GNOME keyring.
If you need secrets inside Nix config, use `sops-nix` (already included as a flake input/module here).

## sops-nix quick setup (age)

If you don't have the tools locally, you can get them temporarily with:

```sh
nix-shell -p age sops
```

1. Create an age key for your user and copy the public key:

```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

2. Add `.sops.yaml` in the repo root (replace the key):

```yaml
creation_rules:
  - path_regex: ^secrets/.*\.ya?ml$
    age:
      - AGE_PUBLIC_KEY_HERE
```

3. Create/edit an encrypted secrets file:

```sh
mkdir -p secrets
sops --config .sops.yaml secrets/zeus.yaml
```

4. Wire it up in your host config.

Example snippet for `hosts/zeus/base.nix` (or `hosts/zeus/configuration.nix`):

```nix
{
  sops = {
    defaultSopsFile = ../../secrets/zeus.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Example secret path inside the YAML:
    # mail:
    #   app-password: "..."
    secrets."mail/app-password".owner = "philipp";
  };
}
```

5. Install the private key on the target machine and rebuild:

```sh
sudo install -D -m 0600 ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo nixos-rebuild switch --flake .#zeus
```

Keep encrypted files in `secrets/` and never commit the age private key.
