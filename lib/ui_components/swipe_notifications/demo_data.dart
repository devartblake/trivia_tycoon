import 'dart:math';

class Email {
  final String from;
  final String subject;
  final String body;
  final String time;
  final String category;
  final String? profileImageUrl;
  final bool isRead;
  final bool isUnread;
  bool isFavorite;

  int randNum = Random().nextInt(999);

  Email({
    required this.from,
    required this.subject,
    required this.body,
    required this.time,
    required this.category,
    this.profileImageUrl,
    this.isRead = false,
    this.isUnread = false,
    this.isFavorite = false,
  });

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}

class DemoData {
  final List<Email> _inbox = [
    Email(
      from: 'Jeffrey Evans',
      subject: 'Re: Workshop Preperation',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '12:00 pm',
      category: 'Work',
      profileImageUrl: 'images/avatars/avatar-1.png',
    ),
    Email(
      from: 'Jordan Chow',
      isRead: true,
      subject: 'Reservation Confirmed for Brooklyn',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '2:00 pm',
      category: 'Personal',
      profileImageUrl: null,
    ),
    Email(
      from: 'Katherine Woodward',
      subject: 'Rough outline',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '2:30 pm',
      category: 'Work',
      profileImageUrl: 'images/avatars/avatar-2.png',
    ),
    Email(
      from: 'Maddie Toohey',
      isRead: true,
      subject: 'Daily Recap for Tuesday, October 30',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '2d',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Tamia Clouthier',
      isRead: true,
      subject: 'Workshop Information',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '3w',
      category: 'Work',
      profileImageUrl: 'images/avatars/avatar-3.png',
    ),
    Email(
      from: 'Daniel Song',
      subject: 'Possible Urgent Absence',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Andrew Argue',
      subject: 'Vacation Request',
      isRead: true,
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Personal',
      profileImageUrl: 'images/avatars/avatar-4.png',
    ),
    Email(
      from: 'Jeffrey Evans',
      subject: 'Re: Workshop Preperation',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Updates',
      profileImageUrl: null,
    ),
    Email(
      from: 'Jordan Chow',
      isRead: true,
      subject: 'Reservation Confirmed for Brooklyn',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'PErrsonal',
      profileImageUrl: 'images/avatars/avatar-5.png',
    ),
    Email(
      from: 'Katherine Woodward',
      subject: 'Rough outline',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Maddie Toohey',
      isRead: true,
      subject: 'Daily Recap for Tuesday, October 30',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Tamia Clouthier',
      isRead: true,
      subject: 'Workshop Information',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Promotions',
      profileImageUrl: null,
    ),
    Email(
      from: 'Daniel Song',
      subject: 'Possible Urgent Absence',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Andrew Argue',
      subject: 'Vacation Request',
      isRead: true,
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Jeffrey Evans',
      subject: 'Re: Workshop Preperation',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Jordan Chow',
      isRead: true,
      subject: 'Reservation Confirmed for Brooklyn',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Personal',
      profileImageUrl: null,
    ),
    Email(
      from: 'Katherine Woodward',
      subject: 'Rough outline',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Updates',
      profileImageUrl: null,
    ),
    Email(
      from: 'Maddie Toohey',
      isRead: true,
      subject: 'Daily Recap for Tuesday, October 30',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Tamia Clouthier',
      isRead: true,
      subject: 'Workshop Information',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Daniel Song',
      subject: 'Possible Urgent Absence',
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
    Email(
      from: 'Andrew Argue',
      subject: 'Vacation Request',
      isRead: true,
      body:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at viverra sem. Suspendisse gravida magna in lorem vehicula…',
      time: '',
      category: 'Work',
      profileImageUrl: null,
    ),
  ];

  int getIndexOf(Email email) {
    return _inbox.indexWhere((Email inbox) => inbox.subject == email.subject);
  }

  List<Email> getData() {
    return _inbox;
  }
}
