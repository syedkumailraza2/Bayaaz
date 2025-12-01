const mongoose = require('mongoose');

const lyricSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  poet: {
    type: String,
    trim: true,
    maxlength: [100, 'Poet name cannot exceed 100 characters']
  },
  year: {
    type: Number,
    min: [100, 'Year must be at least 100'],
    max: [new Date().getFullYear() + 1, 'Year cannot be in the future']
  },
  content: {
    type: String,
    required: [true, 'Content is required'],
    trim: true
  },
  plainText: {
    type: String,
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: true
  },
  tags: [{
    type: String,
    trim: true,
    maxlength: [50, 'Tag cannot exceed 50 characters']
  }],
  language: {
    type: String,
    default: 'urdu',
    enum: ['urdu', 'arabic', 'persian', 'english', 'hindi', 'other']
  },
  attachments: [{
    type: {
      type: String,
      enum: ['audio', 'image', 'document'],
      required: true
    },
    url: {
      type: String,
      required: true
    },
    publicId: {
      type: String,
      required: true
    },
    fileName: {
      type: String,
      required: true
    },
    fileSize: {
      type: Number,
      required: true
    },
    mimeType: {
      type: String,
      required: true
    },
    uploadedAt: {
      type: Date,
      default: Date.now
    }
  }],
  metadata: {
    source: {
      type: String,
      maxlength: [100, 'Source cannot exceed 100 characters']
    },
    reference: {
      type: String,
      maxlength: [200, 'Reference cannot exceed 200 characters']
    },
    notes: {
      type: String,
      maxlength: [500, 'Notes cannot exceed 500 characters']
    }
  },
  status: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'published'
  },
  visibility: {
    type: String,
    enum: ['private', 'public'],
    default: 'private'
  },
  isFavorite: {
    type: Boolean,
    default: false
  },
  isPinned: {
    type: Boolean,
    default: false
  },
  isLocked: {
    type: Boolean,
    default: false
  },
  lockPin: {
    type: String,
    select: false
  },
  viewCount: {
    type: Number,
    default: 0
  },
  versions: [{
    content: {
      type: String,
      required: true
    },
    modifiedAt: {
      type: Date,
      default: Date.now
    },
    reason: {
      type: String,
      maxlength: [100, 'Reason cannot exceed 100 characters']
    }
  }],
  lastViewedAt: {
    type: Date
  },
  searchIndex: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Indexes for better search performance
lyricSchema.index({ userId: 1, categoryId: 1 });
lyricSchema.index({ userId: 1, isFavorite: 1 });
lyricSchema.index({ userId: 1, isPinned: 1 });
lyricSchema.index({ userId: 1, tags: 1 });
lyricSchema.index({ userId: 1, poet: 1 });
lyricSchema.index({ userId: 1, year: 1 });
lyricSchema.index({ searchIndex: 'text', plainText: 'text', title: 'text', poet: 'text', tags: 'text' });

// Pre-save middleware to update search index and plain text
lyricSchema.pre('save', function(next) {
  if (this.isModified('content')) {
    // Strip HTML tags for plain text version
    this.plainText = this.content.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();

    // Create search index
    const searchFields = [
      this.title,
      this.poet || '',
      this.tags.join(' '),
      this.plainText
    ].join(' ').toLowerCase();

    this.searchIndex = searchFields;
  }

  // Update last viewed timestamp
  this.lastViewedAt = new Date();

  next();
});

// Pre-save middleware for version history
lyricSchema.pre('save', function(next) {
  if (this.isModified('content') && !this.isNew) {
    // Keep only last 10 versions
    this.versions = [
      {
        content: this.content,
        modifiedAt: new Date(),
        reason: 'Auto-save'
      },
      ...this.versions.slice(0, 9)
    ];
  }
  next();
});

// Method to increment view count
lyricSchema.methods.incrementViewCount = function() {
  this.viewCount += 1;
  this.lastViewedAt = new Date();
  return this.save();
};

// Method to check if lyric is locked
lyricSchema.methods.isLockedByPin = function(pin) {
  if (!this.isLocked) return true;
  return this.lockPin === pin;
};

// Static method for search
lyricSchema.statics.search = function(userId, query, filters = {}) {
  const searchQuery = {
    userId,
    status: 'published'
  };

  if (query) {
    searchQuery.$text = { $search: query };
  }

  // Apply filters
  if (filters.categoryId) {
    searchQuery.categoryId = filters.categoryId;
  }

  if (filters.tags && filters.tags.length > 0) {
    searchQuery.tags = { $in: filters.tags };
  }

  if (filters.poet) {
    searchQuery.poet = new RegExp(filters.poet, 'i');
  }

  if (filters.year) {
    searchQuery.year = filters.year;
  }

  if (filters.isFavorite !== undefined) {
    searchQuery.isFavorite = filters.isFavorite;
  }

  if (filters.isPinned !== undefined) {
    searchQuery.isPinned = filters.isPinned;
  }

  // Sorting
  let sort = {};
  switch (filters.sortBy) {
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

  return this.find(searchQuery)
    .populate('categoryId', 'name color icon')
    .sort(sort)
    .limit(filters.limit || 50)
    .skip(filters.offset || 0);
};

module.exports = mongoose.model('Lyric', lyricSchema);