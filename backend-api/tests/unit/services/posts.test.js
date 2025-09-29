const postService = require('../services/post-service/index');
const postsModule = require('../services/post-service/posts/index');
const prisma = require('../lib/database');

// Mock Prisma
jest.mock('../lib/database', () => ({
  post: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
  },
  postLike: {
    findUnique: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
    count: jest.fn(),
  },
  comment: {
    create: jest.fn(),
    delete: jest.fn(),
    findUnique: jest.fn(),
    count: jest.fn(),
  },
  postShare: {
    create: jest.fn(),
    count: jest.fn(),
  },
  postView: {
    create: jest.fn(),
    findFirst: jest.fn(),
    count: jest.fn(),
  },
}));

// Mock console methods
const consoleSpy = {
  log: jest.spyOn(console, 'log').mockImplementation(() => {}),
  error: jest.spyOn(console, 'error').mockImplementation(() => {}),
};

describe('Post Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    consoleSpy.log.mockRestore();
    consoleSpy.error.mockRestore();
  });

  describe('Main Post Service', () => {
    describe('healthCheck', () => {
      it('should return health check information', async () => {
        const result = await postService.healthCheck();

        expect(result).toEqual({
          service: 'post-service',
          status: 'healthy',
          timestamp: expect.any(String),
          version: '1.0.0',
        });
        expect(new Date(result.timestamp)).toBeInstanceOf(Date);
      });
    });

    describe('initialize', () => {
      it('should initialize successfully', async () => {
        const result = await postService.initialize();

        expect(result).toBe(true);
        expect(consoleSpy.log).toHaveBeenCalledWith('Post Service initialized successfully');
      });

      it('should handle initialization errors', async () => {
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        
        // Create a new PostService instance that will throw during initialization
        const originalConsoleLog = console.log;
        jest.spyOn(console, 'log').mockImplementation(() => {
          throw new Error('Initialization failed');
        });
        
        try {
          const result = await postService.initialize();
          expect(result).toBe(false);
          expect(consoleSpy).toHaveBeenCalledWith(
            'Post Service initialization failed:', 
            expect.any(Error)
          );
        } finally {
          consoleSpy.mockRestore();
          console.log = originalConsoleLog;
        }
      });
    });
  });

  describe('Posts Module', () => {
    describe('getPostById', () => {
      const mockPost = {
        id: 'post-1',
        content: 'Test post content',
        images: [],
        isPublic: true,
        allowComments: true,
        tags: ['test'],
        createdAt: new Date(),
        author: {
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          avatar: 'avatar.jpg',
          isVerified: true
        },
        event: {
          id: 'event-1',
          title: 'Test Event',
          startDate: new Date(),
          location: 'Test Location'
        },
        likes: [{ userId: 'user-2' }],
        comments: [],
        _count: {
          likes: 1,
          comments: 0,
          shares: 0
        }
      };

      it('should return post by ID with all related data', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockPost);

        const result = await postsModule.getPostById('post-1');

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
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
        expect(result).toEqual(mockPost);
      });

      it('should return null for non-existent post', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        const result = await postsModule.getPostById('nonexistent');

        expect(result).toBeNull();
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.getPostById('post-1'))
          .rejects
          .toThrow('Failed to get post: DB error');
      });
    });

    describe('createPost', () => {
      const postData = {
        content: 'New post content',
        images: ['image1.jpg', 'image2.jpg'],
        eventId: 'event-1',
        location: 'Test Location',
        isPublic: true,
        allowComments: true,
        tags: ['test', 'new']
      };

      const mockCreatedPost = {
        id: 'post-2',
        ...postData,
        authorId: 'user-1',
        createdAt: new Date(),
        author: {
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          avatar: 'avatar.jpg',
          isVerified: true
        },
        event: {
          id: 'event-1',
          title: 'Test Event',
          startDate: new Date(),
          location: 'Test Location'
        }
      };

      it('should create post with all provided data', async () => {
        prisma.post.create.mockResolvedValueOnce(mockCreatedPost);

        const result = await postsModule.createPost(postData, 'user-1');

        expect(prisma.post.create).toHaveBeenCalledWith({
          data: {
            content: 'New post content',
            images: ['image1.jpg', 'image2.jpg'],
            eventId: 'event-1',
            location: 'Test Location',
            isPublic: true,
            allowComments: true,
            tags: ['test', 'new'],
            authorId: 'user-1',
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
        expect(result).toEqual(mockCreatedPost);
      });

      it('should create post with minimal data and defaults', async () => {
        const minimalData = { content: 'Minimal post' };
        prisma.post.create.mockResolvedValueOnce(mockCreatedPost);

        await postsModule.createPost(minimalData, 'user-1');

        expect(prisma.post.create).toHaveBeenCalledWith({
          data: {
            content: 'Minimal post',
            images: [],
            eventId: undefined,
            location: undefined,
            isPublic: true, // Default
            allowComments: true, // Default
            tags: [],
            authorId: 'user-1',
          },
          include: expect.any(Object)
        });
      });

      it('should handle explicit false values for isPublic and allowComments', async () => {
        const privateData = {
          content: 'Private post',
          isPublic: false,
          allowComments: false
        };
        prisma.post.create.mockResolvedValueOnce(mockCreatedPost);

        await postsModule.createPost(privateData, 'user-1');

        expect(prisma.post.create).toHaveBeenCalledWith({
          data: expect.objectContaining({
            isPublic: false,
            allowComments: false
          }),
          include: expect.any(Object)
        });
      });

      it('should throw error if database fails', async () => {
        prisma.post.create.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.createPost(postData, 'user-1'))
          .rejects
          .toThrow('Failed to create post: DB error');
      });
    });

    describe('updatePost', () => {
      const updateData = {
        content: 'Updated content',
        isPublic: false
      };

      const mockPost = { authorId: 'user-1' };
      const mockUpdatedPost = {
        id: 'post-1',
        content: 'Updated content',
        isPublic: false,
        updatedAt: new Date(),
        author: {
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          avatar: 'avatar.jpg'
        }
      };

      it('should update post when user is authorized', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockPost);
        prisma.post.update.mockResolvedValueOnce(mockUpdatedPost);

        const result = await postsModule.updatePost('post-1', updateData, 'user-1');

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          select: { authorId: true }
        });
        expect(prisma.post.update).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          data: {
            ...updateData,
            updatedAt: expect.any(Date),
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
        expect(result).toEqual(mockUpdatedPost);
      });

      it('should throw error if post not found', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.updatePost('post-1', updateData, 'user-1'))
          .rejects
          .toThrow('Failed to update post: Post not found');
      });

      it('should throw error if user is not authorized', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ authorId: 'user-2' });

        await expect(postsModule.updatePost('post-1', updateData, 'user-1'))
          .rejects
          .toThrow('Failed to update post: Not authorized to update this post');
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.updatePost('post-1', updateData, 'user-1'))
          .rejects
          .toThrow('Failed to update post: DB error');
      });
    });

    describe('deletePost', () => {
      const mockPost = { authorId: 'user-1' };
      const mockDeletedPost = { id: 'post-1' };

      it('should delete post when user is authorized', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockPost);
        prisma.post.delete.mockResolvedValueOnce(mockDeletedPost);

        const result = await postsModule.deletePost('post-1', 'user-1');

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          select: { authorId: true }
        });
        expect(prisma.post.delete).toHaveBeenCalledWith({
          where: { id: 'post-1' }
        });
        expect(result).toEqual(mockDeletedPost);
      });

      it('should throw error if post not found', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.deletePost('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete post: Post not found');
      });

      it('should throw error if user is not authorized', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ authorId: 'user-2' });

        await expect(postsModule.deletePost('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete post: Not authorized to delete this post');
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.deletePost('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete post: DB error');
      });
    });

    describe('getFeedPosts', () => {
      const mockPosts = [
        {
          id: 'post-1',
          content: 'Test post 1',
          author: { id: 'user-2', firstName: 'Jane', lastName: 'Doe' },
          event: { id: 'event-1', title: 'Event 1' },
          _count: { likes: 5, comments: 2, shares: 1 },
          likes: [{ id: 'like-1' }]
        },
        {
          id: 'post-2',
          content: 'Test post 2',
          author: { id: 'user-1', firstName: 'John', lastName: 'Doe' },
          event: null,
          _count: { likes: 3, comments: 1, shares: 0 },
          likes: []
        }
      ];

      it('should return feed posts with pagination', async () => {
        prisma.post.findMany.mockResolvedValueOnce(mockPosts);
        prisma.post.count.mockResolvedValueOnce(25);

        const result = await postsModule.getFeedPosts('user-1', 1, 10);

        expect(prisma.post.findMany).toHaveBeenCalledWith({
          where: {
            OR: [
              { isPublic: true },
              {
                author: {
                  followers: {
                    some: {
                      followerId: 'user-1',
                    }
                  }
                }
              },
              { authorId: 'user-1' }
            ]
          },
          skip: 0,
          take: 10,
          include: expect.any(Object),
          orderBy: { createdAt: 'desc' }
        });
        expect(result).toEqual({
          posts: [
            {
              ...mockPosts[0],
              isLiked: true,
              likes: undefined
            },
            {
              ...mockPosts[1],
              isLiked: false,
              likes: undefined
            }
          ],
          pagination: {
            current: 1,
            total: 3,
            count: 25
          }
        });
      });

      it('should handle pagination correctly', async () => {
        prisma.post.findMany.mockResolvedValueOnce([]);
        prisma.post.count.mockResolvedValueOnce(50);

        await postsModule.getFeedPosts('user-1', 3, 20);

        expect(prisma.post.findMany).toHaveBeenCalledWith(
          expect.objectContaining({
            skip: 40, // (3-1) * 20
            take: 20
          })
        );
      });

      it('should throw error if database fails', async () => {
        prisma.post.findMany.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.getFeedPosts('user-1'))
          .rejects
          .toThrow('Failed to get feed posts: DB error');
      });
    });

    describe('getUserPosts', () => {
      const mockUserPosts = [
        {
          id: 'post-1',
          content: 'User post 1',
          author: { id: 'user-1', firstName: 'John', lastName: 'Doe' },
          _count: { likes: 2, comments: 1, shares: 0 },
          likes: []
        }
      ];

      it('should return user posts when viewing own profile', async () => {
        prisma.post.findMany.mockResolvedValueOnce(mockUserPosts);
        prisma.post.count.mockResolvedValueOnce(5);

        const result = await postsModule.getUserPosts('user-1', 'user-1');

        expect(prisma.post.findMany).toHaveBeenCalledWith({
          where: { authorId: 'user-1' },
          skip: 0,
          take: 10,
          include: expect.any(Object),
          orderBy: { createdAt: 'desc' }
        });
        expect(result.posts[0].isLiked).toBe(false);
      });

      it('should return only public posts when viewing other user profile', async () => {
        prisma.post.findMany.mockResolvedValueOnce(mockUserPosts);
        prisma.post.count.mockResolvedValueOnce(3);

        await postsModule.getUserPosts('user-2', 'user-1');

        expect(prisma.post.findMany).toHaveBeenCalledWith({
          where: { 
            authorId: 'user-2',
            isPublic: true 
          },
          skip: 0,
          take: 10,
          include: expect.any(Object),
          orderBy: { createdAt: 'desc' }
        });
      });

      it('should handle no viewer ID', async () => {
        prisma.post.findMany.mockResolvedValueOnce(mockUserPosts);
        prisma.post.count.mockResolvedValueOnce(3);

        const result = await postsModule.getUserPosts('user-1', null);

        expect(result.posts[0].isLiked).toBe(false);
      });

      it('should throw error if database fails', async () => {
        prisma.post.findMany.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.getUserPosts('user-1'))
          .rejects
          .toThrow('Failed to get user posts: DB error');
      });
    });

    describe('toggleLike', () => {
      it('should remove like when user has already liked', async () => {
        const existingLike = { id: 'like-1' };
        prisma.postLike.findUnique.mockResolvedValueOnce(existingLike);
        prisma.postLike.delete.mockResolvedValueOnce(existingLike);

        const result = await postsModule.toggleLike('post-1', 'user-1');

        expect(prisma.postLike.findUnique).toHaveBeenCalledWith({
          where: {
            postId_userId: {
              postId: 'post-1',
              userId: 'user-1',
            }
          }
        });
        expect(prisma.postLike.delete).toHaveBeenCalledWith({
          where: { id: 'like-1' }
        });
        expect(result).toEqual({ liked: false });
      });

      it('should add like when user has not liked yet', async () => {
        prisma.postLike.findUnique.mockResolvedValueOnce(null);
        prisma.postLike.create.mockResolvedValueOnce({ id: 'like-2' });

        const result = await postsModule.toggleLike('post-1', 'user-1');

        expect(prisma.postLike.create).toHaveBeenCalledWith({
          data: {
            postId: 'post-1',
            userId: 'user-1',
          }
        });
        expect(result).toEqual({ liked: true });
      });

      it('should throw error if database fails', async () => {
        prisma.postLike.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.toggleLike('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to toggle like: DB error');
      });
    });

    describe('addComment', () => {
      const commentData = {
        content: 'Test comment',
        parentCommentId: null
      };

      const mockCreatedComment = {
        id: 'comment-1',
        content: 'Test comment',
        postId: 'post-1',
        authorId: 'user-1',
        author: {
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          avatar: 'avatar.jpg'
        },
        replies: []
      };

      it('should add comment when post allows comments', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ allowComments: true });
        prisma.comment.create.mockResolvedValueOnce(mockCreatedComment);

        const result = await postsModule.addComment('post-1', commentData, 'user-1');

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          select: { allowComments: true }
        });
        expect(prisma.comment.create).toHaveBeenCalledWith({
          data: {
            content: 'Test comment',
            postId: 'post-1',
            authorId: 'user-1',
            parentCommentId: null,
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
        expect(result).toEqual(mockCreatedComment);
      });

      it('should throw error if post not found', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.addComment('post-1', commentData, 'user-1'))
          .rejects
          .toThrow('Failed to add comment: Post not found');
      });

      it('should throw error if comments are disabled', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ allowComments: false });

        await expect(postsModule.addComment('post-1', commentData, 'user-1'))
          .rejects
          .toThrow('Failed to add comment: Comments are disabled for this post');
      });

      it('should handle parent comment ID', async () => {
        const replyData = { ...commentData, parentCommentId: 'comment-parent' };
        prisma.post.findUnique.mockResolvedValueOnce({ allowComments: true });
        prisma.comment.create.mockResolvedValueOnce(mockCreatedComment);

        await postsModule.addComment('post-1', replyData, 'user-1');

        expect(prisma.comment.create).toHaveBeenCalledWith({
          data: expect.objectContaining({
            parentCommentId: 'comment-parent'
          }),
          include: expect.any(Object)
        });
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.addComment('post-1', commentData, 'user-1'))
          .rejects
          .toThrow('Failed to add comment: DB error');
      });
    });

    describe('deleteComment', () => {
      const mockComment = { authorId: 'user-1' };

      it('should delete comment when user is authorized', async () => {
        prisma.comment.findUnique.mockResolvedValueOnce(mockComment);
        prisma.comment.delete.mockResolvedValueOnce({ id: 'comment-1' });

        const result = await postsModule.deleteComment('comment-1', 'user-1');

        expect(prisma.comment.findUnique).toHaveBeenCalledWith({
          where: { id: 'comment-1' },
          select: { authorId: true }
        });
        expect(prisma.comment.delete).toHaveBeenCalledWith({
          where: { id: 'comment-1' }
        });
        expect(result).toEqual({ id: 'comment-1' });
      });

      it('should throw error if comment not found', async () => {
        prisma.comment.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.deleteComment('comment-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete comment: Comment not found');
      });

      it('should throw error if user is not authorized', async () => {
        prisma.comment.findUnique.mockResolvedValueOnce({ authorId: 'user-2' });

        await expect(postsModule.deleteComment('comment-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete comment: Not authorized to delete this comment');
      });

      it('should throw error if database fails', async () => {
        prisma.comment.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.deleteComment('comment-1', 'user-1'))
          .rejects
          .toThrow('Failed to delete comment: DB error');
      });
    });

    describe('sharePost', () => {
      const shareData = {
        content: 'Sharing this great post!',
        isPublic: true
      };

      const mockOriginalPost = { id: 'post-1', isPublic: true };
      const mockShare = {
        id: 'share-1',
        postId: 'post-1',
        userId: 'user-1',
        content: 'Sharing this great post!',
        isPublic: true,
        post: {
          id: 'post-1',
          author: {
            id: 'user-2',
            firstName: 'Jane',
            lastName: 'Doe',
            username: 'janedoe',
            avatar: 'avatar2.jpg'
          }
        },
        user: {
          id: 'user-1',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          avatar: 'avatar1.jpg'
        }
      };

      it('should share public post successfully', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockOriginalPost);
        prisma.postShare.create.mockResolvedValueOnce(mockShare);

        const result = await postsModule.sharePost('post-1', 'user-1', shareData);

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          select: { id: true, isPublic: true }
        });
        expect(prisma.postShare.create).toHaveBeenCalledWith({
          data: {
            postId: 'post-1',
            userId: 'user-1',
            content: 'Sharing this great post!',
            isPublic: true,
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
        expect(result).toEqual(mockShare);
      });

      it('should share with default values when minimal data provided', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockOriginalPost);
        prisma.postShare.create.mockResolvedValueOnce(mockShare);

        await postsModule.sharePost('post-1', 'user-1');

        expect(prisma.postShare.create).toHaveBeenCalledWith({
          data: {
            postId: 'post-1',
            userId: 'user-1',
            content: undefined,
            isPublic: true, // Default value
          },
          include: expect.any(Object)
        });
      });

      it('should throw error if post not found', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.sharePost('post-1', 'user-1', shareData))
          .rejects
          .toThrow('Failed to share post: Post not found');
      });

      it('should throw error if trying to share private post', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ id: 'post-1', isPublic: false });

        await expect(postsModule.sharePost('post-1', 'user-1', shareData))
          .rejects
          .toThrow('Failed to share post: Cannot share private post');
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.sharePost('post-1', 'user-1', shareData))
          .rejects
          .toThrow('Failed to share post: DB error');
      });
    });

    describe('getPostAnalytics', () => {
      const mockPost = { authorId: 'user-1' };

      it('should return analytics when user owns the post', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(mockPost);
        prisma.postLike.count.mockResolvedValueOnce(10);
        prisma.comment.count.mockResolvedValueOnce(5);
        prisma.postShare.count.mockResolvedValueOnce(3);
        prisma.postView.count.mockResolvedValueOnce(100);

        const result = await postsModule.getPostAnalytics('post-1', 'user-1');

        expect(prisma.post.findUnique).toHaveBeenCalledWith({
          where: { id: 'post-1' },
          select: { authorId: true }
        });
        expect(prisma.postLike.count).toHaveBeenCalledWith({ where: { postId: 'post-1' } });
        expect(prisma.comment.count).toHaveBeenCalledWith({ where: { postId: 'post-1' } });
        expect(prisma.postShare.count).toHaveBeenCalledWith({ where: { postId: 'post-1' } });
        expect(prisma.postView.count).toHaveBeenCalledWith({ where: { postId: 'post-1' } });
        expect(result).toEqual({
          likes: 10,
          comments: 5,
          shares: 3,
          views: 100,
          engagement: 18, // 10 + 5 + 3
        });
      });

      it('should throw error if post not found', async () => {
        prisma.post.findUnique.mockResolvedValueOnce(null);

        await expect(postsModule.getPostAnalytics('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to get post analytics: Post not found');
      });

      it('should throw error if user is not authorized', async () => {
        prisma.post.findUnique.mockResolvedValueOnce({ authorId: 'user-2' });

        await expect(postsModule.getPostAnalytics('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to get post analytics: Not authorized to view analytics for this post');
      });

      it('should throw error if database fails', async () => {
        prisma.post.findUnique.mockRejectedValueOnce(new Error('DB error'));

        await expect(postsModule.getPostAnalytics('post-1', 'user-1'))
          .rejects
          .toThrow('Failed to get post analytics: DB error');
      });
    });

    describe('trackView', () => {
      it('should track view when no recent view exists', async () => {
        prisma.postView.findFirst.mockResolvedValueOnce(null);
        prisma.postView.create.mockResolvedValueOnce({ id: 'view-1' });

        const result = await postsModule.trackView('post-1', 'user-1');

        expect(prisma.postView.findFirst).toHaveBeenCalledWith({
          where: {
            postId: 'post-1',
            userId: 'user-1',
            viewedAt: {
              gte: expect.any(Date), // Last 24 hours
            }
          }
        });
        expect(prisma.postView.create).toHaveBeenCalledWith({
          data: {
            postId: 'post-1',
            userId: 'user-1',
            viewedAt: expect.any(Date),
          }
        });
        expect(result).toBe(true);
      });

      it('should not track view when recent view exists', async () => {
        prisma.postView.findFirst.mockResolvedValueOnce({ id: 'existing-view' });

        const result = await postsModule.trackView('post-1', 'user-1');

        expect(prisma.postView.create).not.toHaveBeenCalled();
        expect(result).toBe(true);
      });

      it('should return false and not throw when database fails', async () => {
        prisma.postView.findFirst.mockRejectedValueOnce(new Error('DB error'));

        const result = await postsModule.trackView('post-1', 'user-1');

        expect(result).toBe(false);
        // The function should not throw an error, just return false
      });
    });
  });
});