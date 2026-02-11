function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    if test -z "$VSCODE_PID" -a "$TERM_PROGRAM" != "vscode"
        set _tty (tty)
        if test "$TERM" != "linux" -a (not string match -r '^/dev/tty[0-9]+$' $_tty)
            starship init fish | source
        end
        set -e _tty
    end

    if test -f ~/.config/fish/matugen-colors.fish
        source ~/.config/fish/matugen-colors.fish
    end

    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias cls 'clear'
    alias q 'qs -c ii'
    
end
