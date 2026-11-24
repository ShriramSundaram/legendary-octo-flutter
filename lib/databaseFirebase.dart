import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ViewGenericDatabase extends StatefulWidget {
  final String GermanLevel;

  const ViewGenericDatabase({Key? key, required this.GermanLevel})
      : super(key: key);

  @override
  State<ViewGenericDatabase> createState() => _ViewGenericDatabaseState();
}

class _ViewGenericDatabaseState extends State<ViewGenericDatabase> {
  int selectedIndex = 0;
  final List<String> doumentsIdList = ["", "", ""];
  late FlutterTts flutterTts;
  bool isTtsReady = false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  // Get the documents Id's from Firebase - NOT USED NOW, FUTURE USE
  void getDocuIdFireBase() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('User').get();
      for (var element in snapshot.docs) {
        doumentsIdList.add(element.reference.id);
      }
    } catch (e) {
      debugPrint('Error fetching document IDs: $e');
    }
  }

  void initTts() async {
    flutterTts = FlutterTts();
    try {
      await flutterTts.setLanguage("DE");
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.9);

      // Check if German language is available
      List<dynamic>? languages = await flutterTts.getLanguages;
      bool isGermanSupported = languages != null &&
          languages.any((lang) => lang.toString().toLowerCase().contains('de'));

      setState(() {
        isTtsReady = isGermanSupported;
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      setState(() {
        isTtsReady = false;
      });
    }
  }

  void speak(String text) async {
    if (!isTtsReady) {
      initTts();
      // We can only check the current state
      if (!isTtsReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Text-to-speech is not available for German language.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
    }

    try {
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error with text-to-speech: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not speak the text. Please try again.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final CollectionReference user =
      FirebaseFirestore.instance.collection('Generic');

  Map<String, dynamic> dataCurr = {};

  bool firstTime = true;

  @override
  void initState() {
    super.initState();
    initTts();
    getData();
  }

  void getData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final DocumentSnapshot snapshot =
          await user.doc(widget.GermanLevel).get();
      if (snapshot.exists) {
        debugPrint('DataPresent');
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            dataCurr = data;
            isLoading = false;
          });
          debugPrint('Data loaded: ${dataCurr.length} items');
        } else {
          setState(() {
            hasError = true;
            errorMessage = 'No data available for this level';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Document does not exist';
          isLoading = false;
        });
      }

      if (firstTime) {
        runFilter('');
        firstTime = false;
      }
    } catch (e) {
      debugPrint('Error getting data: $e');
      setState(() {
        hasError = true;
        errorMessage = 'Failed to load data. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            "German Collection ${widget.GermanLevel.replaceAll('GenericCollections', '')}",
            style: const TextStyle(fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh data',
              onPressed: () {
                getData();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: runFilter,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  labelText: 'Search',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: 18.0,
                  ),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildWordList(),
            ),
          ],
        ),
      );

  Widget _buildWordList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading words...'),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: getData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final filteredWords = dataCurr['filteredWords'] as List<dynamic>?;
    if (filteredWords == null || filteredWords.isEmpty) {
      return const Center(
        child: Text(
          'No words found for this level.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredWords.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final word = filteredWords[index].toString();

        return Card(
          elevation: selectedIndex == index ? 4 : 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: selectedIndex == index ? Colors.blue.shade50 : null,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              word,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selectedIndex == index
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            leading: Icon(
              Icons.text_fields,
              color: selectedIndex == index ? Colors.blue : Colors.black54,
            ),
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    speak(word);
                  },
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Speak',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void runFilter(String enterWord) {
    try {
      enterWord = enterWord.trim().toLowerCase();

      if (!dataCurr.containsKey('wordStorage') ||
          dataCurr['wordStorage'] == null) {
        debugPrint('Warning: wordStorage is null or not found in dataCurr');
        setState(() {
          hasError = true;
          errorMessage = 'Word data is missing or corrupted';
        });
        return;
      }

      final List<dynamic> wordStorage =
          dataCurr['wordStorage'] as List<dynamic>;

      setState(() {
        if (enterWord.isEmpty) {
          dataCurr['filteredWords'] = wordStorage;
        } else {
          dataCurr['filteredWords'] = wordStorage.where((word) {
            return word.toString().toLowerCase().contains(enterWord);
          }).toList();
        }

        // Reset selected index when filter changes
        if (selectedIndex >= (dataCurr['filteredWords'] as List).length) {
          selectedIndex = 0;
        }
      });
    } catch (e) {
      debugPrint('Error in runFilter: $e');
      setState(() {
        hasError = true;
        errorMessage = 'Error filtering words: $e';
      });
    }
  }
}
