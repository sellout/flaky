## Settings for participating in [Hacktoberfest](https://hacktoberfest.com/participation/#maintainers)
##
## TODO: Add similar settings for GitLab, if that’s possible.
{
  config,
  lib,
  ...
}: let
  cfg = config.community.hacktoberfest;
in {
  meta.maintainers = [lib.maintainers.sellout];

  options.community.hacktoberfest = {
    enable = lib.mkEnableOption "Hacktoberfest";
  };

  config = lib.mkIf cfg.enable {
    programs.vale.vocab.${config.project.name}.accept = ["Hacktoberfest"];
    services.github.settings.repository.topics =
      lib.mkIf (! config.services.github.settings.repository.private)
      ["hacktoberfest"];
    services.github.settings.labels = lib.mkIf (! config.services.github.settings.repository.private) {
      hacktoberfest = {
        color = "#000000"; # black
        description = "Issues you want contributors to help with.";
      };
      hacktoberfest-accepted = {
        color = "#ff7518"; # pumpkin
        description = "Indicates acceptance for Hacktoberfest criteria, even if not merged yet.";
      };
      spam = {
        color = "#ffc0cb"; #pink
        description = "Topic created in bad faith. Services like Hacktoberfest use this to identify bad actors.";
      };
      invalid = {
        color = "#333333"; #dark grey
        description = "Unaccepted contributions that haven’t been closed for some reason.";
      };
    };
  };
}
