# Анализ потоков данных (DFA)

## 1. Цепочки Def-Use
* **Переменная: log_entry**
  * Def: Строка 2 (`log_entry = "Start processing"`), строка 10 (`log_entry = "Transaction finished..."`)
  * Use: Строка 11 (`file.write(log_entry)`)
* **Переменная: status**
  * Def: Строка 4 (`status = "approved"`)
  * Use: Строка 10 (конкатенация строк), строка 13 (`return status`)
* **Переменная: balance**
  * Def: Строка 5 (`balance = get_balance(user_id)`)
  * Use: Строка 6 (`new_balance = balance - amount`)
* **Переменная: new_balance**
  * Def: Строка 6 (`new_balance = balance - amount`)
  * Use: Строка 7 (`update_balance(user_id, new_balance)`)
* **Переменная: file**
  * Def: Строка 11 (`file = open(...)`)
  * Use: Строка 12 (`file.write(...)`)

## 2. Выявленные дефекты
* **Дефект 1 (Неинициализированная переменная):** Если `amount <= 0`, блок `if` не выполняется, переменная `status` не создается. При попытке сделать `return status` (строка 13) возникнет ошибка `UnboundLocalError`.
* **Дефект 2 (Мертвое присваивание):** Переменной `log_entry` в строке 2 присваивается значение `"Start processing"`, но оно нигде не читается, так как в строке 10 переменная перезаписывается новым значением.
* **Дефект 3 (Утечка ресурса):** Файл открывается в строке 11 (`file = open(...)`), но нигде не вызывается `file.close()`. Это приводит к утечке памяти и блокировке файла.
