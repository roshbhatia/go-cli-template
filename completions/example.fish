complete -c example -e
complete -c example -f

function __example_completion_context
  set -l context ''
  set -l words (commandline -opc)
  set -l consume_value 0
  set -l options_done 0
  for word in $words[2..-1]
    if test $consume_value -eq 1
      set consume_value 0
      continue
    end
    if test $options_done -eq 1
      continue
    end
    if test "$word" = '--'
      set options_done 1
      continue
    end
    switch "$context:$word"
    end
    switch "$context:$word"
      case ':completion'
        set context 'completion'
      case ':completion'
        set context 'completion'
    end
  end
  echo $context
end
complete -c example -n 'test (__example_completion_context) = ""' -l help -s h -d 'Print command help'
complete -c example -n 'test (__example_completion_context) = ""' -l json -d 'Write JSON to stdout'
complete -c example -n 'test (__example_completion_context) = ""' -l version -d 'Write the version to stdout'
complete -c example -f -n 'test (__example_completion_context) = ""' -a completion -d 'Generate shell completions'
complete -c example -f -n 'test (__example_completion_context) = ""' -a completion -d 'example completion <bash|fish|nu|zsh>'
complete -c example -f -n 'test (__example_completion_context) = "completion"' -a 'bash zsh fish nu'
complete -c example -f -n 'test (__example_completion_context) = "completion"' -a 'bash zsh fish nu'