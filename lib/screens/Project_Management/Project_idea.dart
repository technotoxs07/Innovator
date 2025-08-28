import 'package:flutter/material.dart';


class Project {
  final String id;
  String title;
  String description;
  String? mentorId;
  String status;
  String? videoLink;
  String? photoLink;
  String? textSubmission;
  String? rejectionReason;
  DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.mentorId,
    this.status = 'Looking for Mentor',
    this.videoLink,
    this.photoLink,
    this.textSubmission,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class Mentor {
  final String id;
  final String name;
  final String expertise;
  final String bio;
  final String experience;
  double rating;
  int totalReviews;
  final String avatar;

  Mentor({
    required this.id,
    required this.name,
    required this.expertise,
    required this.bio,
    required this.experience,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.avatar,
  });
}

class MentorReview {
  final String mentorId;
  final String projectId;
  final double rating;
  final String comment;
  final DateTime date;

  MentorReview({
    required this.mentorId,
    required this.projectId,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class Project_HomeScreen extends StatefulWidget {
  @override
  _Project_HomeScreenState createState() => _Project_HomeScreenState();
}

class _Project_HomeScreenState extends State<Project_HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Project> projects = [];
  List<Mentor> mentors = [
    Mentor(
      id: '1',
      name: 'CA. Amrit Shrestha',
      expertise: 'Flutter & Mobile Development',
      bio: 'Senior Flutter developer with 8+ years of experience in mobile app development. Specialized in creating scalable and performant applications.',
      experience: '8+ years',
      rating: 4.8,
      totalReviews: 124,
      avatar: '👩‍💻',
    ),
    Mentor(
      id: '2',
      name: 'ER. Razu Shrestha',
      expertise: 'AI/ML & Data Science',
      bio: 'Machine Learning researcher and professor. Expert in deep learning, computer vision, and natural language processing.',
      experience: '12+ years',
      rating: 4.9,
      totalReviews: 89,
      avatar: '👨‍🔬',
    ),
    Mentor(
      id: '3',
      name: 'MD. Siddharth Khan',
      expertise: 'Full Stack Web Development',
      bio: 'Full-stack developer specializing in React, Node.js, and cloud technologies. Passionate about clean code and modern architectures.',
      experience: '6+ years',
      rating: 4.7,
      totalReviews: 156,
      avatar: '👨‍💼',
    ),
    Mentor(
      id: '4',
      name: 'Ronit Shrivastav',
      expertise: 'UI/UX Design & Research',
      bio: 'Design thinking expert with extensive experience in user research, prototyping, and creating intuitive user experiences.',
      experience: '10+ years',
      rating: 4.6,
      totalReviews: 201,
      avatar: '👩‍🎨',
    ),
  ];
  List<MentorReview> mentorReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'My Projects', icon: Icon(Icons.assignment, color: Colors.white,)),
            Tab(text: 'Find Mentors', icon: Icon(Icons.people, color: Colors.white,)),
            Tab(text: 'Reviews', icon: Icon(Icons.star, color: Colors.white,)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectsTab(),
          _buildMentorsTab(),
          _buildReviewsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateProjectDialog,
              icon: Icon(Icons.add),
              label: Text('New Project',style: TextStyle(color: Colors.white),),
            )
          : null,
    );
  }

