import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';

import '../logic/book_detail_provider.dart'
    show bookDetailProvider, BookDetailRequest, BookDetail;
import '../logic/bookshelf_provider.dart'
    show bookshelfProvider, BookshelfRequest, BookshelfRequestHead, BookCover;
import 'read_page.dart' show ReadPage;

class BookDetailPage extends StatelessWidget {
  const BookDetailPage({
    @required this.bookDetailUrl,
    @required this.bookTitle,
    @required this.bookAuthor1,
    @required this.bookAuthor2,
  });

  final String bookDetailUrl;
  final String bookTitle;
  final String bookAuthor1;
  final String bookAuthor2;

  Widget _buildIntroductionRow(
    String bookImageUrl,
    String bookAuthor,
    String bookCategory,
    String bookUpdateState,
    String bookNewestUpdateTime,
    String bookNewestChapterTitle,
  ) {
    return Row(
      children: <Widget>[
        Container(
          height: 180.0,
          width: 120.0,
          margin: EdgeInsets.all(15.0),
          child: CachedNetworkImage(
            imageUrl: bookImageUrl,
            fit: BoxFit.fill,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                bookAuthor,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                bookCategory,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.0),
              ),
              Text(
                bookUpdateState,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.0),
              ),
              Text(
                bookNewestUpdateTime,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.0),
              ),
              Text(
                bookNewestChapterTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRow(
    BuildContext context,
    String bookTitle,
    String bookImageUrl,
    String bookUrl,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(width: 5.0),
        Expanded(
          child: RaisedButton(
            child: Text('立即阅读'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ReadPage(
                      bookUrl: bookUrl,
                      bookTitle: bookTitle,
                      readingChapterTitle: null,
                    );
                  },
                ),
              );
            },
          ),
        ),
        SizedBox(width: 5.0),
        Expanded(
          child: RaisedButton(
            child: Text('加入书架'),
            onPressed: () {
              bookshelfProvider.request(
                BookshelfRequest(
                  head: BookshelfRequestHead.Add,
                  body: BookCover(
                    bookUrl: bookUrl,
                    bookTitle: bookTitle,
                    bookImageUrl: bookImageUrl,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 5.0),
      ],
    );
  }

  Widget _buildDescriptionRow(String bookDescription) {
    return Row(
      children: <Widget>[
        SizedBox(width: 5.0),
        Expanded(
          child: Text(
            bookDescription,
            style: TextStyle(fontSize: 15.0),
          ),
        ),
        SizedBox(width: 5.0),
      ],
    );
  }

  Widget _buildUpdateTimeRow(String bookNewestUpdateTime) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
            color: Color(0xff303030),
            child: Text(
              '最新章节  $bookNewestUpdateTime',
              style: TextStyle(fontSize: 20.0, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterColumn(
    BuildContext context,
    String bookTitle,
    String bookUrl,
    List<String> detailChapterTitleList,
  ) {
    return Column(
      children: detailChapterTitleList.reversed.map((detailChapterTitle) {
        return ListTile(
          contentPadding: EdgeInsets.only(left: 5.0),
          title: Text(detailChapterTitle),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ReadPage(
                    bookUrl: bookUrl,
                    bookTitle: bookTitle,
                    readingChapterTitle: detailChapterTitle,
                  );
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bookDetailProvider.response,
      builder: (context, snapshot) {
        final BookDetail bookDetail = snapshot.data as BookDetail;

        if (bookDetail == null ||
            bookDetail.bookTitle == null ||
            bookDetail.bookCategory == null ||
            bookDetail.bookAuthor == null ||
            bookDetail.bookUpdateState == null ||
            bookDetail.bookNewestChapterTitle == null ||
            bookDetail.bookImageUrl == null ||
            bookDetail.bookNewestUpdateTime == null ||
            bookDetail.bookDescription == null ||
            bookDetail.bookUrl == null ||
            bookDetail.detailChapterTitleList == null) {
          bookDetailProvider.request(
            BookDetailRequest(
              bookDetailUrl: bookDetailUrl,
              bookTitle: bookTitle,
              bookAuthor1: bookAuthor1,
              bookAuthor2: bookAuthor2,
            ),
          );
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                "正在加载详细信息……",
                style: TextStyle(fontSize: 15.0),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(bookDetail.bookTitle),
          ),
          body: ListView(
            children: <Widget>[
              _buildIntroductionRow(
                bookDetail.bookImageUrl,
                bookDetail.bookAuthor,
                bookDetail.bookCategory,
                bookDetail.bookUpdateState,
                bookDetail.bookNewestUpdateTime,
                bookDetail.bookNewestChapterTitle,
              ),
              _buildButtonRow(
                context,
                bookDetail.bookTitle,
                bookDetail.bookImageUrl,
                bookDetail.bookUrl,
              ),
              Divider(
                height: 5.0,
                color: Colors.white,
              ),
              _buildDescriptionRow(
                bookDetail.bookDescription,
              ),
              Divider(
                height: 5.0,
                color: Colors.white,
              ),
              _buildUpdateTimeRow(
                bookDetail.bookNewestUpdateTime,
              ),
              _buildChapterColumn(
                context,
                bookDetail.bookTitle,
                bookDetail.bookUrl,
                bookDetail.detailChapterTitleList,
              ),
            ],
          ),
        );
      },
    );
  }
}
