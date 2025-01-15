from faker import Faker
import random

fake = Faker()

# Funkcja do generowania losowego numeru telefonu w polskim formacie
def random_phone():
    return f"+48{random.randint(100000000, 999999999)}"

# Funkcja do generowania losowego adresu
def random_address():
    city_id = random.randint(0, 100)
    street_name = fake.street_name()
    street_number = random.randint(1, 50)
    postal_code = fake.postcode()
    return city_id, street_name, street_number, postal_code

# Generowanie skryptu SQL
def generate_sql_script(n):
    sql_script = []
    for _ in range(n):
        first_name = fake.first_name()
        last_name = fake.last_name()
        phone = random_phone()
        birthdate = fake.date_of_birth(minimum_age=18, maximum_age=33).strftime('%Y-%m-%d')
        email = fake.email()
        city_id, street, street_number, postal_code = random_address()

        sql_script.append(f"EXEC create_student\n    @first_name = '{first_name}',\n    @last_name = '{last_name}',\n    @phone = '{phone}',\n    @birthdate = '{birthdate}',\n    @email = '{email}',\n    @user_id = @user_id OUTPUT;")
        sql_script.append(f"EXEC set_student_address\n    @user_id = @user_id,\n    @CityId = {city_id},\n    @street = '{street}',\n    @streetN = {street_number},\n    @postal_code = '{postal_code}';")

    return "\n".join(sql_script)

# Generowanie 100 studentów
with open("generate_students.sql", "w") as file:
    file.write(generate_sql_script(1000))

print("Skrypt SQL został wygenerowany i zapisany do pliku 'generate_students.sql'.")
