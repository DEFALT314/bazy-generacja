# Generowanie instrukcji SQL
with open("assign_languages.sql", "w") as file:
    for translator_id in range(21, 41):  # ID tłumaczy od 21 do 40
        for language_id in range(1, 6):  # Języki od 1 do 5
            sql = f"INSERT INTO TranslationDetails (TranslatorID, LanguageID) VALUES ({translator_id}, {language_id});\n"
            file.write(sql)

print("Plik SQL 'assign_languages.sql' został wygenerowany.")
