// Posts service module within post-service
const prisma = require('../../../lib/database');

class PostService {
  // Get post by ID
  async getPostById(id) {
    try {
      return await prisma.post.findUnique({ 
        where: { id },
        include: {
          author: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              username: true,
              avatar: true,
              isVerified: true,
            }
          },
          event: {
            select: {
              id: true,
              title: true,
              startDate: true,
              location: true,
            }
          },
          likes: {
            select: {
              userId: true,
            }
          },
          comments: {
            include: {
              author: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  username: true,
                  avatar: true,
                }
              }
            },
            orderBy: { createdAt: 'desc' }
          },
          _count: {
            select: {
              likes: true,
              comments: true,
              shares: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get post: ${error.message}`);
    }
  }

  // Create new post
  async createPost(postData, authorId) {
    try {
      const { 
        content, images, eventId, location, 
        isPublic, allowComments, tags 
      } = postData;
      
      return await prisma.post.create({
        data: {
          content,
          images: images || [],
          eventId,
          location,
          isPublic: isPublic !== false, // Default to true
          allowComments: allowComments !== false, // Default to true
          tags: tags || [],
          authorId,
        },
        include: {
          author: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              username: true,
              avatar: true,
              isVerified: true,
            }
          },
          event: {
            select: {
              id: true,
              title: true,
              startDate: true,
              location: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to create post: ${error.message}`);
    }
  }

