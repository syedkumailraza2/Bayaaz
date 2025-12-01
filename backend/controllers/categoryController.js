const Category = require('../models/Category');
const mongoose = require('mongoose');

// Get all categories for a user
const getCategories = async (req, res) => {
  try {
    const { includeArchived = false } = req.query;

    const filters = {
      userId: req.user._id
    };

    if (includeArchived !== 'true') {
      filters.isArchived = false;
    }

    const categories = await Category.find(filters)
      .sort({ order: 1, name: 1 });

    res.json({
      categories
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      message: 'Server error while fetching categories'
    });
  }
};

// Get single category by ID
const getCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid category ID'
      });
    }

    const category = await Category.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!category) {
      return res.status(404).json({
        message: 'Category not found'
      });
    }

    res.json({
      category
    });
  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      message: 'Server error while fetching category'
    });
  }
};

// Create new category
const createCategory = async (req, res) => {
  try {
    const { name, description, color, icon } = req.body;

    // Check if category already exists for this user
    const existingCategory = await Category.findOne({
      name: name.trim(),
      userId: req.user._id
    });

    if (existingCategory) {
      return res.status(400).json({
        message: 'Category with this name already exists'
      });
    }

    // Get the highest order value
    const lastCategory = await Category.findOne({ userId: req.user._id })
      .sort({ order: -1 });

    const category = new Category({
      name: name.trim(),
      description,
      color,
      icon,
      userId: req.user._id,
      order: lastCategory ? lastCategory.order + 1 : 0
    });

    await category.save();

    res.status(201).json({
      message: 'Category created successfully',
      category
    });
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({
      message: 'Server error while creating category',
      error: error.message
    });
  }
};

// Update category
const updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, color, icon, order } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid category ID'
      });
    }

    const category = await Category.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!category) {
      return res.status(404).json({
        message: 'Category not found'
      });
    }

    // Check if it's a default category
    if (category.isDefault) {
      return res.status(400).json({
        message: 'Cannot edit default categories'
      });
    }

    // Check if new name conflicts with existing category
    if (name && name.trim() !== category.name) {
      const existingCategory = await Category.findOne({
        name: name.trim(),
        userId: req.user._id,
        _id: { $ne: id }
      });

      if (existingCategory) {
        return res.status(400).json({
          message: 'Category with this name already exists'
        });
      }
    }

    // Update fields
    if (name !== undefined) category.name = name.trim();
    if (description !== undefined) category.description = description;
    if (color !== undefined) category.color = color;
    if (icon !== undefined) category.icon = icon;
    if (order !== undefined) category.order = order;

    await category.save();

    res.json({
      message: 'Category updated successfully',
      category
    });
  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({
      message: 'Server error while updating category',
      error: error.message
    });
  }
};

// Delete category
const deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid category ID'
      });
    }

    const category = await Category.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!category) {
      return res.status(404).json({
        message: 'Category not found'
      });
    }

    // Check if it's a default category
    if (category.isDefault) {
      return res.status(400).json({
        message: 'Cannot delete default categories'
      });
    }

    // Check if category has any lyrics
    const Lyric = mongoose.model('Lyric');
    const lyricsCount = await Lyric.countDocuments({ categoryId: id });

    if (lyricsCount > 0) {
      return res.status(400).json({
        message: 'Cannot delete category that contains lyrics. Please move or delete the lyrics first.',
        lyricsCount
      });
    }

    await Category.findByIdAndDelete(id);

    res.json({
      message: 'Category deleted successfully'
    });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({
      message: 'Server error while deleting category'
    });
  }
};

// Archive/unarchive category
const toggleArchive = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid category ID'
      });
    }

    const category = await Category.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!category) {
      return res.status(404).json({
        message: 'Category not found'
      });
    }

    // Check if it's a default category
    if (category.isDefault) {
      return res.status(400).json({
        message: 'Cannot archive default categories'
      });
    }

    category.isArchived = !category.isArchived;
    await category.save();

    res.json({
      message: `Category ${category.isArchived ? 'archived' : 'unarchived'} successfully`,
      isArchived: category.isArchived
    });
  } catch (error) {
    console.error('Toggle archive error:', error);
    res.status(500).json({
      message: 'Server error while toggling archive status'
    });
  }
};

// Reorder categories
const reorderCategories = async (req, res) => {
  try {
    const { categoryOrders } = req.body;

    if (!Array.isArray(categoryOrders)) {
      return res.status(400).json({
        message: 'categoryOrders must be an array'
      });
    }

    // Validate all category IDs
    const categoryIds = categoryOrders.map(item => item.categoryId);
    const validIds = categoryIds.every(id => mongoose.Types.ObjectId.isValid(id));

    if (!validIds) {
      return res.status(400).json({
        message: 'Invalid category ID(s) in the list'
      });
    }

    // Verify all categories belong to the user
    const categories = await Category.find({
      _id: { $in: categoryIds },
      userId: req.user._id
    });

    if (categories.length !== categoryIds.length) {
      return res.status(404).json({
        message: 'One or more categories not found'
      });
    }

    // Update categories in bulk
    const bulkOps = categoryOrders.map(({ categoryId, order }) => ({
      updateOne: {
        filter: { _id: categoryId, userId: req.user._id },
        update: { order }
      }
    }));

    await Category.bulkWrite(bulkOps);

    res.json({
      message: 'Categories reordered successfully'
    });
  } catch (error) {
    console.error('Reorder categories error:', error);
    res.status(500).json({
      message: 'Server error while reordering categories'
    });
  }
};

// Get category statistics
const getCategoryStats = async (req, res) => {
  try {
    const userId = req.user._id;

    const stats = await Category.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      {
        $lookup: {
          from: 'lyrics',
          localField: '_id',
          foreignField: 'categoryId',
          as: 'lyrics'
        }
      },
      {
        $project: {
          name: 1,
          color: 1,
          icon: 1,
          isDefault: 1,
          isArchived: 1,
          lyricsCount: { $size: '$lyrics' },
          totalViews: { $sum: '$lyrics.viewCount' },
          favoritesCount: {
            $size: {
              $filter: {
                input: '$lyrics',
                cond: { $eq: ['$$this.isFavorite', true] }
              }
            }
          }
        }
      },
      {
        $sort: { lyricsCount: -1 }
      }
    ]);

    res.json({
      stats
    });
  } catch (error) {
    console.error('Get category stats error:', error);
    res.status(500).json({
      message: 'Server error while fetching category statistics'
    });
  }
};

module.exports = {
  getCategories,
  getCategoryById,
  createCategory,
  updateCategory,
  deleteCategory,
  toggleArchive,
  reorderCategories,
  getCategoryStats
};