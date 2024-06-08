{
  description = "very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      #System types to support.
      supportedSystems = [ "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      version = "0.0.1";
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
           default = pkgs.buildGoModule {
            inherit version;
            name = "webapp";
            src = ./.;

            vendorHash = "sha256-QNEbR1YvJiKSrwdiC1MLsoiNdbHfOBGUWMY0Ar8klsw=";
          };
        });
    };
}
