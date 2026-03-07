export let eggs = #{
    // Root configs
    bashrc: { targets: "~/.bashrc", templates: [".bashrc"] },
    zshrc: { targets: "~/.zshrc", templates: [".zshrc"] },
    profile: { targets: "~/.profile", templates: [".profile"] },
    gitconfig: { targets: "~/.gitconfig", templates: [".gitconfig"] },

    // Scripts directory
    scripts: { targets: "~/scripts", templates: ["scripts"] },

    // Config directories
    bash_config: { targets: "~/.config/bash", templates: ["bash"] },
    zsh_config: { targets: "~/.config/zsh", templates: ["zsh"] },
    fish: { targets: "~/.config/fish", templates: ["fish"] },
    nushell: { targets: "~/.config/nushell", templates: ["nushell"] },
    
    nvim: { targets: "~/.config/nvim", templates: ["nvim"] },
    hypr: { targets: "~/.config/hypr", templates: ["hypr"] },
    xdg_portal: { targets: "~/.config/xdg-desktop-portal", templates: ["xdg-desktop-portal"] },
    niri: { targets: "~/.config/niri", templates: ["niri"] },
    waybar: { targets: "~/.config/waybar", templates: ["waybar"] },
    rofi: { targets: "~/.config/rofi", templates: ["rofi"] },
    kitty: { targets: "~/.config/kitty", templates: ["kitty"] },
    tmux: { targets: "~/.config/tmux", templates: ["tmux"] },
    zellij: { targets: "~/.config/zellij", templates: ["zellij"] },
    fastfetch: { targets: "~/.config/fastfetch", templates: ["fastfetch"] },
    tealdeer: { targets: "~/.config/tealdeer", templates: ["tealdeer"] },
    
    // Single file configs in root of .dots that go to .config
    starship: { targets: "~/.config/starship.toml", templates: ["starship.toml"] },
};
