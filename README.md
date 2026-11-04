# nix-regedit

nix-regedit is a graphical application that presents any flake using a "Registry Editor" style menu familiar to windows users. It supports selecting your flake, and can edit the flake directly. It presents attrsets as folders with non-attrset values being similar to the key-value pairs in the windows registry.  


## Requirements

- NixOS or another Linux system with nix w/ nix-command and flakes enabled.
- Flake checkouts under `$HOME/repos`; the application scans that directory at startup.

## Install

Add the flake input and enable the module:

```nix
{
  inputs.nix-regedit.url = "github:ojuny-project/nix-regedit";

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.nix-regedit.nixosModules.default
        { services.nix-regedit.enable = true; }
      ];
    };
  };
}
```

Rebuild with `sudo nixos-rebuild switch --flake .#<host>`. The module adds the
package to `environment.systemPackages`. Check the result with
`command -v nix-regedit`, which prints the store path.

To build without the module, run `nix build`; the executable is
`result/bin/nix-regedit`. `nix run` starts the application from the checkout, you can also use `nix run github:ojuny-project/nix-regedit` to run the application without permanent install.

## Usage

Start `nix-regedit`. The flake selector lists every directory under
`$HOME/repos` that contains a `flake.nix`, up to three levels deep.

The left pane shows the namespaces found in the selected flake. The right pane
shows the keys in the selected namespace. Double-click a key to open its editor;
the dialog lists each source location and offers a widget chosen from the value
type. Press OK to write the changes, then the file is reformatted with
`nixfmt` and the flake is rescanned.

The scanner records `flake.modules.<kind>.<name>` bodies and other
`flake.<output>.<name>` bindings. It follows `self.<output>.<path>` references in
`imports` and `modules` lists and marks merged records with their origin.

## Limits

The flake root is fixed to `$HOME/repos` and the scan depth is three. Only
literal attribute paths are read; dynamic attributes are skipped. Files named
`flake.nix` or starting with `_` are excluded, as are hidden directories. The
tool does not evaluate nixpkgs defaults, so type information depends on `nixd`.
An option declared inside `lib.mkMerge`, a list of attribute sets, or another
config-level expression may not appear. Edits are limited to files inside the
flake root and never touch `/nix/store`. There is no built-in undo history and no backup
copy, as flakes are expected to be inside git repositories; `nixfmt` rewrites the file in place.

## Documentation
- [OPTIONS.md](OPTIONS.md) is the generated options reference.


## Contributing

Open issues at <https://github.com/ojuny-project/nix-regedit/issues>. A patch must add
or update a test in `src/extract.rs` for scanner changes, run `cargo test`, and
keep `nix build` passing. State which flake layout the change was tested on.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE). The flake metadata states the same
license.
