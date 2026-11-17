import io
import base64

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt


def membership_chart(data):

    labels = []
    values = []

    for row in data:

        labels.append(row[0])

        values.append(row[1])

    plt.figure(
        figsize=(10, 6)
    )

    plt.bar(
        labels,
        values
    )

    plt.title(
        "Кількість абонементів"
    )

    plt.xlabel(
        "Тип абонемента"
    )

    plt.ylabel(
        "Кількість"
    )

    buffer = io.BytesIO()

    plt.savefig(
        buffer,
        format="png"
    )

    buffer.seek(0)

    image_png = buffer.getvalue()

    buffer.close()

    graph = base64.b64encode(
        image_png
    )

    graph = graph.decode("utf-8")

    plt.close()

    return graph