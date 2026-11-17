# Логічна схема бази даних

## Таблиця members

Призначена для зберігання інформації про учасників спортивного клубу.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| member_id | SERIAL | Первинний ключ |
| first_name | VARCHAR(50) | Ім'я учасника |
| last_name | VARCHAR(50) | Прізвище учасника |
| birth_date | DATE | Дата народження |
| phone | VARCHAR(20) | Номер телефону |
| email | VARCHAR(100) | Електронна пошта |
| registration_date | DATE | Дата реєстрації |

---

## Таблиця trainers

Містить інформацію про тренерів клубу.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| trainer_id | SERIAL | Первинний ключ |
| first_name | VARCHAR(50) | Ім'я тренера |
| last_name | VARCHAR(50) | Прізвище тренера |
| specialization | VARCHAR(100) | Напрям тренувань |
| phone | VARCHAR(20) | Телефон |
| salary | NUMERIC(10,2) | Заробітна плата |

---

## Таблиця memberships

Містить інформацію про абонементи.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| membership_id | SERIAL | Первинний ключ |
| membership_name | VARCHAR(100) | Назва абонемента |
| duration_months | INTEGER | Тривалість у місяцях |
| price | NUMERIC(10,2) | Вартість |

---

## Таблиця member_memberships

Таблиця зв’язку між учасниками та абонементами.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| member_membership_id | SERIAL | Первинний ключ |
| member_id | INTEGER | ID учасника |
| membership_id | INTEGER | ID абонемента |
| start_date | DATE | Дата початку |
| end_date | DATE | Дата завершення |

---

## Таблиця training_sessions

Зберігає інформацію про тренування.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| session_id | SERIAL | Первинний ключ |
| trainer_id | INTEGER | ID тренера |
| session_name | VARCHAR(100) | Назва тренування |
| session_date | DATE | Дата проведення |
| start_time | TIME | Час початку |
| end_time | TIME | Час завершення |
| max_participants | INTEGER | Максимальна кількість учасників |

---

## Таблиця attendance

Зберігає інформацію про відвідування тренувань.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| attendance_id | SERIAL | Первинний ключ |
| member_id | INTEGER | ID учасника |
| session_id | INTEGER | ID тренування |

---

## Таблиця equipment

Містить інформацію про спортивне обладнання.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| equipment_id | SERIAL | Первинний ключ |
| equipment_name | VARCHAR(100) | Назва обладнання |
| quantity | INTEGER | Кількість |
| purchase_date | DATE | Дата придбання |
| condition | VARCHAR(30) | Стан |

---

## Таблиця users

Призначена для зберігання користувачів системи.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| user_id | SERIAL | Первинний ключ |
| username | VARCHAR(50) | Логін |
| password_hash | VARCHAR(255) | Пароль |
| email | VARCHAR(100) | Email |
| role | VARCHAR(20) | Роль |
| created_at | TIMESTAMP | Дата створення |

---

## Таблиця activity_log

Таблиця журналу активності користувачів.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| log_id | SERIAL | Первинний ключ |
| user_id | INTEGER | ID користувача |
| action_name | VARCHAR(100) | Назва дії |
| table_name | VARCHAR(100) | Назва таблиці |
| record_id | INTEGER | ID запису |
| action_details | TEXT | Опис дії |
| created_at | TIMESTAMP | Час виконання |

---

## Таблиця member_audit

Призначена для аудиту змін учасників.

| Поле | Тип даних | Опис |
|--------|--------|--------|
| audit_id | SERIAL | Первинний ключ |
| member_id | INTEGER | ID учасника |
| action_type | VARCHAR(20) | Тип операції |
| action_date | TIMESTAMP | Час виконання |

---

# Зв'язки між таблицями

- members → member_memberships (1:M)
- memberships → member_memberships (1:M)
- trainers → training_sessions (1:M)
- members → attendance (1:M)
- training_sessions → attendance (1:M)
- users → activity_log (1:M)
- members → member_audit (1:M)

База даних приведена до третьої нормальної форми (3НФ), що дозволяє уникнути дублювання даних та забезпечує цілісність інформації.