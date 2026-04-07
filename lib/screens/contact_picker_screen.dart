import 'package:flutter/material.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      Navigator.pop(context);
      return;
    }

    final contacts = await FastContacts.getAllContacts();
    //for only keepinng contacts that have phone number
    setState(() {
      _contacts = contacts
          .where((contacts) => contacts.phones.isNotEmpty)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: Text(
          'Pick a Contact',
          style: GoogleFonts.inika(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _contacts.isEmpty
              ? const Center(child: Text('No contacts found'))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];

                    // Getting first phone number and cleaning it
                    //removing unwanted characters
                    final phone = contact.phones.first.number
                        .replaceAll(' ', '')
                        .replaceAll('-', '');

                    final name = contact.displayName;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.teal[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.karma(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(phone),
                      onTap: () {
                        Navigator.pop(context, {
                          'name': name,
                          'phone': phone,
                        });
                      },
                    );
                  },
                ),
    );
  }
}