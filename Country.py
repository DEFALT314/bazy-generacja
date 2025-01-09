from faker import Faker
import random

# Inicjalizacja Faker
fake = Faker()

# Rozszerzona mapa państw i ich miast
country_city_map = {
    "Poland": ["Warsaw", "Krakow", "Wroclaw", "Gdansk", "Poznan", "Szczecin", "Lublin", "Katowice", "Lodz", "Bialystok"],
    "Germany": ["Berlin", "Munich", "Frankfurt", "Hamburg", "Stuttgart", "Dresden", "Leipzig", "Cologne", "Dortmund", "Bremen"],
    "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier", "Bordeaux", "Lille"],
    "Italy": ["Rome", "Milan", "Naples", "Turin", "Florence", "Venice", "Genoa", "Bologna", "Verona", "Palermo"],
    "Spain": ["Madrid", "Barcelona", "Seville", "Valencia", "Bilbao", "Malaga", "Zaragoza", "Murcia", "Granada", "Alicante"],
    "Netherlands": ["Amsterdam", "Rotterdam", "Utrecht", "The Hague", "Eindhoven", "Groningen", "Maastricht", "Leeuwarden", "Tilburg", "Breda"],
    "Norway": ["Oslo", "Bergen", "Trondheim", "Stavanger", "Drammen", "Kristiansand", "Fredrikstad", "Tromso", "Sandnes", "Haugesund"],
    "Sweden": ["Stockholm", "Gothenburg", "Malmo", "Uppsala", "Vasteras", "Orebro", "Linkoping", "Helsingborg", "Jonkoping", "Norrkoping"],
    "Denmark": ["Copenhagen", "Aarhus", "Odense", "Aalborg", "Esbjerg", "Randers", "Kolding", "Horsens", "Vejle", "Roskilde"],
    "Finland": ["Helsinki", "Tampere", "Turku", "Oulu", "Lahti", "Kuopio", "Jyvaskyla", "Pori", "Lappeenranta", "Vaasa"],
}

# Liczba państw i miast do wygenerowania
num_countries = 10  # wybierz 10 losowych państw
cities_per_country = 7  # po 7 miast na państwo

# Wybieramy losowe państwa
selected_countries = random.sample(list(country_city_map.keys()), num_countries)

# Generowanie danych dla tabeli Country
countries = []
for i, country_name in enumerate(selected_countries, start=1):
    countries.append((i, country_name))  # (CountryID, CountryName)

# Generowanie danych dla tabeli City
cities = []
city_id = 1
for country_id, country_name in countries:
    available_cities = country_city_map[country_name]
    selected_cities = random.sample(available_cities, cities_per_country)
    for city_name in selected_cities:
        cities.append((city_id, city_name, country_id))  # (CityID, CityName, CountryID)
        city_id += 1

# Tworzenie zapytań SQL
country_sql = "INSERT INTO Country (CountryID, CountryName) VALUES\n" + ",\n".join(
    [f"({c[0]}, '{c[1]}')" for c in countries]
) + ";"

city_sql = "INSERT INTO City (CityID, CityName, CountryID) VALUES\n" + ",\n".join(
    [f"({c[0]}, '{c[1]}', {c[2]})" for c in cities]
) + ";"

# Zapis do pliku SQL
with open("dummy_data_large_countries_cities.sql", "w", encoding="utf-8") as file:
    file.write(country_sql + "\n\n" + city_sql)

print("Dane zostały wygenerowane i zapisane do pliku 'dummy_data_large_countries_cities.sql'.")
