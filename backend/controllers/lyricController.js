const Lyric = require('../models/Lyric');
const mongoose = require('mongoose');

// Create new lyric
const createLyric = async (req, res) => {
  try {
    const {
      title,
      poet,
      year,
      content,
      categoryId,
      tags,
      language,
      metadata,
      status,
      visibility,
      isLocked,
      lockPin
    } = req.body;

    const lyric = new Lyric({
      title,
      poet,
      year,
      content,
      categoryId,
      tags: tags || [],
      language: language || 'urdu',
      metadata: metadata || {},
      status: status || 'published',
      visibility: visibility || 'private',
      isLocked: isLocked || false,
      lockPin: isLocked ? lockPin : undefined,
      userId: req.user._id
    });

    await lyric.save();
    await lyric.populate('categoryId', 'name color icon');

    res.status(201).json({
      message: 'Lyric created successfully',
      lyric
    });
  } catch (error) {
    console.error('Create lyric error:', error);
    res.status(500).json({
      message: 'Server error while creating lyric',
      error: error.message
    });
  }
};

// Get all lyrics for a user with pagination and filtering
const getLyrics = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      categoryId,
      tags,
      poet,
      year,
      search,
      isFavorite,
      isPinned,
      sortBy = 'recent',
      status = 'published'
    } = req.query;

    const filters = {
      userId: req.user._id,
      status
    };

    // Apply filters
    if (categoryId) filters.categoryId = categoryId;
    if (poet) filters.poet = new RegExp(poet, 'i');
    if (year) filters.year = parseInt(year);
    if (isFavorite !== undefined) filters.isFavorite = isFavorite === 'true';
    if (isPinned !== undefined) filters.isPinned = isPinned === 'true';
    if (tags) {
      const tagArray = Array.isArray(tags) ? tags : tags.split(',');
      filters.tags = { $in: tagArray };
    }

    // Search functionality
    if (search) {
      filters.$text = { $search: search };
    }

    // Sorting
    let sort = {};
    switch (sortBy) {
      case 'title':
        sort.title = 1;
        break;
      case 'poet':
        sort.poet = 1;
        break;
      case 'year':
        sort.year = -1;
        break;
      case 'views':
        sort.viewCount = -1;
        break;
      case 'recent':
      default:
        sort.createdAt = -1;
        break;
    }

    // Pinned items first
    sort.isPinned = -1;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const lyrics = await Lyric.find(filters)
      .populate('categoryId', 'name color icon')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .select('-lockPin -versions'); // Exclude sensitive fields

    const total = await Lyric.countDocuments(filters);

    res.json({
      lyrics,
      pagination: {
        current: parseInt(page),
        pageSize: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get lyrics error:', error);
    res.status(500).json({
      message: 'Server error while fetching lyrics'
    });
  }
};

// Get single lyric by ID
const getLyricById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    })
      .populate('categoryId', 'name color icon')
      .select('-lockPin');

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    // Increment view count
    await lyric.incrementViewCount();

    res.json({
      lyric
    });
  } catch (error) {
    console.error('Get lyric error:', error);
    res.status(500).json({
      message: 'Server error while fetching lyric'
    });
  }
};

// Update lyric
const updateLyric = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    // Check if lyric is locked
    if (lyric.isLocked) {
      const { pin } = req.body;
      if (!pin || !lyric.isLockedByPin(pin)) {
        return res.status(403).json({
          message: 'Incorrect PIN. Lyric is locked.'
        });
      }
    }

    // Update fields
    const allowedUpdates = [
      'title', 'poet', 'year', 'content', 'categoryId', 'tags',
      'language', 'metadata', 'status', 'visibility', 'isFavorite',
      'isPinned', 'isLocked', 'lockPin'
    ];

    allowedUpdates.forEach(field => {
      if (updateData[field] !== undefined) {
        lyric[field] = updateData[field];
      }
    });

    await lyric.save();
    await lyric.populate('categoryId', 'name color icon');

    res.json({
      message: 'Lyric updated successfully',
      lyric
    });
  } catch (error) {
    console.error('Update lyric error:', error);
    res.status(500).json({
      message: 'Server error while updating lyric',
      error: error.message
    });
  }
};

