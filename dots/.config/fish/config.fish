if status is-interactive
    # Don't Greet
    set fish_greeting

    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
        alias ls 'eza --icons'
    end

    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias cls "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
