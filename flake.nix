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
      pname = "app"
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          ${pname} = pkgs.buildGoModule {
            inherit version;
            inherit name;
            src = ./.;

            vendorHash = "sha256-QNEbR1YvJiKSrwdiC1MLsoiNdbHfOBGUWMY0Ar8klsw=";
          };
        });
      nixosModules.default = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        { config
        , lib
        , pkgs
        , ...
        }:
          with lib; let
            cfg = config.playground.services.webapp;
          in
          {
            options.playground.services.webapp = {
              enable = mkEnableOption "Enable webapp";

              package = mkOption {
                type = types.package;
                default = self.packages.${system}.webapp;
                description = "webapp to use";
              };

              port = mkOption {
                type = types.port;
                default = 8051;
                description = "port to serve webapp on";
              };
            };
            config = mkIf cfg.enable {
              systemd.services.webapp = {
                description = "webapp";
                wantedBy = [ "multi-user.target" ];
                environment = {
                  PORT = "${toString cfg.port}";
                };
                serviceConfig = {
                  ExecStart = "${cfg.package}/bin/webapp";
                  ProtectHome = "read-only";
                  Restart = "on-failure";
                  Type = "exec";
                };
              };
            };
          });
    };
}
