## Using the Interpreter

For details on the language itself, read the [manual](http://hjemmesider.diku.dk/~torbenm/Troll/manual.pdf).

All functionality described in the manual is implemented (*not necessarily correctly* :) with the following exceptions:

- Compositional functions
- Probability calculations

As these are functions I do not currently need, their implementation is low priority. Let me know if they are important to you and I may re-consider. Of course, pull requests with implementations are appreciated!

### Running a Script

If you run troll with a filename on the command line, it will execute that script

```
troll afile.t
```

You can optionally define variables on the command line as well

```
troll afile.t N=5 S=20
```

Given this command line, the definitions can make use of the values specified for `N` and `S`. Variable definitions must be of the form `<identifier>=<integer>` where `<identifier>` follows the Troll requirements for variable names. There cannot be spaces between the equals sign and the identifier and integer value. Definitions for variables that are not used in the Troll script are ignored.

Troll files conventionally have names ending in `.t`, but that is not required.

### Interactive Usage

If you run troll without a filename

```
$ troll
```

it will start up an interactive shell (aka a REPL). You can enter a line of Troll code at the prompt and the interpreter will print the resulting value. In addition, several commands are supported (enter commands on a line by themselves):

- `+set` &mdash; define a variable to be used in subsequent Troll code. The format is `+set <varname> <integer>`
- `-set` &mdash; remove a variable definition. The format is `-set <varname`
- `+multiline` &mdash; allows you to enter multiple lines of Troll code

   This is particularly useful for entering function definitions since currently you cannot enter them without also entering a 'main' Troll script.
   
   To stop entering Toll code and have the interpreter run the script, enter `+done` on its own line.
- `+quit` &mdash; quit the REPL (*Ctl-D and Ctl-C also work*)
- `+version` &mdash; print the interpreter version
- `+help` &mdash; print a help message

NOTE: Variable definitions remain in existance until either you remove them (*via `-set`*) or you quit the REPL; although you can *shadow* variables by re-defining them.  Functions continue to be defined as well (*currently there is no mechanism to un-define a function, other than quitting the REPL*).

The following commands are (*probably*) only of interest to people working on the Troll implementation:

- `+parser` &mdash; print the AST
-  `-parser` &mdash; stop printing the AST
- `+scanner` &mdash; print the token stream
- `-scanner` &mdash; stop printing the token stream





## Installing Troll

Troll should build on any platform that has Swift, i.e. macOS, Linux (Ubuntu, CentOS, Amazon Linux 2), and Windows 10. Currently it has only been tested on macOS.

### Get a pre-compiled version

Download the [latest release](https://github.com/profburke/troll/releases), and copy the executable to somewhere on your PATH; `/usr/local/bin` is recommended.

### Build from scratch

Building should be fairly straight-forward:

```
git clone https://github.com/profburke/troll
cd troll
swift build -c release
```

Copy the executable file (`.build/release/troll`) to somewhere on your PATH; `/usr/local/bin` is a good choice.

If there are errors while building, please create an [issue](https://github.com/profburke/troll/issues/new).
