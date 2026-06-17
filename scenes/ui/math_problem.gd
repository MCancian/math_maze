extends Control

signal solved
signal wrong_answer

@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var answer_input: LineEdit = $Panel/VBoxContainer/AnswerInput
@onready var submit_button: Button = $Panel/VBoxContainer/SubmitButton

var current_answer: int = 0
var current_question_text := ""
var wrong_answer_message := "Incorrect! Try again."
var _sanitizing_input := false

func _ready() -> void:
    hide()
    submit_button.pressed.connect(_on_submit)
    answer_input.text_submitted.connect(_on_text_submit)
    answer_input.text_changed.connect(_on_answer_text_changed)

func show_problem() -> void:
    var problem := GameManager.math.make_problem()
    current_answer = problem["answer"]
    current_question_text = "What is %s?" % problem["text"]
    question_label.text = current_question_text
    answer_input.text = ""
    show()
    answer_input.grab_focus()

func set_wrong_answer_message(message: String) -> void:
    wrong_answer_message = message

func _on_submit() -> void:
    _check_answer()
    
func _on_text_submit(_new_text: String) -> void:
    _check_answer()

func _on_answer_text_changed(new_text: String) -> void:
    if _sanitizing_input:
        return
    var sanitized := _numbers_and_slashes_only(new_text)
    if sanitized == new_text:
        return
    var caret := answer_input.caret_column
    _sanitizing_input = true
    answer_input.text = sanitized
    answer_input.caret_column = mini(caret, sanitized.length())
    _sanitizing_input = false

func _check_answer() -> void:
    if _answer_matches(answer_input.text):
        hide()
        solved.emit()
    else:
        wrong_answer.emit()
        answer_input.text = ""
        question_label.text = "%s\n%s" % [wrong_answer_message, current_question_text]

func _numbers_and_slashes_only(value: String) -> String:
    var cleaned := ""
    for i in value.length():
        var c := value.substr(i, 1)
        var code := c.unicode_at(0)
        if (code >= 48 and code <= 57) or c == "/":
            cleaned += c
    return cleaned

func _answer_matches(value: String) -> bool:
    if value.is_valid_int():
        return value.to_int() == current_answer
    var parts := value.split("/", false)
    if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
        return false
    var denominator := parts[1].to_int()
    if denominator == 0:
        return false
    return is_equal_approx(float(parts[0].to_int()) / float(denominator), float(current_answer))
