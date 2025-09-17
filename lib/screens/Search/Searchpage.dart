import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/controllers/State_Management_Profile.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import '../../controllers/user_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final AppData _appData = AppData();
  final UserController userController = Get.find<UserController>();
  
  List<dynamic> _searchResults = [];
  List<dynamic> _suggestedUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedUsers();
  }

  List<dynamic> _filterUniqueUsers(List<dynamic> users) {
    final uniqueEmails = <String>{};
    return users.where((user) {
      final email = user['email'] ?? '';
      if (email.isEmpty || uniqueEmails.contains(email)) {
        return false;
      }
      uniqueEmails.add(email);
      return true;
    }).toList();
  }

  Future<void> _fetchSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3067/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        
        // CACHE ALL USERS DATA INSTANTLY
        userController.bulkCacheUsers(data.cast<Map<String, dynamic>>());
        
        // PRELOAD IMAGES FOR FIRST 10 USERS
        final firstTenUserIds = data.take(10).map((user) => user['_id'] as String).toList();
        userController.preloadVisibleUsers(firstTenUserIds, context);
        
        setState(() {
          _suggestedUsers = data.take(10).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Error loading suggestions');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3067/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        
        final filteredResults = data
            .where((user) =>
                user['name']?.toLowerCase().contains(query.toLowerCase()) ?? false)
            .toList();
        
        // CACHE SEARCH RESULTS DATA
        userController.bulkCacheUsers(filteredResults.cast<Map<String, dynamic>>());
        
        // PRELOAD IMAGES FOR SEARCH RESULTS
        final searchUserIds = filteredResults.map((user) => user['_id'] as String).toList();
        userController.preloadVisibleUsers(searchUserIds, context);
        
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Error searching users');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSimpleHeader(),
            _buildSimpleSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingMenuWidget(),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find People',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('Discover and connect with others',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for people...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _searchUsers('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {});
            _searchUsers(value);
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  _isSearching ? 'Search Results' : 'Suggested People',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const Spacer(),
                if (!_isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_suggestedUsers.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final users = _isSearching ? _searchResults : _suggestedUsers;
    
    if (users.isEmpty && _isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Try a different search term', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpecificUserProfilePage(userId: user['_id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // USE THE INSTANT PROFILE PICTURE WIDGET
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: InstantProfilePicture(
                  userId: user['_id'],
                  radius: 25,
                  fallbackName: user['name'],
                  fallbackImageUrl: user['picture'] != null && user['picture'].isNotEmpty
                      ? 'http://182.93.94.210:3067${user['picture']}'
                      : null,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tap to view profile', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}