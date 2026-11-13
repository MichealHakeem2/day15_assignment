import urllib.request
import json
import time
import os

token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZjZkNDExY2UyMTQ0MmE3NjNiYmQ3YSIsImlhdCI6MTc5NDU2MTA0MiwiZXhwIjoxNzk3MTUzMDQyfQ.bM_GwTQJ9tB6oZrC6f3KpZq_b-itgooACp1Vm00Fqtg'
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}
base = 'https://supermarket-dan1.onrender.com/api/v1'

os.makedirs('api/data', exist_ok=True)

def fetch_url(url):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f'Rate limited on {url}, waiting 3s...')
                time.sleep(3)
                continue
            print(f'HTTP {e.code} on {url}')
            return None
        except Exception as e:
            print(f'Error fetching {url}: {e}')
            time.sleep(2)
    return None

print('=== 1. Extracting Products ===')
all_products = []
skip = 0
limit = 50
while True:
    data = fetch_url(f'{base}/home/products?skip={skip}&limit={limit}')
    if not data or 'list' not in data or not data['list']:
        break
    items = data['list']
    all_products.extend(items)
    total = data.get('total', 'unknown')
    print(f'Fetched batch {skip}..{skip + len(items)} (total collected: {len(all_products)} / {total})')
    if len(items) < limit:
        break
    skip += limit
    time.sleep(0.5)

print(f'Total products extracted: {len(all_products)}')
with open('api/data/products.json', 'w', encoding='utf-8') as f:
    json.dump(all_products, f, ensure_ascii=False, indent=2)

print('=== 2. Extracting Categories ===')
cats = fetch_url(f'{base}/home/categories')
if cats:
    cat_list = cats.get('list', cats) if isinstance(cats, dict) else cats
    print(f'Total categories extracted: {len(cat_list)}')
    with open('api/data/categories.json', 'w', encoding='utf-8') as f:
        json.dump({'list': cat_list}, f, ensure_ascii=False, indent=2)

print('=== 3. Extracting Brands ===')
brands = fetch_url(f'{base}/home/brands')
if brands:
    brand_list = brands.get('list', brands) if isinstance(brands, dict) else brands
    print(f'Total brands extracted: {len(brand_list)}')
    with open('api/data/brands.json', 'w', encoding='utf-8') as f:
        json.dump({'list': brand_list}, f, ensure_ascii=False, indent=2)

print('=== 4. Extracting User Profile ===')
profile = fetch_url(f'{base}/portfoilo/userData')
if profile and 'message' in profile:
    u = profile['message']
    name = u.get("name")
    email = u.get("email")
    print(f'User profile extracted: {name} <{email}>')
    with open('api/data/users_seed.json', 'w', encoding='utf-8') as f:
        json.dump([u], f, ensure_ascii=False, indent=2)

print('=== Extraction Completed Successfully! ===')
