from faker import Faker
import numpy as np
import random

fake = Faker()

list_of_domains = (
    'gmail.com',
    'hotmail.com',
    'yahoo.com',
    'msn.com',
    'outlook.com'
)

for j in range(1000):
    name = fake.name()
    year = int(min(max(np.random.normal(1990, 5), 1965), 2005))
    month = random.randint(1, 12)
    if month in [1,3,5,7,8,10,12]:
        day = random.randint(1, 31)
    elif month != 2:
        day = random.randint(1, 30)
    elif year % 4 != 0:
        day = random.randint(1, 28)
    else:
        day = random.randint(1, 29)
    
    phone = ''.join([random.choice('1234567890') for i in range(9)])
    
    fn, ln = name.split(' ')
    email = f'{fn.lower()}.{ln.lower()}@{random.choice(list_of_domains)}'
    if random.random() < 0.99:
        active = True
    else:
        active = False
    
    print(active)