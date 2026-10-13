class_name UiFormat

const UNITS: PackedStringArray = ["K", "M", "B"]

## Abrevia un número a 5 caracteres como máximo: hasta 9999 tal cual, luego 12.3K, 123K, 1.2M...
## Trunca en vez de redondear para no pasar de 999.9K a "1000K".
@warning_ignore("integer_division")
static func abbreviate(amount: int) -> String:
	if amount < 10000:
		return str(amount)
	var divisor := 1000
	for unit in UNITS:
		var whole := amount / divisor
		if whole < 1000 or unit == UNITS[-1]:
			var tenth := (amount % divisor) * 10 / divisor
			if whole < 100 and tenth > 0:
				return "%d.%d%s" % [whole, tenth, unit]
			return "%d%s" % [whole, unit]
		divisor *= 1000
	return str(amount)
