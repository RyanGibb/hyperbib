{
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
    # maintain a different opam-repository to those pinned upstream
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
    opam-nix.inputs.opam-repository.follows = "opam-repository";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        package = "hyperbib";
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        query = { ocaml-base-compiler = "*"; };
        overlay = final: prev: {
          # You can add overrides here
          "${package}-static" = prev.${package}.overrideAttrs (_: {
            buildPhase = ''
             dune build src/app/static
            '';
            installPhase = ''
              mkdir $out
              cp -R _build/default/src/app/static/* $out/
            '';
          });
        };
        resolved-scope =
          let scope = on.buildOpamProject' { } ./. query; in
          scope.overrideScope' overlay;
        materialized-scope =
          let scope = on.materializedDefsToScope { sourceMap.${package} = ./.; } ./package-defs.json; in
          scope.overrideScope' overlay;
      in rec {
        packages = {
          resolved = resolved-scope;
          materialized = materialized-scope;
          # to generate:
          #   cat $(nix eval .#package-defs --raw) > package-defs.json
          package-defs = on.materializeOpamProject' { } ./. query;
        };
        defaultPackage = packages.materialized.${package};
        packages.default = packages.materialized.${package};
      }
    ) // {
      nixosModules.default = ({ pkgs, config, lib, ... }:
        with lib;

        let cfg = config.services.hyperbib; in
        {
          options = {
            services.hyperbib = {
              enable = mkEnableOption "hyperbib website";
              domain = mkOption {
                type = types.str;
                default = "example.org";
              };
              port = lib.mkOption {
                type = lib.types.port;
                default = 8080;
              };
              user = lib.mkOption {
                type = lib.types.str;
                default = "hyperbib";
              };
              group = lib.mkOption {
                type = lib.types.str;
                default = cfg.user;
              };
              servicePath = lib.mkOption {
                type = lib.types.str;
                default = "/mybibliography";
              };
              appDir = lib.mkOption {
                type = lib.types.str;
                default = "/var/www/hyperbib/";
              };
            };
          };

          config = mkIf cfg.enable {
            services.nginx = {
              enable = true;
              virtualHosts = {
                "${cfg.domain}" = {
                  forceSSL = true;
                  enableACME = true;
                  locations."${cfg.servicePath}" = {
                    proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}/";
                  };
                };
              };
            };

            systemd.services.hyperbib = {
              enable = true;
              description = "hyperbib";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                ExecStart =
                  "${self.packages.${config.nixpkgs.hostPlatform.system}.default}/bin/hyperbib" +
                  " serve" +
                  " --listen localhost:${builtins.toString cfg.port}" +
                  " --service-path ${cfg.servicePath}" +
                  " --app-dir ${cfg.appDir}";
                Restart = "on-failure";
                RestartSec = "10s";
                User = cfg.user;
                Group = cfg.group;
              };
            };

            users.users = {
              "${cfg.user}" = {
                description = "hyperbib service";
                useDefaultShell = true;
                group = cfg.group;
                isSystemUser = true;
              };
            };

            users.groups."${cfg.group}" = {};
          };
        });

      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            boot.isContainer = true;
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 ];
            services.nginx = {
              enable = true;
              virtualHosts."_" = {
                locations."/" = {
                   proxyPass = "http://127.0.0.1:8080";
                 };
              };
            };
            systemd.services.hyperbib = {
              enable = true;
              description = "hyperbib";
              serviceConfig = {
                ExecStart = ''
                  ${self.packages."x86_64-linux".default}/bin/hyperbib
                  --listen localhost:8000
                  --service-path /mybibliography/
                  --app-dir /var/www/hyperbib
                '';
              };
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              environment.PORT = "8080";
            };
            system.stateVersion = "22.11";
          })
        ];
      };
    };
}