  Widget _buildProjectsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(244, 135, 6, 0.1),
            Colors.white,
          ],
        ),
      ),
      child: projects.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectCard(project);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color.fromRGBO(244, 135, 6, 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 60,
              color: Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Start Your Journey',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Create your first project and find amazing\nmentors to guide you through your learning journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateProjectDialog,
            icon: Icon(Icons.add),
            label: Text('Create Project'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToProjectDetail(project),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(project.status),
                      color: _getStatusColor(project.status),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(project.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            project.status,
                            style: TextStyle(
                              color: _getStatusColor(project.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                project.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(project.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (project.mentorId != null) ...[
                    Spacer(),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Color.fromRGBO(244, 135, 6, 1),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getMentorName(project.mentorId!),
                      style: TextStyle(
                        color: Color.fromRGBO(244, 135, 6, 1),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentorsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(244, 135, 6, 0.1),
            Colors.white,
          ],
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: mentors.length,
        itemBuilder: (context, index) {
          final mentor = mentors[index];
          return _buildMentorCard(mentor);
        },
      ),
    );
  }

  Widget _buildMentorCard(Mentor mentor) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(244, 135, 6, 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      mentor.avatar,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        mentor.expertise,
                        style: TextStyle(
                          color: Color.fromRGBO(244, 135, 6, 1),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 16,
                                color: index < mentor.rating.floor()
                                    ? Colors.amber
                                    : Colors.grey[300],
                              );
                            }),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${mentor.rating} (${mentor.totalReviews})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              mentor.bio,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    mentor.experience,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _showMentorProfile(mentor),
                      child: Text('View Profile'),
                    ),
                    IconButton(
                      icon: Icon(Icons.star, color: Color.fromRGBO(244, 135, 6, 1)),
                      onPressed: () => _showRateMentorDialog(mentor.id, null),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviews = mentorReviews;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(244, 135, 6, 0.1),
            Colors.white,
          ],
        ),
      ),
      child: reviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Reviews Yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete projects to leave reviews for mentors',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final mentor = mentors.firstWhere((m) => m.id == review.mentorId);
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(mentor.avatar, style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(mentor.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            Spacer(),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < review.rating ? Colors.amber : Colors.grey[300],
                                );
                              }),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(review.comment),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(review.date),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Looking for Mentor':
        return Colors.blue;
      case 'Mentor Assigned':
        return Color.fromRGBO(244, 135, 6, 1);
      case 'In Progress':
        return Colors.purple;
      case 'Submitted':
        return Colors.indigo;
      case 'Under Review':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Looking for Mentor':
        return Icons.search;
      case 'Mentor Assigned':
        return Icons.person_add;
      case 'In Progress':
        return Icons.construction;
      case 'Submitted':
        return Icons.upload;
      case 'Under Review':
        return Icons.rate_review;
      case 'Completed':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMentorName(String mentorId) {
    try {
      final mentor = mentors.firstWhere((m) => m.id == mentorId);
      return mentor.name;
    } catch (e) {
      return 'Unknown Mentor';
    }
  }

  void _showCreateProjectDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Color.fromRGBO(244, 135, 6, 1)),
            SizedBox(width: 8),
            Text('Create New Project'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Project Title',
                hintText: 'e.g., E-commerce Mobile App',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what you want to build and learn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                setState(() {
                  projects.add(Project(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text,
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Create Project'),
          ),
        ],
      ),
    );
  }

  void _showMentorProfile(Mentor mentor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mentor.avatar,
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: 16),
              Text(
                mentor.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                mentor.expertise,
                style: TextStyle(
                  color: Color.fromRGBO(244, 135, 6, 1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < mentor.rating.floor()
                            ? Colors.amber
                            : Colors.grey[300],
                      );
                    }),
                  ),
                  SizedBox(width: 8),
                  Text('${mentor.rating} (${mentor.totalReviews} reviews)'),
                ],
              ),
              SizedBox(height: 16),
              Text(
                mentor.bio,
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle mentor selection logic here
                      },
                      child: Text('Select Mentor'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRateMentorDialog(mentor.id, null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Rate Mentor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: project,
          mentors: mentors,
          onProjectUpdated: (updatedProject) {
            setState(() {
              final index = projects.indexWhere((p) => p.id == updatedProject.id);
              if (index != -1) {
                projects[index] = updatedProject;
              }
            });
          },
          onReviewAdded: (review) {
            setState(() {
              mentorReviews.add(review);
              final mentor = mentors.firstWhere((m) => m.id == review.mentorId);
              mentor.rating = ((mentor.rating * mentor.totalReviews) + review.rating) / (mentor.totalReviews + 1);
              mentor.totalReviews++;
            });
          },
        ),
      ),
    );
  }

  void _showRateMentorDialog(String mentorId, String? projectId) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Rate Mentor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with ${_getMentorName(mentorId)}?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  final review = MentorReview(
                    mentorId: mentorId,
                    projectId: projectId ?? 'general-${DateTime.now().millisecondsSinceEpoch}',
                    rating: rating,
                    comment: commentController.text,
                    date: DateTime.now(),
                  );
                  setState(() {
                    mentorReviews.add(review);
                    final mentor = mentors.firstWhere((m) => m.id == mentorId);
                    mentor.rating = ((mentor.rating * mentor.totalReviews) + rating) / (mentor.totalReviews + 1);
                    mentor.totalReviews++;
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for your review! ⭐'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final List<Mentor> mentors;
  final Function(Project) onProjectUpdated;
  final Function(MentorReview) onReviewAdded;

  const ProjectDetailScreen({
    Key? key,
    required this.project,
    required this.mentors,
    required this.onProjectUpdated,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project currentProject;
  final videoController = TextEditingController();
  final photoController = TextEditingController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentProject = widget.project;
    videoController.text = currentProject.videoLink ?? '';
    photoController.text = currentProject.photoLink ?? '';
    textController.text = currentProject.textSubmission ?? '';
  }

  @override
  void dispose() {
    videoController.dispose();
    photoController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentProject.title),
        actions: [
          if (currentProject.status == 'Completed')
            IconButton(
              onPressed: _showReviewDialog,
              icon: Icon(Icons.star),
              tooltip: 'Rate Mentor',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(244, 135, 6, 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectHeader(),
              SizedBox(height: 20),
              _buildProjectDescription(),
              SizedBox(height: 20),
              if (currentProject.status == 'Looking for Mentor') _buildMentorSelection(),
              if (currentProject.status == 'Mentor Assigned') _buildProjectWork(),
              if (currentProject.status == 'In Progress') _buildSubmissionForm(),
              if (currentProject.status == 'Rejected') _buildRejectedState(),
              if (currentProject.status == 'Completed') _buildCompletedState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(currentProject.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStatusIcon(currentProject.status),
                color: _getStatusColor(currentProject.status),
                size: 32,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currentProject.status,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(currentProject.status),
                    ),
                  ),
                  if (currentProject.mentorId != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Mentor: ${_getMentorName(currentProject.mentorId!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDescription() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              currentProject.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Created: ${_formatDate(currentProject.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorSelection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(244, 135, 6, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Color.fromRGBO(244, 135, 6, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Choose Your Mentor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Select an expert mentor who will guide you through your project journey.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            ...widget.mentors.map((mentor) => Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(244, 135, 6, 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      mentor.avatar,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(
                  mentor.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      mentor.expertise,
                      style: TextStyle(
                        color: Color.fromRGBO(244, 135, 6, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: index < mentor.rating.floor()
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${mentor.rating} (${mentor.totalReviews})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _selectMentor(mentor.id),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Select'),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectWork() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(244, 135, 6, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Color.fromRGBO(244, 135, 6, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Start Working on Your Project',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.green,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mentor Assigned Successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your mentor ${_getMentorName(currentProject.mentorId!)} is ready to guide you. Start working on your project and submit when ready.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startWorking,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.play_arrow),
                label: Text(
                  'Start Working',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(244, 135, 6, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Color.fromRGBO(244, 135, 6, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Submit Your Project',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Share your completed project with your mentor for review.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Project Description *',
                hintText: 'Describe what you built, challenges faced, and what you learned...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),
            SizedBox(height: 16),
            TextField(
              controller: videoController,
              decoration: InputDecoration(
                labelText: 'Demo Video Link (Optional)',
                hintText: 'https://youtube.com/watch?v=...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.video_library),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: photoController,
              decoration: InputDecoration(
                labelText: 'Project Photos/Screenshots (Optional)',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.photo_library),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitProject,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.send),
                label: Text(
                  'Submit for Review',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text(
                  'Project Needs Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback from ${_getMentorName(currentProject.mentorId!)}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentProject.rejectionReason ??
                        'Please improve your project based on the requirements.',
                    style: TextStyle(
                      color: Colors.red[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resubmitProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.refresh),
                label: Text(
                  'Improve & Resubmit',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Project Completed Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Congratulations! Your mentor has approved your project.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (currentProject.textSubmission != null) ...[
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(currentProject.textSubmission!),
                    SizedBox(height: 12),
                  ],
                  if (currentProject.videoLink != null) ...[
                    Row(
                      children: [
                        Icon(Icons.video_library, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo Video Available',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (currentProject.photoLink != null) ...[
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Project Screenshots Available',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showReviewDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.star),
                label: Text(
                  'Rate Your Mentor',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Looking for Mentor':
        return Colors.blue;
      case 'Mentor Assigned':
        return Color.fromRGBO(244, 135, 6, 1);
      case 'In Progress':
        return Colors.purple;
      case 'Submitted':
        return Colors.indigo;
      case 'Under Review':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Looking for Mentor':
        return Icons.search;
      case 'Mentor Assigned':
        return Icons.person_add;
      case 'In Progress':
        return Icons.construction;
      case 'Submitted':
        return Icons.upload;
      case 'Under Review':
        return Icons.rate_review;
      case 'Completed':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMentorName(String mentorId) {
    try {
      final mentor = widget.mentors.firstWhere((m) => m.id == mentorId);
      return mentor.name;
    } catch (e) {
      return 'Unknown Mentor';
    }
  }

  void _selectMentor(String mentorId) {
    setState(() {
      currentProject.mentorId = mentorId;
      currentProject.status = 'Mentor Assigned';
    });
    widget.onProjectUpdated(currentProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mentor assigned successfully! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startWorking() {
    setState(() {
      currentProject.status = 'In Progress';
    });
    widget.onProjectUpdated(currentProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project started! Good luck! 💪'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitProject() {
    if (textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a project description'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      currentProject.textSubmission = textController.text;
      currentProject.videoLink = videoController.text.isEmpty ? null : videoController.text;
      currentProject.photoLink = photoController.text.isEmpty ? null : photoController.text;
      currentProject.status = 'Under Review';
    });

    widget.onProjectUpdated(currentProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project submitted for review! 📝'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Simulate mentor review process
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        final random = DateTime.now().millisecond % 3;
        setState(() {
          if (random == 0) {
            currentProject.status = 'Completed';
          } else {
            currentProject.status = 'Rejected';
            currentProject.rejectionReason =
                'Great start! However, please add more technical details about your implementation. Consider including code snippets, architecture diagrams, and explain the challenges you faced and how you solved them.';
          }
        });
        widget.onProjectUpdated(currentProject);
      }
    });
  }

  void _resubmitProject() {
    setState(() {
      currentProject.status = 'In Progress';
      currentProject.rejectionReason = null;
    });
    widget.onProjectUpdated(currentProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ready for resubmission. Please improve your project! 🔄'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReviewDialog() {
    if (currentProject.mentorId == null) return;

    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Rate Your Mentor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with ${_getMentorName(currentProject.mentorId!)}?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  final review = MentorReview(
                    mentorId: currentProject.mentorId!,
                    projectId: currentProject.id,
                    rating: rating,
                    comment: commentController.text,
                    date: DateTime.now(),
                  );
                  widget.onReviewAdded(review);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for your review! ⭐'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}