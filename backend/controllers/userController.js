const User = require('../models/User');
const Lyric = require('../models/Lyric');
const Category = require('../models/Category');

// Get user dashboard data
const getDashboard = async (req, res) => {
  try {
    const userId = req.user._id;

    // Get user statistics
    const user = await User.findById(userId);

    // Get recent lyrics
    const recentLyrics = await Lyric.find({ userId })
      .populate('categoryId', 'name color icon')
      .sort({ lastViewedAt: -1 })
      .limit(5)
      .select('-lockPin -versions');

    // Get favorite lyrics
    const favoriteLyrics = await Lyric.find({
      userId,
      isFavorite: true
    })
      .populate('categoryId', 'name color icon')
      .sort({ lastViewedAt: -1 })
      .limit(5)
      .select('-lockPin -versions');

    // Get pinned lyrics
    const pinnedLyrics = await Lyric.find({
      userId,
      isPinned: true
    })
      .populate('categoryId', 'name color icon')
      .sort({ order: 1 })
      .select('-lockPin -versions');

    // Get categories with counts
    const categories = await Category.find({
      userId,
      isArchived: false
    })
      .sort({ order: 1, name: 1 });

    const categoryStats = await Promise.all(
      categories.map(async (category) => {
        const count = await Lyric.countDocuments({
          userId,
          categoryId: category._id
        });
        return {
          _id: category._id,
          name: category.name,
          color: category.color,
          icon: category.icon,
          isDefault: category.isDefault,
          count
        };
      })
    );

    // Get activity data (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentActivity = await Lyric.find({
      userId,
      createdAt: { $gte: sevenDaysAgo }
    })
      .sort({ createdAt: -1 })
      .select('title createdAt categoryId')
      .populate('categoryId', 'name color');

    res.json({
      user: {
        id: user._id,
        username: user.username,
        profile: user.profile,
        stats: user.stats,
        preferences: user.preferences,
        subscription: user.subscription
      },
      recentLyrics,
      favoriteLyrics,
      pinnedLyrics,
      categories: categoryStats,
      recentActivity,
      stats: {
        totalLyrics: user.stats.totalLyrics,
        totalCategories: user.stats.totalCategories,
        totalViews: recentLyrics.reduce((sum, lyric) => sum + lyric.viewCount, 0),
        favoriteCount: favoriteLyrics.length,
        pinnedCount: pinnedLyrics.length
      }
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({
      message: 'Server error while fetching dashboard data'
    });
  }
};

// Search across all user content
const searchContent = async (req, res) => {
  try {
    const {
      q: query,
      type = 'all', // all, lyrics, categories
      limit = 20,
      page = 1,
      sortBy = 'relevance'
    } = req.query;

    if (!query || query.trim().length < 2) {
      return res.status(400).json({
        message: 'Search query must be at least 2 characters long'
      });
    }

    const userId = req.user._id;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    let results = {};

    if (type === 'all' || type === 'lyrics') {
      // Search lyrics
      const lyricSearchQuery = {
        userId,
        status: 'published',
        $text: { $search: query }
      };

      const lyricSort = sortBy === 'recent'
        ? { createdAt: -1, isPinned: -1 }
        : { score: { $meta: 'textScore' }, isPinned: -1 };

      const lyrics = await Lyric.find(lyricSearchQuery, {
        score: { $meta: 'textScore' }
      })
        .populate('categoryId', 'name color icon')
        .sort(lyricSort)
        .skip(skip)
        .limit(parseInt(limit))
        .select('-lockPin -versions');

      const totalLyrics = await Lyric.countDocuments(lyricSearchQuery);

      results.lyrics = {
        items: lyrics,
        total: totalLyrics,
        page: parseInt(page),
        pages: Math.ceil(totalLyrics / parseInt(limit))
      };
    }

    if (type === 'all' || type === 'categories') {
      // Search categories
      const categorySearchQuery = {
        userId,
        isArchived: false,
        name: new RegExp(query, 'i')
      };

      const categories = await Category.find(categorySearchQuery)
        .sort({ isDefault: -1, name: 1 });

      results.categories = {
        items: categories,
        total: categories.length
      };
    }

    res.json({
      query,
      results
    });
  } catch (error) {
    console.error('Search content error:', error);
    res.status(500).json({
      message: 'Server error while searching content'
    });
  }
};

