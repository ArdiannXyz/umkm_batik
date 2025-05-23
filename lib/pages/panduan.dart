import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Remove unused import
// import 'package:umkm_batik/services/product_service.dart';

class PanduanChatbot extends StatefulWidget {
  const PanduanChatbot({Key? key}) : super(key: key);

  @override
  State<PanduanChatbot> createState() => _PanduanChatbotState();
}

class _PanduanChatbotState extends State<PanduanChatbot> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Daftar tombol pilihan cepat (quick replies)
  final List<String> _quickReplies = [
    'stok',
    'bayar',
    'resi',
    'kontak',
    'tentang',
    'menu'
  ];

  @override
  void initState() {
    super.initState();
    // Menambahkan pesan sambutan dari bot
    _addBotMessage(
        "Halo! Saya chatbot panduan UMKM Batik yang bisa membantu Anda. Silakan pilih topik bantuan:",
        content: "Anda bisa bertanya tentang:\n\n" +
            "• Cara cek Stok barang \n" +
            "• Cara pembayaran\n" +
            "• Cara cek resi\n" +
            "• Informasi kontak, dll");
  }

  void _addBotMessage(String text,
      {List<String>? steps,
      List<String>? menu,
      List<Map<String, dynamic>>? contacts,
      String? content}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isBot: true,
          steps: steps,
          menu: menu,
          contacts: contacts,
          content: content,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isBot: false,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      // Kirim pesan menggunakan HTTP request langsung
      final response = await http.post(
        Uri.parse('http://192.168.100.48/umkm_batik/API/chatbot_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': message}),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['type'] == 'stock_steps' ||
          responseData['type'] == 'payment_steps' ||
          responseData['type'] == 'tracking_steps') {
        List<String> stepsList = [];

        if (responseData.containsKey('steps')) {
          for (var step in responseData['steps']) {
            stepsList.add(step);
          }
        }

        _addBotMessage(responseData['message'], steps: stepsList);
      } else if (responseData['type'] == 'unknown') {
        // Tampilkan pesan unknown tanpa tambahan menu
        _addBotMessage(responseData['message']);
      } else if (responseData['type'] == 'product_stock') {
        // Tampilkan informasi stok produk
        String content = '';

        if (responseData.containsKey('data') &&
            responseData['data'].isNotEmpty) {
          for (var product in responseData['data']) {
            content += "• ${product['nama_produk']}\n";
            content += "  Harga: ${product['harga']}\n";
            content += "  Stok: ${product['stok']} pcs\n";
            content +=
                "  Status: ${product['status'] == 'available' ? 'Tersedia' : 'Tidak Tersedia'}\n\n";
          }
        }

        _addBotMessage(responseData['message'], content: content);
      } else if (responseData['type'] == 'category_products') {
        // Tampilkan produk berdasarkan kategori
        String content = '';

        if (responseData.containsKey('data') &&
            responseData['data'].isNotEmpty) {
          for (var product in responseData['data']) {
            content += "• ${product['nama_produk']}\n";
            content += "  Harga: ${product['harga']}\n";
            content +=
                "  Status: ${product['status'] == 'available' ? 'Tersedia' : 'Tidak Tersedia'}\n\n";
          }
        }

        _addBotMessage(responseData['message'], content: content);
      } else if (responseData['type'] == 'contact_info') {
        List<Map<String, dynamic>> contactsList = [];

        if (responseData.containsKey('contacts')) {
          for (var contact in responseData['contacts']) {
            contactsList.add(contact);
          }
        }

        _addBotMessage(responseData['message'], contacts: contactsList);
      } else if (responseData['type'] == 'about') {
        _addBotMessage(
          responseData['message'],
          content: responseData['content'],
        );
      } else {
        _addBotMessage(responseData['message']);
      }
    } catch (e) {
      _addBotMessage(
          "Maaf, terjadi kesalahan dalam memproses permintaan Anda. Silakan coba lagi nanti.");
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    // Memberikan waktu untuk build selesai
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        title: const Text(
          'Panduan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.blue[700],
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          // Quick Reply buttons dengan style modern
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _quickReplies
                    .map((reply) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () => _sendMessage(reply),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.blue.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              reply,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Ketik pesan atau pilih topik di atas...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isBot;
  final List<String>? steps;
  final List<String>? menu;
  final List<Map<String, dynamic>>? contacts;
  final String? content;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isBot,
    this.steps,
    this.menu,
    this.contacts,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 20),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : Colors.blue[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isBot
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                  bottomRight: isBot
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isBot ? Colors.black87 : Colors.black87,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.grey[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        content!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                  if (steps != null && steps!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.grey[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: steps!
                            .map((step) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          step,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  if (menu != null && menu!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...menu!.map((item) => GestureDetector(
                          onTap: () {
                            final command = item.split(' - ').first;
                            final chatbotState =
                                context.findAncestorStateOfType<
                                    _PanduanChatbotState>();
                            if (chatbotState != null) {
                              chatbotState._sendMessage(command);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.blue.shade700),
                              ],
                            ),
                          ),
                        )),
                  ],
                  if (contacts != null && contacts!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...contacts!.map((contact) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (contact['phone'] != null)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        contact['phone'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              if (contact['email'] != null)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email,
                                          size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        contact['email'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              if (contact['hours'] != null)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        contact['hours'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          if (!isBot)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}