  // Update post
  async updatePost(id, updateData, authorId) {
    try {
      // Check if user owns the post
      const post = await prisma.post.findUnique({
        where: { id },
        select: { authorId: true }
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (post.authorId !== authorId) {
        throw new Error('Not authorized to update this post');
      }

      return await prisma.post.update({
        where: { id },
        data: {
          ...updateData,
          updatedAt: new Date(),
        },
        include: {
          author: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              username: true,
              avatar: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to update post: ${error.message}`);
    }
  }

  // Delete post
  async deletePost(id, authorId) {
    try {
      // Check if user owns the post
      const post = await prisma.post.findUnique({
        where: { id },
        select: { authorId: true }
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (post.authorId !== authorId) {
        throw new Error('Not authorized to delete this post');
      }

      return await prisma.post.delete({
        where: { id }
      });
    } catch (error) {
      throw new Error(`Failed to delete post: ${error.message}`);
    }
  }

  // Get feed posts (with pagination)
  async getFeedPosts(userId, page = 1, limit = 10) {
    try {
      const skip = (page - 1) * limit;
      
      // Get posts from users the current user follows and public posts
      const [posts, total] = await Promise.all([
        prisma.post.findMany({
          where: {
            OR: [
              { isPublic: true },
              {
                author: {
                  followers: {
                    some: {
                      followerId: userId,
                    }
                  }
                }
              },
              { authorId: userId } // User's own posts
            ]
          },
          skip,
          take: limit,
          include: {
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                username: true,
                avatar: true,
                isVerified: true,
              }
            },
            event: {
              select: {
                id: true,
                title: true,
                startDate: true,
                location: true,
              }
            },
            _count: {
              select: {
                likes: true,
                comments: true,
                shares: true,
              }
            },
            likes: {
              where: { userId },
              select: { id: true }
            }
          },
          orderBy: { createdAt: 'desc' }
        }),
        prisma.post.count({
          where: {
            OR: [
              { isPublic: true },
              {
                author: {
                  followers: {
                    some: {
                      followerId: userId,
                    }
                  }
                }
              },
              { authorId: userId }
            ]
          }
        })
      ]);

      return {
        posts: posts.map(post => ({
          ...post,
          isLiked: post.likes.length > 0,
          likes: undefined, // Remove the likes array, keep the count
        })),
        pagination: {
          current: page,
          total: Math.ceil(total / limit),
          count: total
        }
      };
    } catch (error) {
      throw new Error(`Failed to get feed posts: ${error.message}`);
    }
  }

  // Get user posts
  async getUserPosts(userId, viewerId = null, page = 1, limit = 10) {
    try {
      const skip = (page - 1) * limit;
      
      // If viewing own profile or following, show all posts
      // Otherwise, only show public posts
      const where = {
        authorId: userId,
        ...(viewerId !== userId && { isPublic: true })
      };

      const [posts, total] = await Promise.all([
        prisma.post.findMany({
          where,
          skip,
          take: limit,
          include: {
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                username: true,
                avatar: true,
                isVerified: true,
              }
            },
            event: {
              select: {
                id: true,
                title: true,
                startDate: true,
                location: true,
              }
            },
            _count: {
              select: {
                likes: true,
                comments: true,
                shares: true,
              }
            },
            ...(viewerId && {
              likes: {
                where: { userId: viewerId },
                select: { id: true }
              }
            })
          },
          orderBy: { createdAt: 'desc' }
        }),
        prisma.post.count({ where })
      ]);

      return {
        posts: posts.map(post => ({
          ...post,
          isLiked: viewerId ? post.likes?.length > 0 : false,
          likes: undefined,
        })),
        pagination: {
          current: page,
          total: Math.ceil(total / limit),
          count: total
        }
      };
    } catch (error) {
      throw new Error(`Failed to get user posts: ${error.message}`);
    }
  }

  // Like/Unlike post
  async toggleLike(postId, userId) {
    try {
      const existingLike = await prisma.postLike.findUnique({
        where: {
          postId_userId: {
            postId,
            userId,
          }
        }
      });

      if (existingLike) {
        // Unlike
        await prisma.postLike.delete({
          where: { id: existingLike.id }
        });
        return { liked: false };
      } else {
        // Like
        await prisma.postLike.create({
          data: {
            postId,
            userId,
          }
        });
        return { liked: true };
      }
    } catch (error) {
      throw new Error(`Failed to toggle like: ${error.message}`);
    }
  }

  // Add comment to post
  async addComment(postId, commentData, authorId) {
    try {
      const { content, parentCommentId } = commentData;

      // Check if post allows comments
      const post = await prisma.post.findUnique({
        where: { id: postId },
        select: { allowComments: true }
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (!post.allowComments) {
        throw new Error('Comments are disabled for this post');
      }

      return await prisma.comment.create({
        data: {
          content,
          postId,
          authorId,
          parentCommentId,
        },
        include: {
          author: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              username: true,
              avatar: true,
            }
          },
          replies: {
            include: {
              author: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  username: true,
                  avatar: true,
                }
              }
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to add comment: ${error.message}`);
    }
  }

  // Delete comment
  async deleteComment(commentId, authorId) {
    try {
      const comment = await prisma.comment.findUnique({
        where: { id: commentId },
        select: { authorId: true }
      });

      if (!comment) {
        throw new Error('Comment not found');
      }

      if (comment.authorId !== authorId) {
        throw new Error('Not authorized to delete this comment');
      }

      return await prisma.comment.delete({
        where: { id: commentId }
      });
    } catch (error) {
      throw new Error(`Failed to delete comment: ${error.message}`);
    }
  }

  // Share post
  async sharePost(postId, userId, shareData = {}) {
    try {
      const { content, isPublic = true } = shareData;

      // Check if post exists
      const originalPost = await prisma.post.findUnique({
        where: { id: postId },
        select: { id: true, isPublic: true }
      });

      if (!originalPost) {
        throw new Error('Post not found');
      }

      if (!originalPost.isPublic) {
        throw new Error('Cannot share private post');
      }

      return await prisma.postShare.create({
        data: {
          postId,
          userId,
          content,
          isPublic,
        },
        include: {
          post: {
            include: {
              author: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  username: true,
                  avatar: true,
                }
              }
            }
          },
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              username: true,
              avatar: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to share post: ${error.message}`);
    }
  }

  // Get post analytics
  async getPostAnalytics(postId, authorId) {
    try {
      // Check if user owns the post
      const post = await prisma.post.findUnique({
        where: { id: postId },
        select: { authorId: true }
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (post.authorId !== authorId) {
        throw new Error('Not authorized to view analytics for this post');
      }

      const [likes, comments, shares, views] = await Promise.all([
        prisma.postLike.count({ where: { postId } }),
        prisma.comment.count({ where: { postId } }),
        prisma.postShare.count({ where: { postId } }),
        prisma.postView.count({ where: { postId } })
      ]);

      return {
        likes,
        comments,
        shares,
        views,
        engagement: likes + comments + shares,
      };
    } catch (error) {
      throw new Error(`Failed to get post analytics: ${error.message}`);
    }
  }

  // Track post view
  async trackView(postId, userId) {
    try {
      // Only track if user hasn't viewed this post recently
      const recentView = await prisma.postView.findFirst({
        where: {
          postId,
          userId,
          viewedAt: {
            gte: new Date(Date.now() - 24 * 60 * 60 * 1000), // Last 24 hours
          }
        }
      });

      if (!recentView) {
        await prisma.postView.create({
          data: {
            postId,
            userId,
            viewedAt: new Date(),
          }
        });
      }

      return true;
    } catch (error) {
      // Don't throw error for view tracking
      console.error('Failed to track view:', error.message);
      return false;
    }
  }
}

module.exports = new PostService();
