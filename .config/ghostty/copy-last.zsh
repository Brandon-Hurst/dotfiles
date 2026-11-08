# Copies the last command (path line + prompt line as displayed) and its
# output to the clipboard. Triggered by Ghostty (Alt+E): write_scrollback_file:copy
# puts the scrollback file path on the clipboard, then sends the private
# sequence bound below.
#
# Written for a two-line starship prompt:
#     ~/proj on main took 4s      <- path line (GCL_PROMPT_ABOVE lines above the marker)
#     ❯ command                   <- line starting with GCL_PROMPT_RE
#
# The command line is located by the exact text zsh recorded in preexec, so
# other "❯" lines in scrollback (e.g. Claude Code's input box) are ignored.
# The scrollback file used is kept at ~/.cache/ghostty-copy-last/last.txt for debugging.

zmodload zsh/stat zsh/datetime
typeset -g GCL_PROMPT_RE='[❯❮]*' GCL_PROMPT_ABOVE=1 _gcl_cmd=
typeset -g GCL_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-copy-last

autoload -Uz add-zsh-hook
_gcl_preexec() { _gcl_cmd=${1%%$'\n'*} }   # first line of the command as typed
add-zsh-hook preexec _gcl_preexec

_gcl_clip_get() {
  if [[ -n $WAYLAND_DISPLAY ]] && (( $+commands[wl-paste] )); then wl-paste -n 2>/dev/null
  else xclip -selection clipboard -o 2>/dev/null; fi
}
_gcl_clip_set() {
  if [[ -n $WAYLAND_DISPLAY ]] && (( $+commands[wl-copy] )); then wl-copy
  else xclip -selection clipboard -i; fi
}

# _gcl_extract FILE -> prints header lines + output of the last finished command
_gcl_extract() {
  [[ -n $_gcl_cmd ]] || return 1
  local -a lines=("${(@f)$(<$1)}")
  local i cur=0 prev=0 above=$GCL_PROMPT_ABOVE

  # Trailing blank lines don't count.
  while (( $#lines )) && [[ -z ${lines[-1]//[[:space:]]/} ]]; do lines[-1]=(); done

  # cur = current (bottom-most) prompt line.
  for (( i=$#lines; i>=1; i-- )); do
    [[ ${lines[i]} == ${~GCL_PROMPT_RE} ]] && { cur=$i; break }
  done
  (( cur )) || return 1

  # prev = nearest earlier prompt line ending in exactly the command we ran.
  for (( i=cur-1; i>above; i-- )); do
    local l=${lines[i]%%[[:space:]]#}   # ignore trailing whitespace
    if [[ $l == ${~GCL_PROMPT_RE} && $l == *"$_gcl_cmd" ]]; then
      prev=$i; break
    fi
  done
  (( prev )) || return 1

  # The path line carries the *previous* command's duration ("took 4m25s"); drop it.
  local path_line=${lines[prev-above]}
  [[ $path_line =~ ' took [0-9hmsd. ]+$' ]] && path_line=${path_line% took *}

  local -a header=("${(@)lines[prev-above,prev]}")
  header[1]=$path_line

  local -a out=("${(@)lines[prev+1,cur-above-1]}")
  while (( $#out )) && [[ -z ${out[-1]//[[:space:]]/} ]]; do out[-1]=(); done
  print -r -- "${(F)header}"
  (( $#out )) && print -r -- "${(F)out}"
  return 0
}

copy-last-command() {
  # Accept only a readable file written in the last few seconds; poll up to ~1.5s
  # so a stale clipboard (old path, or unrelated text) is never used.
  local file i
  local -a st
  for (( i=0; i<30; i++ )); do
    file=$(_gcl_clip_get)
    if [[ $file == /* && -r $file ]]; then
      zstat -A st +mtime -- $file 2>/dev/null && (( EPOCHSECONDS - st[1] <= 5 )) && break
    fi
    file=
    sleep 0.05
  done
  [[ -n $file ]] || { zle -M "copy-last: no fresh scrollback file from Ghostty"; return }

  mkdir -p -- $GCL_CACHE && cp -f -- $file $GCL_CACHE/last.txt
  rm -f -- $file

  local result
  result=$(_gcl_extract $GCL_CACHE/last.txt) || { zle -M "copy-last: couldn't find '$_gcl_cmd' in scrollback"; return }
  print -rn -- $result | _gcl_clip_set
  zle -M "copied: $_gcl_cmd"
}
zle -N copy-last-command
bindkey '\e[9001~' copy-last-command
