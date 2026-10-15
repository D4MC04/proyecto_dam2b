class_name UiFormat

const UNITS: PackedStringArray = ["K", "M", "B"]

## Abrevia un número a 6 caracteres como máximo: hasta 999 tal cual; desde 1000 en K, M o B con un
## decimal sin ".0": 1000 -> 1K, 1100 -> 1.1K, 12345 -> 12.3K, 999999 -> 999.9K, 1250000 -> 1.2M.
## Trunca en vez de redondear para no pasar de 999.9K a "1000K".
@warning_ignore("integer_division")
static func abbreviate(amount: int) -> String:
	if amount < 1000:
		return str(amount)
	var divisor := 1000
	for unit in UNITS:
		var whole := amount / divisor
		if whole < 1000 or unit == UNITS[-1]:
			var tenth := (amount % divisor) * 10 / divisor
			if tenth > 0:
				return "%d.%d%s" % [whole, tenth, unit]
			return "%d%s" % [whole, unit]
		divisor *= 1000
	return str(amount)

## Dinero: el número abreviado con el €, como mucho 7 caracteres: 999€, 1K€, 1.1K€, 12.3K€.
static func money(amount: int) -> String:
	return abbreviate(amount) + "€"

## Número de un stat: con un decimal como mucho (sin ceros sobrantes) por debajo de 100; si no, abreviado.
static func number(value: float) -> String:
	if value < 100.0 and not is_equal_approx(value, roundf(value)):
		return _decimals(value, 1)
	return abbreviate(roundi(value))

## Segundos con 2 decimales como mucho, sin ceros sobrantes y en 5 caracteres como máximo: 0.25s, 1.5s, 5s.
static func seconds(value: float) -> String:
	for decimals: int in [2, 1, 0]:
		var text := _decimals(value, decimals) + "s"
		if text.length() <= 5:
			return text
	# Más de 9999 s: abreviado y sin decimal para no pasar de 5 caracteres.
	var whole := abbreviate(roundi(value))
	if whole.contains("."):
		whole = whole.get_slice(".", 0) + whole.right(1)
	return whole + "s"

# Redondea a `decimals` decimales y quita los ceros sobrantes (1.50 -> 1.5, 2.00 -> 2).
static func _decimals(value: float, decimals: int) -> String:
	var text := "%.*f" % [decimals, value]
	if text.contains("."):
		text = text.rstrip("0").trim_suffix(".")
	return text
