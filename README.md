# cscCLI
Compile a C# source file with any .NET Framework version installed on PC

**Usage:** *`cscCLI <filePath> <frameworkChoice> <compilerOptions>`*

Only *filePath* is required. *frameworkChoice* can be set interactively. For *compilerOptions* see [this](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/command-line-building-with-csc-exe#sample-command-lines-for-the-c-compiler).

**Usage #2:** *drag&drop™ a C# source file onto cscCLI and see what happens*

**Notes:**

* See available framework choices [here](https://github.com/Svetomech/cscCLI/blob/master/cscCLI.cmd#L157).
* cscCLI passes [some compiler options](https://github.com/Svetomech/cscCLI/blob/master/cscCLI.cmd#L27) by default.
* cscCLI has [return codes](https://github.com/Svetomech/cscCLI/blob/master/cscCLI.cmd#L4) for external usage.

**TODO:** 

* Support other VS 2017 editions (besides Community).
* Example script utilizing cscCLI capabilities.
