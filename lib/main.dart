import 'package:caht_app/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

Future<void>  main() async{
  WidgetsFlutterBinding.ensureInitialized(); // runApp 前に何かを実行したいときはこれが必要です。
  await Firebase.initializeApp( // これが Firebase の初期化処理です。
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Future<void> signInWithGoogle() async {
    // GoogleSignIn をして得られた情報を Firebase と関連づけることをやっています。
    final googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();

    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
    title: const Text('GoogleSignIn'),
    ),
    body: Center(
    child: ElevatedButton(
    child: const Text('GoogleSignIn'),
    onPressed: () async {
    await signInWithGoogle();
    if(mounted){
      Navigator.of(context).push(MaterialPageRoute(builder: (context){
        return const ChatPage();
      }));
    }
    },
    ),
    ),
    );
  }
}

final postsReference = FirebaseFirestore.instance.collection('posts').withConverter<Post>( // <> ここに変換したい型名をいれます。今回は Post です。
  fromFirestore: ((snapshot, _) { // 第二引数は使わないのでその場合は _ で不使用であることを分かりやすくしています。
    return Post.fromFirestore(snapshot); // 先ほど定期着した fromFirestore がここで活躍します。
  }),
  toFirestore: ((value, _) {
    return value.toMap(); // 先ほど適宜した toMap がここで活躍します。
  }),
);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Post>>(
                stream: postsReference.snapshots(),
                  builder: (context, snapshot){
                  final posts = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index].data();
                        return Text(post.text);
                      },
                    );
              }),
            ),
            TextFormField(
              onFieldSubmitted: (text){
                final newDocumentReference = postsReference.doc()!;
                final user = FirebaseAuth.instance.currentUser!;
                final newPost = Post(
                    text: text,
                    createdAt: Timestamp.now(),
                    posterName: user.displayName!,
                    posterImageUrl: user.photoURL!,
                    posterId: user.uid,
                    reference: postsReference.doc(),
                );
                newDocumentReference.set(newPost);
              },
            ),
          ],
        ),
      ),
    );
  }
}