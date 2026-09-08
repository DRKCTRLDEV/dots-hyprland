# Keep terminal titles without invoking the Pure prompt's prompt_pwd function.
function fish_title
    if not set -q INSIDE_EMACS
        echo (status current-command) ' '
        and pwd
    end
end
