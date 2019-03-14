# Coding Conventions

This file contains descriptions of certain coding conventions used in the Command Line Interface's
scripts.

---

## File Structure
Scripts are structured into:
* a header containing documentation and imports
* constant declarations
* function declarations
* the main script

#### Header:
The header usually contains a description of the script's functionality including expected
arguments, type of output and explanations of possible return status. Imports in the header are
achieved by sourcing other scripts.

#### Constants:
Constants are declared in a `declare_constants` function which expects all of the script's command
line arguments as parameters. `declare_constants` is the first function to be called in the main
script. This way constant declarations can also use functions declared after the `declare_constants`
function itself. Constant declarations use `readonly` instead of `declare -r`, so that the
declarations are global. The `declare_constants` may be failable.

#### Functions:
Functions are declared with the `function` keyword. Furthermore they set their return status as
described in [Error Handeling](#errorhandeling).

#### Main:
The main section of the script contains the equivalent of a `main`-function in other languages. It
starts by calling `declare_constants` if appropriate. It is also resposible for propagating any
failing return status produced by calling failable functions.

---

<a name="errorhandeling"></a>
## Error Handeling
Functions whose names end on an underscore can fail, indicated by returning on a non-zero return
status. Functions without a trailing underscore should be expected to succeed and return `0`.
Occurrences of `return 0` or `exit 0` for the purpose of adhering to this convention are annotated
with `# EHC` (meaning _error handeling convention_). Call sites of failable functions whose failures
are not handeled are annotated with `# NF` (meaning _non-fatal_).
