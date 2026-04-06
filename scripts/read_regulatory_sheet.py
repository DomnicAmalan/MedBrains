import openpyxl

wb = openpyxl.load_workbook('/Users/apple/Projects/MedBrains/MedBrains_Features.xlsx', data_only=True)
ws = wb['Regulatory & Compliance']

for row in ws.iter_rows(min_row=1, max_col=8, values_only=False):
    r = row[0].row
    sno = row[0].value
    mod = str(row[1].value or "")
    sub = str(row[2].value or "")
    feat = str(row[3].value or "")
    status = str(row[6].value or "")
    print(f"R{r:3d} | S.No={str(sno):5s} | {mod:12s} | {sub:45s} | {feat:90s} | {status}")
