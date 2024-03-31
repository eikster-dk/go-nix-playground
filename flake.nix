{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" ];
    pkgsForSystem = system: (import nixpkgs {
      inherit system;
    });
  in
  {
    packages = forAllSystems
     (system:
        let
          inherit (pkgsForSystem system) buildGoModule lib;
          version = self.shortRev or (builtins.substring 0 7 self.dirtyRev);
          rev = self.rev or self.dirtyRev;
        in
        {
          default = self.packages.${system}.webapp;

          webapp = buildGoModule rec {
            inherit version;
            pname = "webapp";
            src = ./.;
            subPackages = [ "cmd/webapp" ];

            CGO_ENABLED=0;
            ldflags = [
              "-w -s"
            ];
            tags = [];
            vendorHash = "sha256-QNEbR1YvJiKSrwdiC1MLsoiNdbHfOBGUWMY0Ar8klsw=";
          };
        }
     );
  };
}
