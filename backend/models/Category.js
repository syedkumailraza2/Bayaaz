const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Category name is required'],
    trim: true,
    maxlength: [50, 'Category name cannot exceed 50 characters']
  },
  description: {
    type: String,
    maxlength: [200, 'Description cannot exceed 200 characters']
  },
  color: {
    type: String,
    default: '#6366f1',
    match: [/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, 'Invalid color format']
  },
  icon: {
    type: String,
    default: 'book'
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  order: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Compound index to ensure unique category names per user
categorySchema.index({ name: 1, userId: 1 }, { unique: true });

// Predefined categories for new users
categorySchema.statics.createDefaultCategories = async function(userId) {
  const defaultCategories = [
    { name: 'Nauha', description: 'Mourning poetry for Imam Hussain', color: '#1f2937', icon: 'heart', isDefault: true },
    { name: 'Salaam', description: 'Salutations to Ahlul Bayt', color: '#059669', icon: 'pray', isDefault: true },
    { name: 'Manqabat', description: 'Praise poetry for saints', color: '#7c3aed', icon: 'star', isDefault: true },
    { name: 'Marsiya', description: 'Elegy poetry', color: '#dc2626', icon: 'cloud', isDefault: true },
    { name: 'Qasida', description: 'Classical poetry form', color: '#ea580c', icon: 'scroll', isDefault: true },
    { name: 'Poetry', description: 'General poetry', color: '#0891b2', icon: 'feather', isDefault: true }
  ];

  const categories = defaultCategories.map((cat, index) => ({
    ...cat,
    userId,
    order: index
  }));

  return this.insertMany(categories);
};

module.exports = mongoose.model('Category', categorySchema);