_snk_sift() 
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ ${cur} == -* ]] ; then
		opts="$(snk-sift --help | snk-sift '\s+(--[\w-]+)(?:\s|=)' --replace '$1' --output-sep ' ')"
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
	fi

	case "${prev}" in
		-t|-T|--type|--no-type|--del-type)
			types="$(snk-sift --list-types | snk-sift '^(\w+)\s+:' --replace '$1' --output-sep ' ')"
			COMPREPLY=( $(compgen -W "${types}" -- ${cur}) )
			return 0;;
	esac

	_filedir
	return 0
}
complete -F _snk_sift snk-sift
