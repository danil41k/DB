from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import (
    SimpleDocTemplate,
    Table,
    TableStyle,
    Paragraph,
    Spacer
)
from reportlab.lib.styles import getSampleStyleSheet


def create_members_report(
    members,
    filename="members_report.pdf"
):

    document = SimpleDocTemplate(
        filename,
        pagesize=A4
    )

    styles = getSampleStyleSheet()

    elements = []

    title = Paragraph(
        "Звіт про учасників спортивного клубу",
        styles["Title"]
    )

    elements.append(title)

    elements.append(
        Spacer(
            1,
            20
        )
    )

    data = [
        [
            "ID",
            "Ім'я",
            "Прізвище",
            "Телефон",
            "Email"
        ]
    ]

    for member in members:

        data.append(
            [
                str(member[0]),
                member[1],
                member[2],
                member[3],
                member[4]
            ]
        )

    table = Table(data)

    table.setStyle(
        TableStyle(
            [
                (
                    "BACKGROUND",
                    (0, 0),
                    (-1, 0),
                    colors.blue
                ),
                (
                    "TEXTCOLOR",
                    (0, 0),
                    (-1, 0),
                    colors.white
                ),
                (
                    "GRID",
                    (0, 0),
                    (-1, -1),
                    1,
                    colors.black
                )
            ]
        )
    )

    elements.append(table)

    document.build(elements)

    return filename