# nix-regedit

nix-regedit is a GTK4 and libadwaita application that presents the options
written in a Nix flake as a registry editor. It scans a flake checkout, lists
the literal configuration assignments in its module files, and writes edited
values back into the same files. The package targets Linux and wraps `nix`,
`nixd`, and `nixfmt` into its runtime path.

## Status

Untested. The version in `Cargo.toml` and `flake.nix` is 0.1.0. No end-to-end
run is recorded for this page, and the flake builds the package with
`doCheck = false`.

## Requirements

- NixOS or another Linux system with flakes enabled.
- GTK4 and libadwaita at runtime; the package supplies both.
- Flake checkouts under `$HOME/repos`; the application scans that directory at
  startup, not an arbitrary path.
- `nixd` for option types and descriptions, and `nixfmt` for formatting edited
  files. The packaged binary finds both through its wrapper.
- A Rust toolchain and `cargo` only when building from the devshell.

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
`result/bin/nix-regedit`. `nix run` starts the application from the checkout.

## Usage

Start `nix-regedit`. The flake selector lists every directory under
`$HOME/repos` that contains a `flake.nix`, up to three levels deep, skipping
`target`, `result`, `node_modules`, `.git`, and `.direnv`. If
`$HOME/repos/nixos-configs/dendrite` exists, it is selected first.

The left pane shows the namespaces found in the selected flake. The right pane
shows the keys in the selected namespace. Double-click a key to open its editor;
the dialog lists each source location and offers a widget chosen from the value
type. Press OK to write the changes, then the file is reformatted with
`nixfmt` and the flake is rescanned.

Expected results: the status bar reports `N configured option(s) from flake
files` after a scan and `Saved, rescanning...` after a successful edit. A
failed scan or save opens an error dialog and changes the status text.

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
flake root and never touch `/nix/store`. There is no undo history and no backup
copy; `nixfmt` rewrites the file in place.

## Documentation

- [src/extract.rs](src/extract.rs) shows what the scanner records and resolves.
- [src/edit.rs](src/edit.rs) shows the write, format, and editability rules.
- [src/nixd.rs](src/nixd.rs) shows the type and description lookup.
- [modules/nixos.nix](modules/nixos.nix) defines the module option.

## Contributing

Open issues at <https://github.com/ojuny-project/nix-regedit/issues>. A patch must add
or update a test in `src/extract.rs` for scanner changes, run `cargo test`, and
keep `nix build` passing. State which flake layout the change was tested on.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE). The flake metadata states the same
license.
