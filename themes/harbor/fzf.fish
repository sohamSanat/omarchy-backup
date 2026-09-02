set -l color00 '#dfe4c4'
set -l color01 '#b14752'
set -l color02 '#556753'
set -l color03 '#dc8164'
set -l color04 '#4c6c94'
set -l color05 '#8a5b81'
set -l color06 '#3d727d'
set -l color07 '#384f54'
set -l color08 '#7d8794'
set -l color09 '#b14752'
set -l color0A '#556753'
set -l color0B '#dc8164'
set -l color0C '#4c6c94'
set -l color0D '#8a5b81'
set -l color0E '#3d727d'
set -l color0F '#1c2d28'

set -l FZF_NON_COLOR_OPTS

for arg in (echo $FZF_DEFAULT_OPTS | tr " " "\n")
    if not string match -q -- "--color*" $arg
        set -a FZF_NON_COLOR_OPTS $arg
    end
end

set -Ux FZF_DEFAULT_OPTS "$FZF_NON_COLOR_OPTS"" --color=bg+:$color00,bg:$color00,spinner:$color0E,hl:$color0D"" --color=fg:$color07,header:$color0D,info:$color0A,pointer:$color0E"" --color=marker:$color0E,fg+:$color06,prompt:$color0A,hl+:$color0D"
