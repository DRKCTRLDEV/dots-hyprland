## Why is this important?
Instead of installing python packages via system package manager, we should install them into virtual environment.

This is important because there has been so many complaints about the failure installing/updating python packages via system package manager, see [#1017](https://github.com/end-4/dots-hyprland/issues/1017).

## How to add/remove python package?

1. Edit `requirements.in`. You may refer to [PyPI](https://pypi.org/) for possible package names.
  - If PyPI does not have the needed package, we probably need to build it manually inside the venv. In such case we need to edit the install scripts.
2. Run `uv pip compile requirements.in -o requirements.txt` in this folder.

**Notes:**
- For reference see [uv doc](https://docs.astral.sh/uv/pip/dependencies/#using-requirementsin).
- `requirements.txt` is included in Git. It's for locking package versions to enhance stability and reproducibility.[^1]

[^1]: In fact, including package version lock file in Git is also the most common way for similar situations, for example the `package-lock.json` of Node.js projects (see also [this stackoverflow question](https://stackoverflow.com/questions/48524417/should-the-package-lock-json-file-be-added-to-gitignore)). Although there are some situations when it's not suitable to include the lock file, for example [the poetry document](https://python-poetry.org/docs/basic-usage/#committing-your-poetrylock-file-to-version-control) recommend application developers to include package version lock file in Git, but library developers should consider more, such as not including the lock file or including it but refreshing regularly.

## How will the python packages get installed?

For summary:
- They will be installed to the virtual environment `$ILLOGICAL_IMPULSE_VIRTUAL_ENV`.
- The default value of `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` is `$XDG_STATE_HOME/quickshell/.venv`.
  - The default value of `$XDG_STATE_HOME` is `$HOME/.local/state`.
- Currently we use `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV, ~/.local/state/quickshell/.venv` in `~/.config/hypr/hyprland/env.conf` to set this environment variable.[^2]

For details: see the function `install-python-packages()` defined in `/sdata/lib/package-installers.sh`.

[^2]: Hyprland seems to have weird problem dealing with recursive variable, so we can not use `$XDG_STATE_HOME/quickshell/.venv` even if we had set `$XDG_STATE_HOME` to `~/.local/state` explicitly, else `$XDG_STATE_HOME` will possibly not get expanded but get recognised as literally `$XDG_STATE_HOME`. This problem never happens for some users, but according to some issues when we were using recursive variable setting in the past, it's possible to happen for other users. Reason unknown.

## How to use the python packages installed through here?

Basically you'll need to activate the virtual environment first:
```bash
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
```

It will add the python executable located in the venv to `$PATH` and give it the highest priority.
Run `which python` and you'll understand.

This python executable will also search and use the python package inside the venv,
which enables running any python script or running command provided via python package using the venv.

After that you probably need to deactivate it:
```bash
deactivate
```

### Situation 1: As a single command
**Description:** At someplace which accept a single command,
- run a python script,
- or run a command provided by python package.

Example: In `~/‎.config/quickshell/ii/screenshot.qml`:
```qml
Process {
id: imageDetectionProcess
                command: ["bash", "-c", `${Directories.scriptPath}/images/find_regions.py ` 
+ `--hyprctl ` 
+ `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}' ` 
+ `--max-width ${Math.round(panelWindow.screen.width * root.falsePositivePreventionRatio)} ` 
```
In this example, python script `find_regions.py` is called and receives some arguments.

#### Solution: shebang (preferred)

Add the shebang below to the beginning of python script:
```python
#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
```
And that's it! The script activates the venv, then `exec`s python with the script and all
arguments. No wrapper shell script needed.

The QML caller doesn't need to change — it still calls the `.py` file directly:
```qml
Process {
id: imageDetectionProcess
                command: ["bash", "-c", `${Directories.scriptPath}/images/find_regions.py ` 
+ `--hyprctl ` 
+ `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}' ` 
+ `--max-width ${Math.round(panelWindow.screen.width * root.falsePositivePreventionRatio)} ` 
```

**Notes:**
- This shebang uses `env -S` to split the argument and invoke `/bin/sh -c` which activates
  the venv and then `exec`s `python -E` with the script and its arguments.
- `\_` is `env -S`'s escape for a space character (avoids kernel shebang splitting issues).
- `\$` is `env -S`'s escape for a literal `$` (deferred to the shell for expansion).
- The shebang is ignored if the script is run directly via `python3 foo.py`; use `./foo.py` instead.
- This approach is used by `thumbgen.py`, `find_regions.py`, and `rivalcfg_wrapper.py`.

### Situation 2: Inside a bash script
Note: the solutions for `Situation 1: As a single command` also apply here; but **not** vice versa.

**Description:**
Inside a bash script,
- run a python script,
- or run a command provided by python package.

**Solution:**
- Add "activation command" before the target line,
- Also add "deactivation command" after the target line.

**Example:**

For running a python script,
take `scheme_for_image.py` as example:
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
python3 "$SCRIPT_DIR/scheme_for_image.py" "$imgpath"
deactivate
```

For running a command provided by python package,
take `rivalcfg` as example:
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
rivalcfg --sensitivity 800
deactivate
```



