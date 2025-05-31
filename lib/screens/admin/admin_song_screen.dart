import 'package:flutter/material.dart';

class AdminSongScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _AdminSongScreenState createState() => _AdminSongScreenState();
}

class _AdminSongScreenState extends State<AdminSongScreen> {
  // ... (existing code)

  void _showEditDialog(Song song) {
    final titleController = TextEditingController(text: song.title);
    final descriptionController = TextEditingController(text: song.description);
    final lyricsController = TextEditingController(text: song.lyrics);
    final durationController = TextEditingController(text: song.duration);
    final urlController = TextEditingController(text: song.url);
    final coverImageController = TextEditingController(text: song.coverImage);
    final isPublic = song.isPublic;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa bài hát',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                controller: titleController,
                label: 'Tên bài hát',
                icon: Icons.music_note,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: descriptionController,
                label: 'Mô tả',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: lyricsController,
                label: 'Lời bài hát',
                icon: Icons.lyrics,
                maxLines: 5,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: durationController,
                label: 'Thời lượng',
                icon: Icons.timer,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: urlController,
                label: 'URL bài hát',
                icon: Icons.link,
              ),
              SizedBox(height: 16),
              _buildInputField(
                controller: coverImageController,
                label: 'URL ảnh bìa',
                icon: Icons.image,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.public, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Công khai',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500)),
                  Spacer(),
                  Switch(
                    value: isPublic,
                    onChanged: (value) {
                      // Handle public/private toggle
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              if (song.genreNames.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    const Icon(Icons.category, size: 20, color: Colors.deepPurple),
                    ...song.genreNames.map((g) => Text(
                      g,
                      style: const TextStyle(fontSize: 15, color: Colors.deepPurple),
                    )),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle save
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý bài hát'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Handle add new song
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Search and filter section
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài hát...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          // Handle search
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    if (constraints.maxWidth > 600) // Show filter button only on larger screens
                      ElevatedButton.icon(
                        onPressed: () {
                          // Handle filter
                        },
                        icon: Icon(Icons.filter_list),
                        label: Text('Lọc'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Songs list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: 10, // Replace with actual song count
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://via.placeholder.com/60',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 12),
                            // Nội dung chính
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tên bài hát rất dài cũng không bị tràn', // Thay bằng song.title
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4),
                                  Text('Nghệ sĩ: MCK', style: TextStyle(fontSize: 14)),
                                  SizedBox(height: 4),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            WidgetSpan(child: Icon(Icons.category, size: 16, color: Colors.blue)),
                                            TextSpan(text: ' Rap, Dance', style: TextStyle(color: Colors.blue, fontSize: 13)),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            WidgetSpan(child: Icon(Icons.calendar_today, size: 16, color: Colors.grey)),
                                            TextSpan(text: ' ngày 30/5/2025', style: TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text('Lượt thích: 0', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            // Nút chức năng
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pagination
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: () {
                        // Handle previous page
                      },
                    ),
                    Text('Trang 1 / 10'),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: () {
                        // Handle next page
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 