// Delete lyric
const deleteLyric = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    // Check if lyric is locked
    if (lyric.isLocked) {
      const { pin } = req.body;
      if (!pin || !lyric.isLockedByPin(pin)) {
        return res.status(403).json({
          message: 'Incorrect PIN. Cannot delete locked lyric.'
        });
      }
    }

    await Lyric.findByIdAndDelete(id);

    res.json({
      message: 'Lyric deleted successfully'
    });
  } catch (error) {
    console.error('Delete lyric error:', error);
    res.status(500).json({
      message: 'Server error while deleting lyric'
    });
  }
};

// Toggle favorite status
const toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    lyric.isFavorite = !lyric.isFavorite;
    await lyric.save();

    res.json({
      message: `Lyric ${lyric.isFavorite ? 'added to' : 'removed from'} favorites`,
      isFavorite: lyric.isFavorite
    });
  } catch (error) {
    console.error('Toggle favorite error:', error);
    res.status(500).json({
      message: 'Server error while toggling favorite'
    });
  }
};

// Toggle pin status
const togglePin = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    lyric.isPinned = !lyric.isPinned;
    await lyric.save();

    res.json({
      message: `Lyric ${lyric.isPinned ? 'pinned' : 'unpinned'}`,
      isPinned: lyric.isPinned
    });
  } catch (error) {
    console.error('Toggle pin error:', error);
    res.status(500).json({
      message: 'Server error while toggling pin'
    });
  }
};

// Get version history
const getVersionHistory = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    }).select('versions');

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    res.json({
      versions: lyric.versions
    });
  } catch (error) {
    console.error('Get version history error:', error);
    res.status(500).json({
      message: 'Server error while fetching version history'
    });
  }
};

// Restore version
const restoreVersion = async (req, res) => {
  try {
    const { id, versionIndex } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid lyric ID'
      });
    }

    const lyric = await Lyric.findOne({
      _id: id,
      userId: req.user._id
    });

    if (!lyric) {
      return res.status(404).json({
        message: 'Lyric not found'
      });
    }

    const versionIdx = parseInt(versionIndex);
    if (versionIdx < 0 || versionIdx >= lyric.versions.length) {
      return res.status(400).json({
        message: 'Invalid version index'
      });
    }

    const version = lyric.versions[versionIdx];

    // Check if lyric is locked
    if (lyric.isLocked) {
      const { pin } = req.body;
      if (!pin || !lyric.isLockedByPin(pin)) {
        return res.status(403).json({
          message: 'Incorrect PIN. Cannot restore locked lyric.'
        });
      }
    }

    // Restore version content
    lyric.content = version.content;
    await lyric.save();

    res.json({
      message: 'Version restored successfully',
      lyric
    });
  } catch (error) {
    console.error('Restore version error:', error);
    res.status(500).json({
      message: 'Server error while restoring version'
    });
  }
};

// Get lyrics statistics
const getLyricsStats = async (req, res) => {
  try {
    const userId = req.user._id;

    const stats = await Lyric.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: null,
          totalLyrics: { $sum: 1 },
          totalViews: { $sum: '$viewCount' },
          favoritesCount: { $sum: { $cond: ['$isFavorite', 1, 0] } },
          pinnedCount: { $sum: { $cond: ['$isPinned', 1, 0] } },
          uniquePoets: { $addToSet: '$poet' },
          uniqueTags: { $addToSet: '$tags' }
        }
      },
      {
        $project: {
          totalLyrics: 1,
          totalViews: 1,
          favoritesCount: 1,
          pinnedCount: 1,
          uniquePoetsCount: { $size: '$uniquePoets' },
          uniqueTagsCount: { $size: { $reduce: {
            input: '$uniqueTags',
            initialValue: [],
            in: { $concatArrays: ['$$value', '$$this'] }
          }}}
        }
      }
    ]);

    const categoryStats = await Lyric.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$categoryId',
          count: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'category'
        }
      },
      {
        $unwind: '$category'
      },
      {
        $project: {
          categoryId: '$_id',
          categoryName: '$category.name',
          categoryColor: '$category.color',
          count: 1
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);

    res.json({
      stats: stats[0] || {
        totalLyrics: 0,
        totalViews: 0,
        favoritesCount: 0,
        pinnedCount: 0,
        uniquePoetsCount: 0,
        uniqueTagsCount: 0
      },
      categoryStats
    });
  } catch (error) {
    console.error('Get lyrics stats error:', error);
    res.status(500).json({
      message: 'Server error while fetching lyrics statistics'
    });
  }
};

module.exports = {
  createLyric,
  getLyrics,
  getLyricById,
  updateLyric,
  deleteLyric,
  toggleFavorite,
  togglePin,
  getVersionHistory,
  restoreVersion,
  getLyricsStats
};