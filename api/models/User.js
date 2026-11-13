const mongoose = require('mongoose');

const CartItemSchema = new mongoose.Schema({
  productId: { type: Number, required: true },
  title: { type: String, default: '' },
  price: { type: Number, default: 0.0 },
  image: { type: String, default: '' },
  quantity: { type: Number, default: 1 }
}, { _id: false });

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  phone: { type: String, default: '' },
  password: { type: String, required: true },
  address: { type: String, default: '' },
  image: { type: String, default: '' },
  cart: [CartItemSchema],
  favorites: [{ type: mongoose.Schema.Types.Mixed }]
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id.toString();
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

module.exports = mongoose.model('User', UserSchema);

