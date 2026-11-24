from database import DatabaseConnection


def show_menu():

    print("\n")
    print("=" * 50)
    print("СПОРТИВНИЙ КЛУБ")
    print("=" * 50)
    print("1. Всі учасники")
    print("2. Додати учасника")
    print("3. Оновити телефон")
    print("4. Видалити учасника")
    print("5. Пошук учасника")
    print("0. Вихід")
    print("=" * 50)

    return input("Ваш вибір: ")


def show_members(db):

    members = db.get_all_members()

    if not members:

        print("Учасники відсутні")

        return

    print()

    for member in members:

        print(
            f"ID: {member[0]} | "
            f"{member[1]} {member[2]} | "
            f"{member[4]} | "
            f"{member[5]}"
        )


def add_member(db):

    first_name = input("Ім'я: ")
    last_name = input("Прізвище: ")
    birth_date = input("Дата народження (YYYY-MM-DD): ")
    phone = input("Телефон: ")
    email = input("Email: ")

    db.add_member(
        first_name,
        last_name,
        birth_date,
        phone,
        email
    )

    print("Учасника додано")


def update_phone(db):

    member_id = int(input("ID учасника: "))
    new_phone = input("Новий телефон: ")

    db.update_member_phone(
        member_id,
        new_phone
    )

    print("Телефон змінено")


def delete_member(db):

    member_id = int(
        input("ID учасника для видалення: ")
    )

    db.delete_member(member_id)

    print("Учасника видалено")


def search_member(db):

    keyword = input("Пошук: ")

    result = db.search_members(keyword)

    for member in result:

        print(
            f"{member[0]} | "
            f"{member[1]} "
            f"{member[2]}"
        )


def main():

    db = DatabaseConnection()

    db.connect()

    while True:

        choice = show_menu()

        if choice == "1":

            show_members(db)

        elif choice == "2":

            add_member(db)

        elif choice == "3":

            update_phone(db)

        elif choice == "4":

            delete_member(db)

        elif choice == "5":

            search_member(db)

        elif choice == "0":

            break

        else:

            print("Невірний вибір")

    db.disconnect()


if __name__ == "__main__":
    main()