// Export user data
const exportData = async (req, res) => {
  try {
    const { format = 'json' } = req.query;
    const userId = req.user._id;

    // Get all user data
    const user = await User.findById(userId);
    const categories = await Category.find({ userId });
    const lyrics = await Lyric.find({ userId })
      .populate('categoryId', 'name color icon')
      .select('-lockPin -versions');

    const exportData = {
      user: {
        username: user.username,
        profile: user.profile,
        preferences: user.preferences,
        createdAt: user.createdAt
      },
      categories,
      lyrics,
      exportDate: new Date().toISOString(),
      version: '1.0'
    };

    if (format === 'json') {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="bayaaz-export-${Date.now()}.json"`);
      return res.json(exportData);
    }

    res.status(400).json({
      message: 'Unsupported export format'
    });
  } catch (error) {
    console.error('Export data error:', error);
    res.status(500).json({
      message: 'Server error while exporting data'
    });
  }
};

// Import user data
const importData = async (req, res) => {
  try {
    const { data, mergeStrategy = 'replace' } = req.body;

    if (!data || !data.lyrics || !data.categories) {
      return res.status(400).json({
        message: 'Invalid import data format'
      });
    }

    const userId = req.user._id;
    const results = {
      categoriesImported: 0,
      lyricsImported: 0,
      errors: []
    };

    // Handle categories
    if (mergeStrategy === 'replace') {
      // Delete existing user categories (except defaults)
      await Category.deleteMany({
        userId,
        isDefault: false
      });
    }

    // Import categories
    for (const categoryData of data.categories) {
      try {
        if (categoryData.isDefault) continue; // Skip default categories

        const category = new Category({
          ...categoryData,
          userId,
          _id: undefined // Remove _id to create new documents
        });

        await category.save();
        results.categoriesImported++;
      } catch (error) {
        results.errors.push({
          type: 'category',
          name: categoryData.name,
          error: error.message
        });
      }
    }

    // Handle lyrics
    if (mergeStrategy === 'replace') {
      // Delete existing user lyrics
      await Lyric.deleteMany({ userId });
    }

    // Import lyrics
    for (const lyricData of data.lyrics) {
      try {
        // Find matching category by name
        const category = await Category.findOne({
          userId,
          name: lyricData.categoryId?.name
        });

        const lyric = new Lyric({
          title: lyricData.title,
          poet: lyricData.poet,
          year: lyricData.year,
          content: lyricData.content,
          categoryId: category?._id || null,
          tags: lyricData.tags || [],
          language: lyricData.language || 'urdu',
          metadata: lyricData.metadata || {},
          status: lyricData.status || 'published',
          visibility: lyricData.visibility || 'private',
          isFavorite: lyricData.isFavorite || false,
          isPinned: lyricData.isPinned || false,
          userId,
          _id: undefined, // Remove _id to create new documents
          attachments: lyricData.attachments || [],
          versions: [] // Reset version history
        });

        await lyric.save();
        results.lyricsImported++;
      } catch (error) {
        results.errors.push({
          type: 'lyric',
          title: lyricData.title,
          error: error.message
        });
      }
    }

    // Update user stats
    await User.findById(userId).then(user => user.updateStats());

    res.json({
      message: 'Import completed',
      results
    });
  } catch (error) {
    console.error('Import data error:', error);
    res.status(500).json({
      message: 'Server error while importing data',
      error: error.message
    });
  }
};

// Get user settings
const getSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    res.json({
      settings: {
        profile: user.profile,
        preferences: user.preferences,
        subscription: user.subscription,
        email: user.email,
        username: user.username
      }
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({
      message: 'Server error while fetching settings'
    });
  }
};

// Update user settings
const updateSettings = async (req, res) => {
  try {
    const { profile, preferences } = req.body;
    const user = await User.findById(req.user._id);

    if (profile) {
      user.profile = { ...user.profile, ...profile };
    }

    if (preferences) {
      user.preferences = { ...user.preferences, ...preferences };
    }

    await user.save();

    res.json({
      message: 'Settings updated successfully',
      settings: {
        profile: user.profile,
        preferences: user.preferences,
        subscription: user.subscription
      }
    });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({
      message: 'Server error while updating settings'
    });
  }
};

// Sync user data (for mobile apps)
const syncData = async (req, res) => {
  try {
    const { lastSyncTime, deviceData } = req.body;
    const userId = req.user._id;
    const syncTime = new Date();

    let serverData = {};

    if (lastSyncTime) {
      const lastSync = new Date(lastSyncTime);

      // Get changes since last sync
      const updatedLyrics = await Lyric.find({
        userId,
        updatedAt: { $gt: lastSync }
      })
        .populate('categoryId', 'name color icon')
        .select('-lockPin -versions');

      const updatedCategories = await Category.find({
        userId,
        updatedAt: { $gt: lastSync }
      });

      serverData = {
        lyrics: updatedLyrics,
        categories: updatedCategories,
        syncTime
      };
    } else {
      // Full sync
      serverData = {
        lyrics: await Lyric.find({ userId })
          .populate('categoryId', 'name color icon')
          .select('-lockPin -versions'),
        categories: await Category.find({ userId }),
        syncTime
      };
    }

    // TODO: Process device data and merge changes
    // This would implement conflict resolution for offline changes

    res.json({
      message: 'Sync completed',
      serverData,
      syncTime
    });
  } catch (error) {
    console.error('Sync data error:', error);
    res.status(500).json({
      message: 'Server error while syncing data'
    });
  }
};

module.exports = {
  getDashboard,
  searchContent,
  exportData,
  importData,
  getSettings,
  updateSettings,
  syncData
};