# settings
typeset +H _current_dir="%{$fg_bold[blue]%}%3~%{$reset_color%} "
typeset +H _return_status="%{$fg_bold[red]%}%(?..⍉)%{$reset_color%}"
typeset +H _hist_no="%{$fg[grey]%}%h%{$reset_color%}"

PROMPT='
$(_user_host)${_current_dir} $(git_prompt_info)
%{%(!.${fg[red]}.${fg[green]})%}➜%{$reset_color%} '

PROMPT2='%{%(!.${fg[red]}.${fg[white]})%}◀%{$reset_color%} '

__RPROMPT='$(vi_mode_prompt_info)%{$(echotc UP 1)%}$(_git_time_since_commit) $(git_prompt_status) ${_return_status}%{$(echotc DO 1)%}'
if [[ -z $RPROMPT ]]; then
  RPROMPT=$__RPROMPT
else
  RPROMPT="${RPROMPT} ${__RPROMPT}"  
fi

function _user_host() {
  local me
  if [[ -n $SSH_CONNECTION ]]; then
    me="%n@%m"
  elif [[ $LOGNAME != $USERNAME ]]; then
    me="%n"
  fi
  if [[ -n $me ]]; then
    echo "%{$fg[cyan]%}$me%{$reset_color%}:"
  fi
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
function _git_time_since_commit() {
  local last_commit now seconds_since_last_commit
  local minutes hours days years commit_age
  # Only proceed if there is actually a commit.
  if last_commit=$(command git -c log.showSignature=false log --format='%at' -1 2>/dev/null); then
    now=$(date +%s)
    seconds_since_last_commit=$((now-last_commit))

    # Totals
    minutes=$((seconds_since_last_commit / 60))
    hours=$((minutes / 60))
    days=$((hours / 24))
    years=$((days / 365))

    if [[ $years -gt 0 ]]; then
      commit_age="${years}y$((days % 365 ))d"
    elif [[ $days -gt 0 ]]; then
      commit_age="${days}d$((hours % 24))h"
    elif [[ $hours -gt 0 ]]; then
      commit_age+="${hours}h$(( minutes % 60 ))m"
    else
      commit_age="${minutes}m"
    fi

    echo "${ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL}${commit_age}%{$reset_color%}"
  fi
}

MODE_INDICATOR="%{$fg_bold[yellow]%}❮%{$reset_color%}%{$fg[yellow]%}❮❮%{$reset_color%}"

# Git prompt settings
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚ "
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}⚑ "
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖ "
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%}▴ "
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[cyan]%}§ "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[white]%}◒ "

# Colors vary depending on time lapsed.
ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT="%{$fg[green]%}"
ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM="%{$fg[yellow]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG="%{$fg[red]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL="%{$fg[white]%}"

export LSCOLORS="exfxcxdxbxegedabagacad"
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:'
export GREP_COLORS='mt=1;33'