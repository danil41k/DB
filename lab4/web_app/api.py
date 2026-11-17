from flask import jsonify
from flask import request
import psycopg2


def get_connection():

    return psycopg2.connect(
        host="localhost",
        database="sportsclub",
        user="postgres",
        password="password",
        port=5432
    )


def register_api_routes(app):


    @app.route("/api/members", methods=["GET"])
    def get_members():

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT
                member_id,
                first_name,
                last_name,
                phone,
                email
            FROM members
            ORDER BY member_id
            """
        )

        data = cursor.fetchall()

        result = []

        for row in data:

            result.append(
                {
                    "member_id": row[0],
                    "first_name": row[1],
                    "last_name": row[2],
                    "phone": row[3],
                    "email": row[4]
                }
            )

        cursor.close()
        connection.close()

        return jsonify(result)


    @app.route("/api/members/<int:member_id>", methods=["GET"])
    def get_member(member_id):

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT
                member_id,
                first_name,
                last_name,
                phone,
                email
            FROM members
            WHERE member_id = %s
            """,
            (member_id,)
        )

        row = cursor.fetchone()

        cursor.close()
        connection.close()

        if not row:

            return jsonify(
                {
                    "error": "Member not found"
                }
            ), 404

        return jsonify(
            {
                "member_id": row[0],
                "first_name": row[1],
                "last_name": row[2],
                "phone": row[3],
                "email": row[4]
            }
        )


    @app.route("/api/members", methods=["POST"])
    def create_member():

        data = request.get_json()

        connection = get_connection()
        cursor = connection.cursor()

        cursor.execute(
            """
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
            RETURNING member_id
            """,
            (
                data["first_name"],
                data["last_name"],
                data["birth_date"],
                data["phone"],
                data["email"]
            )
        )

        member_id = cursor.fetchone()[0]

        connection.commit()

        cursor.close()
        connection.close()

        return jsonify(
            {
                "message": "Member created",
                "member_id": member_id
            }
        )


    @app.route("/api/members/<int:member_id>", methods=["DELETE"])
    def delete_member_api(member_id):

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            DELETE FROM members
            WHERE member_id = %s
            """,
            (member_id,)
        )

        connection.commit()

        cursor.close()
        connection.close()

        return jsonify(
            {
                "message": "Member deleted"
            }
        )