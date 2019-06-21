import 'package:flutter/material.dart';

import '../logic/search_provider.dart'
    show searchProvider, Search, SearchRequest;
import 'book_detail_page.dart' show BookDetailPage;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController(text: '西游记');
  final FocusNode _focusNode = FocusNode();

  void _onSubmitted(String value) {
    if (value == null) {
      return;
    }

    final String url = 'https://sou.xanbhx.com/search?siteid=qula&t=m&q=$value';
    searchProvider.request(SearchRequest(body: url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: '输入书名或作者',
            hintStyle: TextStyle(
              color: Colors.white30,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
          controller: _controller,
          onSubmitted: _onSubmitted,
          focusNode: _focusNode,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            color: Colors.white,
            onPressed: () {
              _onSubmitted(_controller.text);
              _focusNode.unfocus();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: searchProvider.response,
        builder: (context, snapshot) {
          final Search search = snapshot.data as Search;

          if (search == null ||
              search.bookDetailUrlList == null ||
              search.bookTitleList == null ||
              search.bookAuthorList1 == null ||
              search.bookAuthorList2 == null) {
            return Center(
              child: Text('暂无搜索结果'),
            );
          }

          return Scrollbar(
            child: ListView.separated(
              itemCount: search.bookDetailUrlList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(search.bookTitleList[index]),
                  subtitle: Text(
                    '${search.bookAuthorList1[index]}\n'
                    '${search.bookAuthorList2[index]}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return BookDetailPage(
                            bookDetailUrl: search.bookDetailUrlList[index],
                            bookTitle: search.bookTitleList[index],
                            bookAuthor1: search.bookAuthorList1[index],
                            bookAuthor2: search.bookAuthorList2[index],
                          );
                        },
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) {
                return Divider(
                  height: 0.0,
                  color: Colors.black,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
