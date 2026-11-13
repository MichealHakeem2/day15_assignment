import urllib.request
import urllib.parse
import json
import os
import sys

BASE_URL = 'http://localhost:5000'
API_V1 = f'{BASE_URL}/api/v1'

results = []

def record(test_name, method, url, status_code, success, req_body=None, res_body=None, error=None):
    res_serialized = res_body
    if isinstance(res_body, bytes):
        res_serialized = f"<bytes: {len(res_body)} bytes>"

    results.append({
        'test': test_name,
        'method': method,
        'url': url,
        'status_code': status_code,
        'success': success,
        'req_body': req_body,
        'res_body': res_serialized,
        'error': error
    })
    mark = "✅ PASS" if success else "❌ FAIL"
    print(f"[{mark}] {test_name} ({method} {url}) -> HTTP {status_code}")
    if not success and error:
        print(f"       Error: {error}")

def make_request(method, url, data=None, headers=None, is_json=True):
    if headers is None:
        headers = {}
    body_bytes = None
    if data is not None:
        if is_json:
            body_bytes = json.dumps(data).encode('utf-8')
            headers['Content-Type'] = 'application/json'
        else:
            body_bytes = data

    req = urllib.request.Request(url, data=body_bytes, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            raw = response.read()
            parsed = None
            try:
                res_text = raw.decode('utf-8')
                parsed = json.loads(res_text)
            except Exception:
                parsed = raw if not is_json else raw.decode('utf-8', errors='ignore')
            return response.status, parsed, response.headers
    except urllib.error.HTTPError as e:
        raw = e.read()
        parsed = None
        try:
            res_text = raw.decode('utf-8')
            parsed = json.loads(res_text)
        except Exception:
            parsed = raw if not is_json else raw.decode('utf-8', errors='ignore')
        return e.code, parsed, e.headers
    except Exception as e:
        return 0, str(e), {}

print("==================================================")
print("🚀 RUNNING COMPREHENSIVE API TEST SUITE (STEP 1)")
print("==================================================")

# --- 1. CORS Preflight Check ---
status, body, hdrs = make_request('OPTIONS', f'{API_V1}/home/products', headers={
    'Origin': 'http://localhost:3000',
    'Access-Control-Request-Method': 'GET'
})
cors_header = hdrs.get('Access-Control-Allow-Origin', '')
record(
    'CORS Configuration for Flutter Web',
    'OPTIONS',
    f'{API_V1}/home/products',
    status,
    status in [200, 204] and ('*' in cors_header or 'localhost' in cors_header),
    req_body={'Origin': 'http://localhost:3000'},
    res_body={'Access-Control-Allow-Origin': cors_header}
)

# --- 2. Products Catalog Verification ---
status, body, _ = make_request('GET', f'{API_V1}/home/products?skip=0&limit=200')
total = body.get('total') if isinstance(body, dict) else 0
products_list = body.get('list', []) if isinstance(body, dict) else []
first_prod = products_list[0] if products_list else {}
last_prod = products_list[-1] if products_list else {}

prod_valid = (
    status == 200 and total == 194 and len(products_list) == 194 and
    first_prod.get('id') == 1 and bool(first_prod.get('price')) and bool(first_prod.get('category'))
)
record(
    'All 194 Products Catalog Fetch',
    'GET',
    f'{API_V1}/home/products?skip=0&limit=200',
    status,
    prod_valid,
    res_body={'total': total, 'count': len(products_list), 'first_id': first_prod.get('id'), 'last_id': last_prod.get('id')}
)

# Product by ID
status, body, _ = make_request('GET', f'{API_V1}/home/products/1')
record(
    'Single Product by ID (ID: 1)',
    'GET',
    f'{API_V1}/home/products/1',
    status,
    status == 200 and isinstance(body, dict) and body.get('id') == 1 and 'title' in body,
    res_body={'id': body.get('id') if isinstance(body, dict) else None, 'title': body.get('title') if isinstance(body, dict) else None}
)

# Products Filter / Search
search_body = {'search': 'mascara', 'skip': 0, 'limit': 10}
status, body, _ = make_request('POST', f'{API_V1}/home/productsFilter', data=search_body)
record(
    'Products Search/Filter (Search: mascara)',
    'POST',
    f'{API_V1}/home/productsFilter',
    status,
    status == 200 and isinstance(body, dict) and body.get('total', 0) >= 1,
    req_body=search_body,
    res_body={'total': body.get('total') if isinstance(body, dict) else None}
)

# --- 3. Categories and Brands Verification ---
status, body, _ = make_request('GET', f'{API_V1}/home/categories')
cat_list = body.get('list', []) if isinstance(body, dict) else []
record(
    'All 24 Categories Fetch',
    'GET',
    f'{API_V1}/home/categories',
    status,
    status == 200 and len(cat_list) == 24,
    res_body={'count': len(cat_list), 'first': cat_list[0].get('name') if cat_list else None}
)

status, body, _ = make_request('GET', f'{API_V1}/home/brands')
brand_list = body.get('list', []) if isinstance(body, dict) else []
record(
    'All 14 Brands Fetch',
    'GET',
    f'{API_V1}/home/brands',
    status,
    status == 200 and len(brand_list) == 14,
    res_body={'count': len(brand_list), 'first': brand_list[0].get('name') if brand_list else None}
)

# --- 4. Authentication (Sign Up, Sign In, Password Reset) ---
# Sign In with Seed User
signin_data = {'email': 'flutteruser2026@test.com', 'password': 'Pass@1234'}
status, body, _ = make_request('POST', f'{API_V1}/auth/signIn', data=signin_data)
token = body.get('token') if isinstance(body, dict) else None
record(
    'Auth Sign In (flutteruser2026@test.com)',
    'POST',
    f'{API_V1}/auth/signIn',
    status,
    status == 200 and token is not None,
    req_body=signin_data,
    res_body={'message': body.get('message') if isinstance(body, dict) else None, 'token_received': token is not None}
)

auth_headers = {'Authorization': f'Bearer {token}'}

# Password Reset Flow
status, body, _ = make_request('POST', f'{API_V1}/auth/resetPassCode', data={'email': 'flutteruser2026@test.com'})
code = body.get('code') if isinstance(body, dict) else None
record(
    'Password Reset - Request Code',
    'POST',
    f'{API_V1}/auth/resetPassCode',
    status,
    status == 200 and code is not None,
    req_body={'email': 'flutteruser2026@test.com'},
    res_body={'code_generated': bool(code)}
)

if code:
    status, body, _ = make_request('POST', f'{API_V1}/auth/activeResetPass', data={'email': 'flutteruser2026@test.com', 'code': code})
    record(
        'Password Reset - Verify Code',
        'POST',
        f'{API_V1}/auth/activeResetPass',
        status,
        status == 200,
        req_body={'email': 'flutteruser2026@test.com', 'code': code},
        res_body=body
    )

# --- 5. Cart CRUD Endpoints ---
# Add Item 1 to Cart
add_cart_1 = {'productId': 1, 'quantity': 2}
status, body, _ = make_request('POST', f'{API_V1}/user/addCart', data=add_cart_1, headers=auth_headers)
record(
    'Cart - Add Product (ID: 1, Qty: 2)',
    'POST',
    f'{API_V1}/user/addCart',
    status,
    status == 200 and any(item.get('productId') == 1 for item in body.get('list', [])),
    req_body=add_cart_1,
    res_body={'items_count': len(body.get('list', [])) if isinstance(body, dict) else 0}
)

# Add Item 2 to Cart
add_cart_2 = {'productId': 2, 'quantity': 1}
status, body, _ = make_request('POST', f'{API_V1}/user/addCart', data=add_cart_2, headers=auth_headers)
record(
    'Cart - Add Product (ID: 2, Qty: 1)',
    'POST',
    f'{API_V1}/user/addCart',
    status,
    status == 200 and any(item.get('productId') == 2 for item in body.get('list', [])),
    req_body=add_cart_2,
    res_body={'items_count': len(body.get('list', [])) if isinstance(body, dict) else 0}
)

# Get Cart
status, body, _ = make_request('GET', f'{API_V1}/user/getCart', headers=auth_headers)
cart_list = body.get('list', []) if isinstance(body, dict) else []
record(
    'Cart - Retrieve User Cart',
    'GET',
    f'{API_V1}/user/getCart',
    status,
    status == 200 and len(cart_list) >= 2,
    res_body={'items_count': len(cart_list), 'first_item': cart_list[0] if cart_list else None}
)

# Delete Item from Cart
del_cart = {'productId': 1}
status, body, _ = make_request('DELETE', f'{API_V1}/user/deleteCart', data=del_cart, headers=auth_headers)
record(
    'Cart - Remove Product (ID: 1)',
    'DELETE',
    f'{API_V1}/user/deleteCart',
    status,
    status == 200 and all(item.get('productId') != 1 for item in body.get('list', [])),
    req_body=del_cart,
    res_body={'items_count': len(body.get('list', [])) if isinstance(body, dict) else 0}
)

# --- 6. Favorites CRUD Endpoints ---
# Add Favorite
add_fav = {'productId': 3}
status, body, _ = make_request('POST', f'{API_V1}/user/addFavorite', data=add_fav, headers=auth_headers)
record(
    'Favorites - Add Product (ID: 3)',
    'POST',
    f'{API_V1}/user/addFavorite',
    status,
    status == 200 and any((item.get('id') == 3 or item.get('productId') == 3) for item in body.get('list', [])),
    req_body=add_fav,
    res_body={'favorites_count': len(body.get('list', [])) if isinstance(body, dict) else 0}
)

# Get Favorites
status, body, _ = make_request('GET', f'{API_V1}/user/getFavorite', headers=auth_headers)
fav_list = body.get('list', []) if isinstance(body, dict) else []
record(
    'Favorites - Retrieve User Favorites',
    'GET',
    f'{API_V1}/user/getFavorite',
    status,
    status == 200 and any((item.get('id') == 3 or item.get('productId') == 3) for item in fav_list),
    res_body={'favorites_count': len(fav_list)}
)

# Delete Favorite
del_fav = {'productId': 3}
status, body, _ = make_request('DELETE', f'{API_V1}/user/deleteFavorite', data=del_fav, headers=auth_headers)
record(
    'Favorites - Remove Product (ID: 3)',
    'DELETE',
    f'{API_V1}/user/deleteFavorite',
    status,
    status == 200 and all((item.get('id') != 3 and item.get('productId') != 3) for item in body.get('list', [])),
    req_body=del_fav,
    res_body={'favorites_count': len(body.get('list', [])) if isinstance(body, dict) else 0}
)

# Re-add item 3 to favorites so we can test persistence across server restart!
make_request('POST', f'{API_V1}/user/addFavorite', data={'productId': 3}, headers=auth_headers)

# --- 7. Profile & Image Upload ---
# Get User Profile
status, body, _ = make_request('GET', f'{API_V1}/portfoilo/userData', headers=auth_headers)
userData = body.get('message', {}) if isinstance(body, dict) else {}
record(
    'Profile - Get User Data',
    'GET',
    f'{API_V1}/portfoilo/userData',
    status,
    status == 200 and userData.get('email') == 'flutteruser2026@test.com',
    res_body=userData
)

# Edit User Profile
edit_data = {'name': 'Flutter Pro User', 'phone': '01122334455', 'address': 'Alexandria, Egypt'}
status, body, _ = make_request('POST', f'{API_V1}/portfoilo/editUserData', data=edit_data, headers=auth_headers)
record(
    'Profile - Update Profile Details',
    'POST',
    f'{API_V1}/portfoilo/editUserData',
    status,
    status == 200,
    req_body=edit_data,
    res_body=body
)

# Verify Edit
status, body, _ = make_request('GET', f'{API_V1}/portfoilo/userData', headers=auth_headers)
updatedData = body.get('message', {}) if isinstance(body, dict) else {}
record(
    'Profile - Verify Updated Profile',
    'GET',
    f'{API_V1}/portfoilo/userData',
    status,
    status == 200 and updatedData.get('name') == 'Flutter Pro User' and updatedData.get('address') == 'Alexandria, Egypt',
    res_body=updatedData
)

# Image Upload (Multipart form-data)
boundary = '----WebKitFormBoundaryTest12345678'
file_content = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' \",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xbf\x00\xff\xd9'

form_data = (
    f'--{boundary}\r\n'
    f'Content-Disposition: form-data; name="file"; filename="test_profile.jpg"\r\n'
    f'Content-Type: image/jpeg\r\n\r\n'
).encode('utf-8') + file_content + f'\r\n--{boundary}--\r\n'.encode('utf-8')

upload_headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': f'multipart/form-data; boundary={boundary}'
}
status, body, _ = make_request('POST', f'{API_V1}/portfoilo/addImage', data=form_data, headers=upload_headers, is_json=False)
uploaded_img_url = body.get('imageUrl') if isinstance(body, dict) else None
record(
    'Profile - Upload Profile Image (multipart)',
    'POST',
    f'{API_V1}/portfoilo/addImage',
    status,
    status == 200 and uploaded_img_url is not None,
    req_body='[Binary JPEG 1x1 data]',
    res_body=body
)

# Test Image Retrieval
if uploaded_img_url:
    img_get_url = f'{BASE_URL}/{uploaded_img_url}'
    status, body, img_hdrs = make_request('GET', img_get_url, is_json=False)
    record(
        f'Profile - Static Image Retrieval ({uploaded_img_url})',
        'GET',
        img_get_url,
        status,
        status == 200,
        res_body={'content_type': img_hdrs.get('Content-Type'), 'size_bytes': len(body) if body else 0}
    )

with open(r'd:\eraasoft_flutter_course\day 15\day15\api\test_results.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2)

print("\n==================================================")
passed = sum(1 for r in results if r['success'])
failed = sum(1 for r in results if not r['success'])
print(f"TESTS FINISHED: {passed} PASSED, {failed} FAILED (TOTAL {len(results)})")
print("==================================================")
