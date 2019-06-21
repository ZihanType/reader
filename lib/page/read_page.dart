import 'package:flutter/material.dart';

import '../logic/book_provider.dart' show bookProvider, Book, BookRequest;
import '../style.dart' show chapterContentFontSize;
import 'index_page.dart' show IndexPage;

class ReadPage extends StatefulWidget {
  const ReadPage({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.readingChapterTitle,
  });

  final String bookUrl;
  final String bookTitle;
  final String readingChapterTitle;

  @override
  _ReadPageState createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  final ScrollController _controller = ScrollController();

  bool _isNight = false;
  bool _showMenu = false;
  bool _showSettings = false;

  double _sliderValue = 0.0;
  double _maxSliderValue = 0.0;

  String _chapterContentCache;

  Widget _buildAppBar() {
    return Positioned(
      left: 0.0,
      right: 0.0,
      top: 0.0,
      child: AppBar(),
    );
  }

  Widget _buildFirstBottom(Book book, List<String> chapterTitleList) {
    return Row(
      children: <Widget>[
        SizedBox(width: 5.0),
        FlatButton(
          child: Text(
            '上一章',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            setState(() {
              if (_sliderValue > 0) {
                _sliderValue -= 1;
              }
            });
            book.toPrevChapter();
            _controller.jumpTo(0.0);
          },
        ),
        Expanded(
          child: Slider(
            activeColor: Colors.red,
            inactiveColor: Colors.white.withOpacity(0.5),
            min: 0.0,
            max: _maxSliderValue,
            divisions: _maxSliderValue.toInt() + 1,
            label: '${(_sliderValue / _maxSliderValue * 100).round()}%',
            value: _sliderValue,
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
            onChangeEnd: (value) {
              book.toNamedChapter(chapterTitleList[value.round()]);
            },
          ),
        ),
        FlatButton(
          child: Text(
            '下一章',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            setState(() {
              if (_sliderValue < chapterTitleList.length - 1) {
                _sliderValue += 1;
              }
            });
            book.toNextChapter();
            _controller.jumpTo(0.0);
          },
        ),
        SizedBox(width: 5.0),
      ],
    );
  }

  Widget _buildSecondBottom(Book book) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return IndexPage(
                    bookUrl: widget.bookUrl,
                    bookTitle: widget.bookTitle,
                    readingChapterTitle: widget.readingChapterTitle,
                  );
                },
              ),
            ).then((chapterTitle) => book.toNamedChapter(chapterTitle));
          },
        ),
        Expanded(
          child: Center(
            child: IconButton(
              icon: Icon(
                !_isNight ? Icons.brightness_3 : Icons.brightness_high,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isNight = !_isNight;
                });
              },
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showSettings = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFirstSettingsBottom() {
    return Row(
      children: <Widget>[
        SizedBox(width: 10.0),
        Expanded(
          child: Text(
            '字体大小',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.remove,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              chapterContentFontSize--;
            });
          },
        ),
        SizedBox(width: 10.0),
        Text(
          '${chapterContentFontSize.toInt()}',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 10.0),
        IconButton(
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              chapterContentFontSize++;
            });
          },
        ),
        SizedBox(width: 10.0),
      ],
    );
  }

  Widget _buildBottomBar(
    Book book,
    List<String> chapterTitleList,
  ) {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
      child: Container(
        color: Color(0xff303030),
        child: !_showSettings
            ? Column(
                children: <Widget>[
                  _buildFirstBottom(book, chapterTitleList),
                  Divider(height: 0.0, color: Colors.white),
                  _buildSecondBottom(book),
                ],
              )
            : Column(
                children: <Widget>[
                  _buildFirstSettingsBottom(),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: bookProvider.response,
        builder: (context, snapshot) {
          final Book book = snapshot.data as Book;

          if (book == null ||
              book.readingChapterTitle == null ||
              book.readingChapterContent == null ||
              book.chapterTitleList == null) {
            bookProvider.request(
              BookRequest(
                bookUrl: widget.bookUrl,
                bookTitle: widget.bookTitle,
                readingChapterTitle: widget.readingChapterTitle,
              ),
            );
            return Center(
              child: Text(
                '正在加载正文……',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          _maxSliderValue = (book.chapterTitleList.length - 1).toDouble();

          if (book.readingChapterTitle ==
              book.readingChapterContent.split('\n\n')[0]) {
            _chapterContentCache = book.readingChapterContent;
          }

          return Stack(
            children: <Widget>[
              SafeArea(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMenu = !_showMenu;
                      if (!_showMenu) {
                        _showSettings = false;
                      }
                      _sliderValue = book.chapterTitleList
                          .indexOf(book.readingChapterTitle)
                          .toDouble();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                    color: !_isNight ? Colors.white : Colors.black,
                    child: ListView(
                      controller: _controller,
                      children: <Widget>[
                        Text(
                          _chapterContentCache,
                          style: TextStyle(
                            color: !_isNight ? Colors.black : Colors.white,
                            fontSize: chapterContentFontSize,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Offstage(
                offstage: !_showMenu,
                child: Stack(
                  children: <Widget>[
                    _buildAppBar(),
                    _buildBottomBar(
                      book,
                      book.chapterTitleList,
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
