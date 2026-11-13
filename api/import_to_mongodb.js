require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');

const User = require('./models/User');
const Product = require('./models/Product');
const Category = require('./models/Category');
const Brand = require('./models/Brand');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/shopping_app';
const DATA_DIR = path.join(__dirname, 'data');

async function importAll() {
  console.log(`Connecting to MongoDB at: ${MONGODB_URI}...`);
  await mongoose.connect(MONGODB_URI);
  console.log('✅ Connected to MongoDB successfully!');

  // 1. Clear existing collections
  console.log('Clearing old collections in shopping_app database...');
  await Product.deleteMany({});
  await Category.deleteMany({});
  await Brand.deleteMany({});
  await User.deleteMany({});

  // 2. Import Products
  const productsFile = path.join(DATA_DIR, 'products.json');
  if (fs.existsSync(productsFile)) {
    const rawProducts = JSON.parse(fs.readFileSync(productsFile, 'utf-8'));
    // Ensure image field is set
    const processedProducts = rawProducts.map(p => ({
      ...p,
      image: p.image || p.thumbnail || (p.images && p.images[0]) || ''
    }));
    await Product.insertMany(processedProducts);
    console.log(`✅ Imported ${processedProducts.length} products into collection "products"`);
  }

  // 3. Import Categories
  const categoriesFile = path.join(DATA_DIR, 'categories.json');
  if (fs.existsSync(categoriesFile)) {
    const rawCats = JSON.parse(fs.readFileSync(categoriesFile, 'utf-8'));
    const catList = rawCats.list || rawCats || [];
    await Category.insertMany(catList);
    console.log(`✅ Imported ${catList.length} categories into collection "categories"`);
  }

  // 4. Import Brands
  const brandsFile = path.join(DATA_DIR, 'brands.json');
  if (fs.existsSync(brandsFile)) {
    const rawBrands = JSON.parse(fs.readFileSync(brandsFile, 'utf-8'));
    const brandList = rawBrands.list || rawBrands || [];
    await Brand.insertMany(brandList);
    console.log(`✅ Imported ${brandList.length} brands into collection "brands"`);
  }

  // 5. Import User Account
  const hashedPassword = bcrypt.hashSync('Pass@1234', 8);
  const user = await User.create({
    name: 'FlutterUser',
    email: 'flutteruser2026@test.com',
    password: hashedPassword,
    phone: '01012345678',
    address: 'Cairo, Egypt',
    image: '',
    cart: [],
    favorites: []
  });
  console.log(`✅ Created test user in collection "users": ${user.email} (Password: Pass@1234)`);

  console.log('🎉 All data successfully imported into MongoDB database "shopping_app"!');
  await mongoose.disconnect();
  process.exit(0);
}

importAll().catch(err => {
  console.error('❌ Import failed:', err);
  process.exit(1);
});

