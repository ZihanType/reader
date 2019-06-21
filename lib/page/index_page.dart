import 'package:flutter/material.dart';

import '../logic/book_provider.dart' show bookProvider, Book, BookRequest;

class IndexPage extends StatefulWidget {
  const IndexPage({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.readingChapterTitle,
  });

  final String bookUrl;
  final String bookTitle;
  final String readingChapterTitle;

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  ScrollController _controller;

  bool _isReversed = false;

  Widget _buildTile(String chapterTitle, String readingChapterTitle) {
    return Container(
      height: 56.0,
      child: ListTile(
        title: Text(
          chapterTitle,
          style: TextStyle(
            fontWeight: chapterTitle == readingChapterTitle
                ? FontWeight.bold
                : FontWeight.normal,
            color:
                chapterTitle == readingChapterTitle ? Colors.red : Colors.black,
          ),
        ),
        onTap: () {
          Navigator.pop(context, chapterTitle);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bookProvider.response,
      builder: (context, snapshot) {
        final Book book = snapshot.data as Book;

        if (book == null ||
            book.readingChapterTitle == null ||
            book.chapterTitleList == null) {
          bookProvider.request(
            BookRequest(
              bookUrl: widget.bookUrl,
              bookTitle: widget.bookTitle,
              readingChapterTitle: widget.readingChapterTitle,
            ),
          );
          return Scaffold(
            appBar: AppBar(),
            body: Container(),
          );
        }

        final int itemCount = book.chapterTitleList.length;
        final double height = book.chapterTitleList.length * 56.0;
        final double offset =
            book.chapterTitleList.indexOf(book.readingChapterTitle) * 56.0;

        _controller = ScrollController(
          initialScrollOffset: offset,
        );

        // ---------------------------------------------------------------------
        return Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.import_export),
                onPressed: () {
                  setState(() {
                    _isReversed = !_isReversed;
                  });
                  _controller.jumpTo(
                    !_isReversed ? offset : height - offset - 56.0,
                  );
                },
              ),
            ],
          ),
          body: Scrollbar(
            child: ListView.separated(
              controller: _controller,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return !_isReversed
                    ? _buildTile(
                        book.chapterTitleList[index],
                        book.readingChapterTitle,
                      )
                    : _buildTile(
                        book.chapterTitleList[itemCount - index - 1],
                        book.readingChapterTitle,
                      );
              },
              separatorBuilder: (context, index) {
                return Divider(
                  height: 0.0,
                  color: Colors.black,
                );
              },
            ),
          ),
        );
        // ---------------------------------------------------------------------
      },
    );
  }
}
