from faker import Faker
import random
import pickle
import os
import re

fake = Faker()
email_file = "generated_emails.pkl"

# Load existing emails if the file exists
if os.path.exists(email_file):
    with open(email_file, "rb") as f:
        generated_emails = pickle.load(f)
else:
    generated_emails = set()  # Global set to store generated emails

def is_valid_email(email):
    # Ensure email matches the pattern '%_@__%._%' and is 20 characters or shorter
    pattern = r'^.+@..+\..+$'
    return re.match(pattern, email) is not None and len(email) <= 20

def get_unique_email():
    global generated_emails
    while True:
        local_part = fake.user_name()[:10]  # Maksymalnie 10 znaków dla części przed @
        domain = fake.domain_name()
        
        email = f"{local_part}@{domain}"
        # Skróć domenę najwyższego poziomu, jeśli email jest za długi
        if len(email) > 20:
            domain_parts = domain.split('.')
            domain_parts[-1] = domain_parts[-1][:2]  # Przytnij TLD do maks. 2 znaków
            email = f"{local_part}@{'.'.join(domain_parts)}"
        
        # Final validation and uniqueness check
        if email not in generated_emails and is_valid_email(email):
            generated_emails.add(email)
            return email

class StudentSQLGenerator:
    def random_phone(self):
        return f"+48{random.randint(100000000, 999999999)}"

    def random_address(self):
        city_id = random.randint(1, 100)
        street_name = fake.street_name()
        street_number = random.randint(1, 50)
        postal_code = fake.postcode()
        return city_id, street_name, street_number, postal_code

    def generate_sql_script(self, n):
        sql_script = []
        for _ in range(n):
            first_name = fake.first_name()
            last_name = fake.last_name()
            phone = self.random_phone()
            birthdate = fake.date_of_birth(minimum_age=18, maximum_age=33).strftime('%Y-%m-%d')
            email = get_unique_email()
            city_id, street, street_number, postal_code = self.random_address()

            sql_script.append(f"EXEC create_student\n    @first_name = '{first_name}',\n    @last_name = '{last_name}',\n    @phone = '{phone}',\n    @birthdate = '{birthdate}',\n    @email = '{email}',\n    @user_id = @user_id OUTPUT;")
            sql_script.append(f"EXEC set_student_address\n    @user_id = @user_id,\n    @CityId = {city_id},\n    @street = '{street}',\n    @streetN = {street_number},\n    @postal_code = '{postal_code}';")

        return "\n".join(sql_script)

# Generowanie 500 studentów
student_generator = StudentSQLGenerator()

with open("/home/defalt/bazy/students.sql", "w") as file:
    file.write(student_generator.generate_sql_script(500))

# Save the generated emails to a file
with open(email_file, "wb") as f:
    pickle.dump(generated_emails, f)

print("Plik SQL 'students.sql' został wygenerowany.")
