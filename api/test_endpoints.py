import urllib.request, json

BASE = 'http://localhost:5000/api/v1'

# 1. Products
r = urllib.request.urlopen(f'{BASE}/home/products?limit=3')
data = json.loads(r.read())
total = data.get('total', 0)
items = data.get('list', [])
print(f'=== PRODUCTS === Total: {total}, Returned: {len(items)}')
for p in items:
    pid = p.get('id', '?')
    title = p.get('title', '')[:50]
    print(f'  id={pid}, title={title}')

# 2. Categories
r = urllib.request.urlopen(f'{BASE}/home/categories')
data = json.loads(r.read())
cats = data.get('list', [])
print(f'\n=== CATEGORIES === Count: {len(cats)}')

# 3. Brands
r = urllib.request.urlopen(f'{BASE}/home/brands')
data = json.loads(r.read())
brands = data.get('list', [])
print(f'=== BRANDS === Count: {len(brands)}')

# 4. Sign in to get token
payload = json.dumps({'email': 'flutteruser2026@test.com', 'password': 'Pass@1234'}).encode()
req = urllib.request.Request(f'{BASE}/auth/signIn', data=payload, headers={'Content-Type': 'application/json'})
r = urllib.request.urlopen(req)
signin_data = json.loads(r.read())
token = signin_data['token']
print(f'\n=== TOKEN === {token[:40]}...')

# 5. Add to Cart
payload = json.dumps({'productId': 1}).encode()
req = urllib.request.Request(f'{BASE}/user/addCart', data=payload, headers={
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
})
r = urllib.request.urlopen(req)
data = json.loads(r.read())
print(f'\n=== ADD CART === {data.get("message")}')
print(f'  Cart items: {len(data.get("list", []))}')

# 6. Get Cart
req = urllib.request.Request(f'{BASE}/user/getCart', headers={'Authorization': f'Bearer {token}'})
r = urllib.request.urlopen(req)
data = json.loads(r.read())
cart_items = data.get('list', [])
print(f'\n=== GET CART === Items: {len(cart_items)}')
for item in cart_items:
    print(f'  productId={item.get("productId")}, title={item.get("title","")[:30]}, qty={item.get("quantity")}')

# 7. Add Favorite
payload = json.dumps({'productId': 2}).encode()
req = urllib.request.Request(f'{BASE}/user/addFavorite', data=payload, headers={
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
})
r = urllib.request.urlopen(req)
data = json.loads(r.read())
print(f'\n=== ADD FAVORITE === {data.get("message")}')
print(f'  Favorites: {len(data.get("list", []))}')

# 8. Get Favorites
req = urllib.request.Request(f'{BASE}/user/getFavorite', headers={'Authorization': f'Bearer {token}'})
r = urllib.request.urlopen(req)
data = json.loads(r.read())
favs = data.get('list', [])
print(f'\n=== GET FAVORITES === Items: {len(favs)}')
for fav in favs:
    pid = fav.get('id', fav.get('productId', '?'))
    title = fav.get('title', '')[:30]
    print(f'  id={pid}, title={title}')

# 9. Get user profile
req = urllib.request.Request(f'{BASE}/portfoilo/userData', headers={'Authorization': f'Bearer {token}'})
r = urllib.request.urlopen(req)
data = json.loads(r.read())
msg = data.get('message', {})
print(f'\n=== USER PROFILE ===')
print(f'  name={msg.get("name")}, email={msg.get("email")}, phone={msg.get("phone")}')

# 10. Delete Cart item
payload = json.dumps({'productId': 1}).encode()
req = urllib.request.Request(f'{BASE}/user/deleteCart', data=payload, headers={
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
}, method='DELETE')
r = urllib.request.urlopen(req)
data = json.loads(r.read())
print(f'\n=== DELETE CART === {data.get("message")}, remaining: {len(data.get("list",[]))}')

# 11. Delete Favorite
payload = json.dumps({'productId': 2}).encode()
req = urllib.request.Request(f'{BASE}/user/deleteFavorite', data=payload, headers={
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
}, method='DELETE')
r = urllib.request.urlopen(req)
data = json.loads(r.read())
print(f'\n=== DELETE FAVORITE === {data.get("message")}, remaining: {len(data.get("list",[]))}')

print('\n✅ ALL ENDPOINTS TESTED SUCCESSFULLY')

