extends Resource
class_name MathConfig
## Controls ONLY the math problems (independent of maze difficulty).
## Authored as .tres in data/math/. Read by math_problem.gd via GameManager.math.

enum Mode {
    ADD,          ## single-digit addition
    MUL,          ## single-digit multiplication
    FRACTION_OF,  ## "n/d of W = ?", whole-number answer
}

@export var display_name: String = "Addition"
@export var mode: Mode = Mode.ADD
## Largest operand for ADD/MUL (single digit = 9).
@export var max_digit: int = 9
## Denominators allowed for FRACTION_OF problems.
@export var fraction_denoms: Array[int] = [2, 3, 4]

## Returns {"text": String, "answer": int}. Answer is always a whole number.
func make_problem() -> Dictionary:
    match mode:
        Mode.MUL:
            var a := randi_range(1, max_digit)
            var b := randi_range(1, max_digit)
            return {"text": "%d × %d" % [a, b], "answer": a * b}
        Mode.FRACTION_OF:
            var d: int = fraction_denoms[randi() % fraction_denoms.size()]
            var num := randi_range(1, d - 1)        # proper fraction
            var mult := randi_range(2, 6)           # so the whole divides evenly
            var whole := d * mult
            return {"text": "%d/%d of %d" % [num, d, whole], "answer": num * mult}
        _:
            var x := randi_range(1, max_digit)
            var y := randi_range(1, max_digit)
            return {"text": "%d + %d" % [x, y], "answer": x + y}
