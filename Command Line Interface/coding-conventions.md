# Coding Conventions

This file contains descriptions of certain coding conventions used in the Command Line Interface's
scripts.

---

## File Structure
Scripts, except for [pseudo-libraries](#pseudolibraries) and tests, are structured into:
* preliminaries
* constant declarations
* function declarations
* the main script

#### Preliminaries:
The preliminaries section contains imports of [pseudo-libraries](#pseudolibraries) and the
declaration of the `dot` variable. The `dot` variable contains the path to the script file in which
it is declared. This is useful when referring to other paths, based on the location of the script.

#### Constants:
Constants are declared in a `declare_constants` function which expects all of the script's command
line arguments as parameters. `declare_constants` is the first function to be called in the main
script. This way constant declarations can also use functions declared after the `declare_constants`
function itself. Constant declarations use `readonly` instead of `declare -r`, so that the
declarations are global. The `declare_constants` may be failable.

#### Functions:
Functions are declared with the `function` keyword. Leading and trailing underscores in functions'
names have semantic relevance, as described in [pseudo-libraries](#pseudolibraries) and
[error handeling](#errorhandeling). Functions are preceded by documentation containing expected
arguments and output (and return status if they are failable).

#### Main:
The main section of the script contains the equivalent of a `main`-function in other languages. It
starts by calling `declare_constants` if appropriate. It is also resposible for propagating any
failing return status produced by calling failable functions.

---

<a name="errorhandeling"></a>
## Error Handeling
Functions whose names end on an underscore can fail, indicated by returning on a non-zero or
"failing" return status. Functions without a trailing underscore should be expected to succeed and
return `0`. Functions whose name end on a hyphen reflect the return status of a given command, and
are therefore failable if and only if the given command is failable.

---

## Variable Declarations
Variables are declared as _readonly_ whenever possible. For global variables this implies the use of
the `readonly` keyword, for local variables the `-r` flag is set. Variables within functions are
always declared as _local_.

---

<a name="pseudolibraries"></a>
## Pseudo-Libraries
Certain functions are used across multiple scripts. These functions live in "libraries", which are
simply scripts containing only function and alias declarations. These libraries are imported by
sourcing the execution of the script (`source <library>`/`. <library>`).
Libraries are layed out slightly differently than other script files. Constants are not declared in
a seperate function, and constants not meant for use outside of the script are preceded by an
underscore in there name. Certain functions in libraries have convenience-aliases meant to be used to call the given function. Such functions are denoted by a leading underscore in their name, and their corresponding alias is declared right above the function declaration.
