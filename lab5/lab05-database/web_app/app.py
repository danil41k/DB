from flask import Flask
from flask import render_template
from flask import request
from flask import redirect
from flask import url_for
from flask import flash

import psycopg2


app = Flask(__name__)

app.secret_key = "sportsclub_secret_key"


def get_connection():

    return psycopg2.connect(
        host="localhost",
        database="sportsclub",
        user="postgres",
        password="password",
        port=5432
    )


@app.route("/")
def index():

    return render_template("index.html")


@app.route("/members")
def members():

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

    members_list = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template(
        "members.html",
        members=members_list
    )


@app.route("/members/add", methods=["GET", "POST"])
def add_member():

    if request.method == "POST":

        first_name = request.form["first_name"]
        last_name = request.form["last_name"]
        birth_date = request.form["birth_date"]
        phone = request.form["phone"]
        email = request.form["email"]

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
            """,
            (
                first_name,
                last_name,
                birth_date,
                phone,
                email
            )
        )

        connection.commit()

        cursor.close()
        connection.close()

        flash("Учасника додано")

        return redirect(
            url_for("members")
        )

    return render_template(
        "add_member.html"
    )


@app.route("/members/delete/<int:member_id>")
def delete_member(member_id):

    connection = get_connection()

    cursor = connection.cursor()

    cursor.execute(
        """
        DELETE FROM members
        WHERE member_id = %s
        """,
        (
            member_id,
        )
    )

    connection.commit()

    cursor.close()
    connection.close()

    flash("Учасника видалено")

    return redirect(
        url_for("members")
    )


if __name__ == "__main__":

    app.run(
        debug=True,
        host="0.0.0.0",
        port=5000
    )