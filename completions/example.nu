export extern "example" [
  --help(-h) # Print command help
  --json # Write JSON to stdout
  --version # Write the version to stdout
  ...args: string@"__example_completion_none"
]

export extern "example completion" [
  shell: string@"nu-complete example shell"
]

def "nu-complete example shell" [] { [bash zsh fish nu] }

def "__example_completion_none" [] { [] }