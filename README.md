# UE-scripts

Set of bash scripts I use to run Unreal Engine 5 locally in DebugGame Editor. Requires [ue4cli](https://github.com/adamrehn/ue4cli) to be installed.
Were tested on Linux and Windows (apart from the `spd-say`).

I normally use them together with the aliases
```
alias ue='full/path/to/run.sh'
alias ueb='full/path/to/build.sh'
alias uet='full/path/to/test.sh'
```
and run them in the folder containing the `.uproject` file for the project.

Examples:
- `ueb` to compile (in DebugGame Editor). The logs were filtered for convenience.
- `ue` to run the project (without debugger)
- `ue -b` to compile and, if the compilation passes, to run the project immediately afterwards.
- `ue -g` to run in standalone.
- `ue -t "string"` to run all the tests whose name contains `string`. Also add `-b` the compilation is required.
