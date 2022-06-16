import 'dart:convert' as convert;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    implements EMChatManagerListener {
  final String appKey = "41117440#383391";

  ScrollController scrollController = ScrollController();
  String _username = "";
  String _password = "";
  String _messageContent = "";
  String _chatId = "";
  final List<String> _logText = [];

  @override
  void initState() {
    super.initState();
    _initSDK();
    _addChatListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: "Enter username"),
              onChanged: (username) => _username = username,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Enter password"),
              onChanged: (password) => _password = password,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: _signIn,
                    child: const Text("SIGN IN"),
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.lightBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: _signOut,
                    child: const Text("SIGN OUT"),
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.lightBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: _signUp,
                    child: const Text("SIGN UP"),
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.lightBlue),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                  hintText: "Enter the username you want to send"),
              onChanged: (chatId) => _chatId = chatId,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Enter content"),
              onChanged: (msg) => _messageContent = msg,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _sendMessage,
              child: const Text("SEND TEXT"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
              ),
            ),
            Flexible(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (_, index) {
                  return Text(_logText[index]);
                },
                itemCount: _logText.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initSDK() async {
    EMOptions options = EMOptions(
      appKey: appKey,
      autoLogin: false,
    );
    await EMClient.getInstance.init(options);
  }

  void _addChatListener() {
    EMClient.getInstance.chatManager.addChatManagerListener(this);
  }

  @override
  void dispose() {
    EMClient.getInstance.chatManager.removeChatManagerListener(this);
    super.dispose();
  }

  void _signIn() async {
    if (_username.isEmpty || _password.isEmpty) {
      _addLogToConsole("username or password is null");
      return;
    }

    String? agoraToken = await HttpRequestManager.loginToAppServer(
      username: _username,
      password: _password,
    );
    if (agoraToken != null) {
      _addLogToConsole("fetch agora token succeed, begin login");
      try {
        await EMClient.getInstance.loginWithAgoraToken(_username, agoraToken);
        _addLogToConsole("login succeed, username: $_username");
      } on EMError catch (e) {
        _addLogToConsole(
            "login failed, code: ${e.code}, desc: ${e.description}");
      }
    } else {
      _addLogToConsole("fetch agora token failed");
    }
  }

  void _signOut() async {
    try {
      await EMClient.getInstance.logout(true);
      _addLogToConsole("sign out succeed");
    } on EMError catch (e) {
      _addLogToConsole(
          "sign out failed, code: ${e.code}, desc: ${e.description}");
    }
  }

  void _signUp() async {
    if (_username.isEmpty || _password.isEmpty) {
      _addLogToConsole("username or password is null");
      return;
    }
    bool ret = await HttpRequestManager.registerToAppServer(
      username: _username,
      password: _password,
    );
    if (ret) {
      _addLogToConsole("sign up succeed, username: $_username");
    } else {
      _addLogToConsole("sign up failed");
    }
  }

  void _sendMessage() async {
    if (_chatId.isEmpty || _messageContent.isEmpty) {
      _addLogToConsole("single chat id or message content is null");
      return;
    }

    var msg = EMMessage.createTxtSendMessage(
      username: _chatId,
      content: _messageContent,
    );
    msg.setMessageStatusCallBack(MessageStatusCallBack(
      onSuccess: () {
        _addLogToConsole("send message: $_messageContent");
      },
      onError: (e) {
        _addLogToConsole(
          "send message failed, code: ${e.code}, desc: ${e.description}",
        );
      },
    ));
    EMClient.getInstance.chatManager.sendMessage(msg);
  }

  void _addLogToConsole(String log) {
    _logText.add(_timeString + ": " + log);
    setState(() {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  String get _timeString {
    return DateTime.now().toString().split(".").first;
  }

  @override
  void onCmdMessagesReceived(List<EMMessage> messages) {}

  @override
  void onConversationRead(String from, String to) {}

  @override
  void onConversationsUpdate() {}

  @override
  void onGroupMessageRead(List<EMGroupMessageAck> groupMessageAcks) {}

  @override
  void onMessagesDelivered(List<EMMessage> messages) {}

  @override
  void onMessagesRead(List<EMMessage> messages) {}

  @override
  void onMessagesRecalled(List<EMMessage> messages) {}

  @override
  void onMessagesReceived(List<EMMessage> messages) {
    for (var msg in messages) {
      switch (msg.body.type) {
        case MessageType.TXT:
          {
            EMTextMessageBody body = msg.body as EMTextMessageBody;
            _addLogToConsole(
              "receive text message: ${body.content}, from: ${msg.from}",
            );
          }
          break;
        case MessageType.IMAGE:
          {
            _addLogToConsole(
              "receive image message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.VIDEO:
          {
            _addLogToConsole(
              "receive video message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.LOCATION:
          {
            _addLogToConsole(
              "receive location message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.VOICE:
          {
            _addLogToConsole(
              "receive voice message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.FILE:
          {
            _addLogToConsole(
              "receive image message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.CUSTOM:
          {
            _addLogToConsole(
              "receive custom message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.CMD:
          {
            // 当前回调中不会有cmd类型消息，cmd类型消息通过 EMChatManagerListener#onCmdMessagesReceived 回调接收
          }
          break;
      }
    }
  }
}

class HttpRequestManager {
  static String host = "a41.easemob.com";
  static String registerUrl = "/app/chat/user/register";
  static String loginUrl = "/app/chat/user/login";

  static Future<bool> registerToAppServer({
    required String username,
    required String password,
  }) async {
    bool ret = false;
    Map<String, String> params = {};
    params["userAccount"] = username;
    params["userPassword"] = password;

    var uri = Uri.https(host, registerUrl);

    var client = http.Client();

    var response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );

    do {
      if (response.statusCode != 200) {
        break;
      }
      Map<String, dynamic>? map = convert.jsonDecode(response.body);
      if (map != null) {
        if (map["code"] == "RES_OK") {
          ret = true;
        }
      }
    } while (false);

    return ret;
  }

  static Future<String?> loginToAppServer({
    required String username,
    required String password,
  }) async {
    Map<String, String> params = {};
    params["userAccount"] = username;
    params["userPassword"] = password;

    var uri = Uri.https(host, loginUrl);

    var client = http.Client();

    var response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic>? map = convert.jsonDecode(response.body);
      if (map != null) {
        if (map["code"] == "RES_OK") {
          return map["accessToken"];
        }
      }
    }
    return null;
  }
}
