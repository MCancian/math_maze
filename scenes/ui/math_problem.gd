extends Control

signal solved

@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var answer_input: LineEdit = $Panel/VBoxContainer/AnswerInput
@onready var submit_button: Button = $Panel/VBoxContainer/SubmitButton

var current_answer: int = 0

func _ready() -> void:
    hide()
    submit_button.pressed.connect(_on_submit)
    answer_input.text_submitted.connect(_on_text_submit)

func show_problem() -> void:
    var problem := GameManager.math.make_problem()
    current_answer = problem["answer"]
    question_label.text = "What is %s?" % problem["text"]
    answer_input.text = ""
    show()
    answer_input.grab_focus()

func _on_submit() -> void:
    _check_answer()
    
func _on_text_submit(new_text: String) -> void:
    _check_answer()

func _check_answer() -> void:
    if answer_input.text.is_valid_int() and answer_input.text.to_int() == current_answer:
        hide()
        solved.emit()
    else:
        answer_input.text = ""
        question_label.text = "Incorrect! Try again."
