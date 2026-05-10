# AuroBool
A boolean algebra utility tool written in Mercury.

## How to use
```
git clone https://github.com/Aurorasphere/AuroBool && cd AuroBool
make
./aurobool -s "A(A+B)"
```

## Options & Features
Every options cannot be used with other options except `--verbose` and `-v`. You can't use two or more than two primary options at the same time. For instance, if you use `-s`, you can't use `-sop`, `-pos`, etc.  

- `-h`, `--help`: Print the help message.
- `--version`: Print the license info and current version. 
- `-s`: Simplify the boolean expression. e.g.) `aurobool -s "ABC'D' + A'B'C + (AB)'C + BCD"`
- `--sop`: Convert the given boolean expression to standard SOP form. e.g.) `aurobool -sop "(A+B'+C)(A'+B)"`
- `--pos`: Convert the given boolean expression to standard POS form. e.g.) `aurobool -pos "ABC + A'B"`
- `--verbose`: Print all the steps of the operation and applied rules. e.g.) `aurobool --verbose -sop "A+B"`
- `--nand`: Convert the given boolean expression to NAND-Only form. e.g.) `aurobool --nand "A+B"`
- `--nor`: Convert the given boolean expression to NOR-Only form. e.g.) `aurobool --nor "AB"`
- `-e`, `--eval`: Evaluate the boolean expression with given variable assignments. e.g.) `aurobool -e "AB'+A'C, A = 1, B = 0, C = 1"`
- `-t`, `--truth`: Print the truth table of the given boolean expression. e.g.) `aurobool --truth "A+B"`
- `--eq`: Check if two boolean expressions are mathematically equivalent. e.g.) `aurobool --eq "AB'+A'C, (A+B')(A'+C)"`
## Syntax
### Variables 
AuroBool support 26 ('A'-'Z') maximum variables. Variables are not case sensitive and uses uppercases as default. Every lowercase letter will be converted to uppercase letter internally.

### Constants
The constant TRUE is represented as "1" and the constant FALSE is represented as "0". For the simplicity of input, only '1' and '0' can be used as constants, and logic representations like 'T', 'F', 'true', 'false', etc are not supported.

### Logic Expression
AuroBool uses engineering notation to represent boolean expressions. AND operation is juxtaposed, OR operation is written as '`+`', and NOT operation is written as "`'`". If you want to negate multiple variables, use parentheses to group them. e.g.) "`(ABC)'`".

Other than AND, OR, NOT, you can also use XOR, XNOR, NAND, NOR. But these operations will be converted to AND, OR, NOT internally. These operations uses Verilog-like notations. NAND is written as '`~&`', NOR is '`~|`', XOR is '`^`', XNOR is '`^~`'. I don't recommend use these operations since they can be easily converted to the combinations of AND, OR, NOT. Check the table below for the reference.

| Type of Operation | Shorthand Expr. (Supprort) | AuroBool Expr. (Recommended) |
| :--- | :--- | :--- |
| XOR | `A ^ B` | `(AB') + (A'B)` |
| XNOR | `A ~^ B` | `AB + A'B'` |
| NAND | `A ~& B` | `(AB)'` |
| NOR | `A ~\| B` | `(A + B)'` |

### Order of Precedence
0. Parentheses
1. NOT (`'`)
2. AND (` `), NAND (`~&`)
3. OR (`+`), NOR (`~|`), XOR (`^`), XNOR (`~^`)

### Example Usage

#### Basic Simplification
```bash
$ aurobool -s "A'B'C+A'BC+AB'C"
# A'C + B'C
```
