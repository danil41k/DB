import psycopg2


class DatabaseConnection:

    def __init__(
        self,
        dbname='sportsclub',
        user='postgres',
        password='password',
        host='localhost',
        port=5432
    ):

        self.connection = None

        self.connection_parameters = {
            "dbname": dbname,
            "user": user,
            "password": password,
            "host": host,
            "port": port
        }

    def connect(self):

        try:

            self.connection = psycopg2.connect(
                **self.connection_parameters
            )

            print("Підключення до бази даних успішне")

        except Exception as error:

            print("Помилка підключення:")
            print(error)

    def disconnect(self):

        if self.connection:

            self.connection.close()

            print("З'єднання закрито")

    def execute_query(self, query, parameters=None):

        try:

            cursor = self.connection.cursor()

            cursor.execute(query, parameters)

            self.connection.commit()

            return cursor

        except Exception as error:

            self.connection.rollback()

            print("Помилка SQL:")
            print(error)

            return None

    def get_all_members(self):

        query = """
        SELECT
            member_id,
            first_name,
            last_name,
            birth_date,
            phone,
            email
        FROM members
        ORDER BY member_id
        """

        cursor = self.execute_query(query)

        if cursor:
            return cursor.fetchall()

        return []

    def add_member(
        self,
        first_name,
        last_name,
        birth_date,
        phone,
        email
    ):

        query = """
        INSERT INTO members
        (
            first_name,
            last_name,
            birth_date,
            phone,
            email
        )
        VALUES
        (
            %s,
            %s,
            %s,
            %s,
            %s
        )
        """

        self.execute_query(
            query,
            (
                first_name,
                last_name,
                birth_date,
                phone,
                email
            )
        )

    def update_member_phone(
        self,
        member_id,
        phone
    ):

        query = """
        UPDATE members
        SET phone = %s
        WHERE member_id = %s
        """

        self.execute_query(
            query,
            (
                phone,
                member_id
            )
        )

    def delete_member(self, member_id):

        query = """
        DELETE FROM members
        WHERE member_id = %s
        """

        self.execute_query(
            query,
            (
                member_id,
            )
        )

    def search_members(self, keyword):

        query = """
        SELECT
            member_id,
            first_name,
            last_name,
            phone,
            email
        FROM members
        WHERE
            LOWER(first_name) LIKE LOWER(%s)
            OR
            LOWER(last_name) LIKE LOWER(%s)
        """

        search_value = f"%{keyword}%"

        cursor = self.execute_query(
            query,
            (
                search_value,
                search_value
            )
        )

        if cursor:

            return cursor.fetchall()

        return []