# config.nu
# Installed by:
# version = "0.105.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.
$env.config = {
    hooks: {
        command_not_found: {
            |cmd_name| (
                try {
                    let pkgs = (pkgfile --binaries --verbose $cmd_name)
                    if ($pkgs | is-empty) {
                        return null
                    }
                    (
                        $"(ansi $env.config.color_config.shape_external)($cmd_name)(ansi reset) " +
                        $"may be found in the following packages:\n($pkgs)"
                    )
                }
            )
        }
    }
}
$env.config.buffer_editor = "nvim" 
$env.config.show_banner = false
$env.EDITOR = "nvim"
let $EDITOR = $env.EDITOR
fastfetch

alias odin = ~/scripts/odin.bash
alias dnvim = doas nvim
#alias cd = z
#alias reset = clear; source ~/.config/nushell/config.nu
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

$env.GOPATH = "/home/liforra/go"
$env.PATH ++= [($env.GOPATH | path join "bin")]
# --- Git Aliases ---

alias gc = git add *; git commit -a
alias gp = git push
alias gpl = git pull
alias gps = git push
alias gg = git clone

source ~/.zoxide.nu
alias cd = z
