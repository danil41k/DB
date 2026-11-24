"""Збирає docs/report.md з docs/report_template.md, підставляючи код із lab05/*.sql.
Маркер {{sql:ім'я_файлу}} замінюється на блок коду. Запуск: python tools/build_report.py"""
import re, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
tpl = (root / "docs" / "report_template.md").read_text(encoding="utf-8")

def repl(m):
    name = m.group(1)
    code = (root / "lab05" / name).read_text(encoding="utf-8").rstrip()
    return f"```sql\n{code}\n```"

out = re.sub(r"\{\{sql:([^}]+)\}\}", repl, tpl)
(root / "docs" / "report.md").write_text(out, encoding="utf-8")
print("docs/report.md збережено,", len(out.splitlines()), "рядків")
